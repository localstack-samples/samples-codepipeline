# LocalStack CodePipeline Samples

This repository contains two sample applications that demonstrate [LocalStack's CodePipeline emulation](https://docs.localstack.cloud/aws/services/codepipeline) with CodeBuild, S3, and CodeArtifact workflows.

## Prerequisites

- A valid [LocalStack for AWS license](https://localstack.cloud/pricing), which provides a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/aws/getting-started/auth-token/) required to run these samples.
- [Docker](https://docs.docker.com/get-docker/) with access to the Docker socket.
- [`lstk` CLI](https://docs.localstack.cloud/aws/developer-tools/running-localstack/lstk/) and AWS CLI, required by `lstk aws`.
- A GitHub Personal Access Token exported as `CODEPIPELINE_GH_TOKEN` (used by both samples to download source archives).
- `npm` (required for the CodeArtifact publishing sample).

```bash
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
export CODEPIPELINE_GH_TOKEN=<your-github-pat>
```

If you start LocalStack with `lstk start`, export the token as `LOCALSTACK_CODEPIPELINE_GH_TOKEN` instead. `lstk` only forwards `LOCALSTACK_`-prefixed variables to the container, which strips the prefix.

Each `run.sh` fails if the pipeline execution fails or takes longer than `MAX_WAIT_SECONDS` (default 1800).

Pull the CodeBuild images before the first run:

```bash
docker pull public.ecr.aws/codebuild/amazonlinux-x86_64-standard:5.0
docker pull localstack/aws-codebuild-local:2
```

LocalStack stops tracking a build if its image is still downloading a few seconds after the build starts, and the pipeline then stays `InProgress`.

## Samples

- [1-codebuild-compile-s3-upload](1-codebuild-compile-s3-upload/README.md): Builds `fzf` with CodeBuild and uploads the resulting binary to S3 through CodePipeline.
- [2-codebuild-test-codeartifact-publish](2-codebuild-test-codeartifact-publish/README.md): Tests a `lodash` fork and publishes the package to CodeArtifact through CodePipeline.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
