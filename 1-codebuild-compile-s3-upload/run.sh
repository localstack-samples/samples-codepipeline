#!/usr/bin/env bash

set -xeuo pipefail

# Create service IAM roles
lstk aws iam create-role --role-name demo-role --assume-role-policy-document file://role.json
lstk aws iam put-role-policy --role-name demo-role --policy-name demo-policy --policy-document file://policy.json

# Create CodeConnection connection
lstk aws codeconnections create-connection --connection-name demo-connection --provider-type GitHub

# Create CodeBuild project
lstk aws codebuild create-project \
    --name demo-compile \
    --source type=CODEPIPELINE,buildspec="$(cat buildspec.yaml)" \
    --artifacts type=CODEPIPELINE \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --service-role arn:aws:iam::000000000000:role/demo-role

# Create pipeline artifact bucket
lstk aws s3 mb s3://artifact-bucket

# Create pipeline output bucket
lstk aws s3 mb s3://output-bucket

# Create pipeline
lstk aws codepipeline create-pipeline --pipeline file://./pipeline.json

# Check pipeline status
lstk aws codepipeline list-pipeline-executions --pipeline-name demo-pipeline

# Wait for pipeline to finish
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

# Retrieve build
lstk aws s3 cp s3://output-bucket/fzf/fzf .

# Try build
file fzf
chmod +x fzf
./fzf --version | grep '^0.62 '
