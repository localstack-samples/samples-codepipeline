#!/usr/bin/env bash

set -xeuo pipefail

# Create IAM role and policy
lstk aws iam create-role --role-name demo-role --assume-role-policy-document file://role.json
lstk aws iam put-role-policy --role-name demo-role --policy-name demo-policy --policy-document file://policy.json

ROLE_ARN=$(lstk aws iam get-role --role-name demo-role --query Role.Arn --output text)

# Create CodeArtifact repository for the NPM package
lstk aws codeartifact create-domain --domain demo-domain
lstk aws codeartifact create-repository --domain demo-domain --repository demo-repo

# Upload BuildSpecs to an S3 bucket
lstk aws s3 mb s3://demo-buildspecs
lstk aws s3 cp demo-test.yaml s3://demo-buildspecs
lstk aws s3 cp demo-publish.yaml s3://demo-buildspecs

# Create CodeBuild projects mentioning the BuildSpecs in the S3 bucket
lstk aws codebuild create-project --name demo-test \
    --source type=CODEPIPELINE,buildspec=arn:aws:s3:::demo-buildspecs/demo-test.yaml \
    --artifacts type=CODEPIPELINE \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux-x86_64-standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --service-role ${ROLE_ARN}

lstk aws codebuild create-project --name demo-publish \
    --source type=CODEPIPELINE,buildspec=arn:aws:s3:::demo-buildspecs/demo-publish.yaml \
    --artifacts type=CODEPIPELINE \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux-x86_64-standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --service-role ${ROLE_ARN}

# Create a CodeConnection connection. This is optional in LocalStack.
CODECONNECT_ARN=$(lstk aws codeconnections create-connection --connection-name demo-connection --provider-type GitHub --query ConnectionArn --output text)

# Create the artifact bucket
lstk aws s3 mb s3://demo-artif-bucket

# Create the pipeline
lstk aws codepipeline create-pipeline --pipeline file://./demo-pipeline.json

# Wait for the pipeline to finish
MAX_WAIT_SECONDS=${MAX_WAIT_SECONDS:-1800}
status=
waited=0
until [[ $status == Succeeded ]]; do
    if [[ $status =~ ^(Failed|Stopped|Superseded)$ ]]; then
        echo "Pipeline execution ended with status $status"
        lstk aws codepipeline get-pipeline-state --name demo-pipeline
        exit 1
    fi
    if (( waited >= MAX_WAIT_SECONDS )); then
        echo "Pipeline did not finish within ${MAX_WAIT_SECONDS}s, last status: $status"
        exit 1
    fi
    sleep 5
    waited=$((waited + 5))
    status=$(lstk aws codepipeline list-pipeline-executions --pipeline-name demo-pipeline --output text --query 'pipelineExecutionSummaries[0].status')
done

# Configure NPM to work with the local CodeArtifact repository
# Warning: This will reconfigure your system NPM configuration
lstk aws codeartifact login --tool npm --domain demo-domain --repository demo-repo

# Try to download the NPM package
npm pack my-lodash-fork

# Check the downloaded package is the fork published by the pipeline
tar -xzOf my-lodash-fork-*.tgz package/package.json | grep '"name": "my-lodash-fork"'
