# Terraform Folder Guide

This folder mixes Terraform-managed infrastructure with templates used at CI/CD runtime.

## Template ownership and usage

### Terraform-consumed templates

These files are read by Terraform during `terraform plan/apply` via `templatefile(...)`:

- `policies/`
- `buildspecs/`
- `cloudfront-functions/`

### Runtime-rendered templates (not directly applied by Terraform)

These files are rendered during CodeBuild/CodePipeline execution and passed to AWS APIs:

- `appspecs/`
- `container-definitions/`

In particular:

- `appspecs/ecs.json.tpl` is rendered to `appspec.json` by CodeBuild and used by CodeDeploy.
- `container-definitions/app.json.tpl` is rendered by CodeBuild and used to register a new ECS task definition.

## Why this matters

- Editing Terraform-consumed templates may require `terraform apply` to update infrastructure configuration.
- Editing runtime-rendered templates usually requires commit/push and a new pipeline run, but not a Terraform apply.

## Current wiring

- `codebuild-app-build-pipeline.tf` injects `buildspecs/app.json.tpl` into the CodeBuild project.
- `buildspecs/app.json.tpl` renders `container-definitions/app.json.tpl` and `appspecs/ecs.json.tpl` using `envsubst`.
