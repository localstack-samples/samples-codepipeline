# LocalStack CodePipeline Samples

This repository contains two sample applications that demonstrate LocalStack's CodePipeline emulation with CodeBuild, S3, and CodeArtifact workflows.

## LocalStack CodePipeline Notes

LocalStack emulates a practical subset of AWS CodePipeline behavior for local development and testing. Before running these samples, review the current CodePipeline limitations:

- https://docs.localstack.cloud/aws/services/codepipeline/#limitations

## Prerequisites

- A valid [LocalStack for AWS license](https://localstack.cloud/pricing), which provides a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/getting-started/auth-token/) required to run these samples.
- [Docker](https://docs.docker.com/get-docker/) with access to the Docker socket.
- [LocalStack CLI](https://docs.localstack.cloud/user-guide/tools/localstack-cli/) (`awslocal`) and AWS CLI.
- A GitHub Personal Access Token exported as `CODEPIPELINE_GH_TOKEN` (used by both samples to download source archives).
- `npm` (required for the CodeArtifact publishing sample).

```bash
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
export CODEPIPELINE_GH_TOKEN=<your-github-pat>
```

## Samples

- [1-codebuild-compile-s3-upload](1-codebuild-compile-s3-upload/README.md): Builds `fzf` with CodeBuild and uploads the resulting binary to S3 through CodePipeline.
- [2-codebuild-test-codeartifact-publish](2-codebuild-test-codeartifact-publish/README.md): Tests a `lodash` fork and publishes the package to CodeArtifact through CodePipeline.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
