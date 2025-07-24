#!/bin/env bash

set -xeuo pipefail

# Create IAM role and policy
awslocal iam create-role --role-name demo-role --assume-role-policy-document file://role.json
awslocal iam put-role-policy --role-name demo-role --policy-name demo-policy --policy-document file://policy.json

ROLE_ARN=$(awslocal iam get-role --role-name demo-role --query Role.Arn --output text)

# Create CodeArtifact repository for the NPM package
awslocal codeartifact create-domain --domain demo-domain
awslocal codeartifact create-repository --domain demo-domain --repository demo-repo

# Upload BuildSpecs to an S3 bucket
awslocal s3 mb s3://demo-buildspecs
awslocal s3 cp demo-test.yaml s3://demo-buildspecs
awslocal s3 cp demo-publish.yaml s3://demo-buildspecs

# Create CodeBuild projects mentioning the BuildSpecs in the S3 bucket
awslocal codebuild create-project --name demo-test \
    --source type=CODEPIPELINE,buildspec=arn:aws:s3:::demo-buildspecs/demo-test.yaml \
    --artifacts type=CODEPIPELINE \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux-x86_64-standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --service-role ${ROLE_ARN}

awslocal codebuild create-project --name demo-publish \
    --source type=CODEPIPELINE,buildspec=arn:aws:s3:::demo-buildspecs/demo-publish.yaml \
    --artifacts type=CODEPIPELINE \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux-x86_64-standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --service-role ${ROLE_ARN}

# Create a CodeConnection connection. This is optional in LocalStack.
CODECONNECT_ARN=$(awslocal codeconnections create-connection --connection-name demo-connection --provider-type GitHub --query ConnectionArn --output text)

# Create the artifact bucket
awslocal s3 mb s3://demo-artif-bucket

# Create the pipeline
awslocal codepipeline create-pipeline --pipeline file://./demo-pipeline.json

# Wait for the pipeline to finish
status=
until [[ $status =~ Succeeded ]]; do
    status=$(awslocal codepipeline list-pipeline-executions --pipeline-name demo-pipeline --output text --query pipelineExecutionSummaries[0].status)
    sleep 5
done

# Configure NPM to work with the local CodeArtifact repository
# Warning: This will reconfigure your system NPM configuration
awslocal codeartifact login --tool npm --domain demo-domain --repository demo-repo

# Try to download the NPM package
npm pack my-lodash-fork
