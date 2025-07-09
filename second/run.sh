set -xeu

# IAM

aws iam create-role --role-name demo-role --assume-role-policy-document file://role.json
aws iam put-role-policy --role-name demo-role --policy-name demo-policy --policy-document file://policy.json

ROLE_ARN=arn:aws:iam::623948600419:role/demo-role

# CodeArtifact

aws codeartifact create-domain --domain demo-domain
aws codeartifact create-repository --domain demo-domain --repository demo-repo

# CodeBuild

aws s3 mb s3://demo-buildspecs
aws s3 cp demo-test.yaml s3://demo-buildspecs
aws s3 cp demo-publish.yaml s3://demo-buildspecs

aws codebuild create-project --name demo-test \
    --source type=CODEPIPELINE,buildspec=arn:aws:s3:::demo-buildspecs/demo-test.yaml \
    --artifacts type=CODEPIPELINE \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux-x86_64-standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --service-role ${ROLE_ARN}

aws codebuild create-project --name demo-publish \
    --source type=CODEPIPELINE,buildspec=arn:aws:s3:::demo-buildspecs/demo-publish.yaml \
    --artifacts type=CODEPIPELINE \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux-x86_64-standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --service-role ${ROLE_ARN}

#
# CodeConnections
#

aws codeconnections create-connection --connection-name demo-connection --provider-type GitHub
# Validate on AWS Console

CODECONNECT_ARN=arn:aws:codeconnections:eu-central-1:623948600419:connection/b61a7b14-1e38-4c0c-a276-556bdab96fa3

#
# CodePipeline
#

aws s3 mb s3://demo-artif-bucket

aws codepipeline create-pipeline --pipeline file://./demo-pipeline.json

aws codeartifact get-repository-endpoint --domain demo-domain --repository demo-repo --format npm
aws codeartifact get-authorization-token --domain demo-domain --query authorizationToken --output text

npm config set registry http://demo-domain-000000000000.d.codeartifact.eu-central-1.localhost.localstack.cloud:4566/npm/demo-repo/
npm config set //demo-domain-000000000000.d.codeartifact.eu-central-1.localhost.localstack.cloud:4566/npm/demo-repo/:_authToken=asdf123

npm pack my-lodash-fork
