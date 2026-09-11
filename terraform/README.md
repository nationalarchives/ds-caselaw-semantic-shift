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

## Beta app deployment (caselaw-semantic-beta)

Beta is deployed as a small, explicit second application on the existing Alpha
platform (shared VPC, ALB, CloudFront distribution, ECS cluster, and build
artifact bucket), reachable at `https://research.caselaw.nationalarchives.gov.uk/beta`.
It intentionally does not generalise the `app_*` resources into a reusable
`apps` map (see `AWS_BETA_DEPLOYMENT_PLAN.md` at the repo root for that
longer-term option) — this keeps the change small and reviewable given a short
delivery window.

New Terraform modules are sourced from
[`nationalarchives/da-terraform-modules`](https://github.com/nationalarchives/da-terraform-modules)
(pinned by commit via `local.tf_modules_ref` in `locals.tf`, as the module repo
has no tagged releases yet) for: ECR, S3, IAM role/policy, and security group.
There is no published module yet for ECS services/tasks, ALB, CloudFront, or
CodePipeline/CodeBuild/CodeDeploy, so those Beta resources are plain
`aws_*` resources following the same pattern as the existing alpha resources.

### Owning repositories

- Application code, Dockerfile, dependencies, and app-level tests: [`nationalarchives/da-caselaw-semantic-beta`](https://github.com/nationalarchives/da-caselaw-semantic-beta)
- Shared/Beta infrastructure (this repo): ECR, S3 model asset bucket, ECS
  task/service, ALB target groups/listener rule, CloudFront `/beta*` behaviour,
  CodePipeline/CodeBuild/CodeDeploy, IAM, and the Secrets Manager basic auth
  reference — all in `terraform/*-beta*.tf` and `terraform/*beta*` template files.

### Deployment and rollback

- Deploy: push to `main` on the Beta app repo triggers
  `${project_name}-beta-build` (CodePipeline → CodeBuild → CodeDeploy
  blue/green), the same pattern as alpha. The pipeline records the source
  commit SHA in the image tag (`commit-$CODEBUILD_RESOLVED_SOURCE_VERSION`) and
  registers a new task definition revision per deploy.
- Rollback: redeploy a previous successful pipeline execution from CodePipeline
  history, or use CodeDeploy's automatic rollback (`DEPLOYMENT_FAILURE` already
  triggers auto-rollback). Because deployments are blue/green, the previous
  task set remains available to fail back to during the deployment bake window.
- First-time infrastructure changes require `terraform plan`/`apply` from this
  directory; application-only changes do not.

### Model/embedding updates

- Model and embedding updates for Beta are a manual, ad hoc process run out of
  band by the maintainer against the existing S3 Vectors bucket/index referenced
  by `beta_s3vectors_index_arn`. The web ECS task has read-only `QueryVectors`
  access and never writes vectors at runtime.
- There is no Terraform-managed Beta model-assets S3 bucket and no automated
  ingestion pipeline for this; see the non-blocking follow-up ticket for
  data-recovery/versioning improvements.

### Secrets: Beta CloudFront basic auth

- The secret container (`aws_secretsmanager_secret.beta_cloudfront_basic_auth`,
  named via `beta_cloudfront_basic_auth_secret_name`) is created by Terraform.
  The secret **value** is provisioned and rotated out of band and must never be
  committed to tfvars, code, container images, logs, or Slack.
- Bootstrap / rotation procedure:
  1. `terraform apply` (creates/updates the empty secret container if needed).
  2. Seed or rotate the value directly in Secrets Manager, storing a JSON
     object of username→password with no single-quote characters (the value is
     interpolated into a CloudFront Function, so a stray `'` would break it):
     `aws secretsmanager put-secret-value --secret-id <beta_cloudfront_basic_auth_secret_name> --secret-string '{"researcher":"<password>"}'`
  3. `terraform apply` again — this re-reads the current secret version and
     redeploys the `beta-service-viewer-request` CloudFront Function with the
     new credentials.
- Basic auth is treated as an access limiter, not strong access control, for
  this R&D deployment; a leaked credential is low risk (public source data) and
  is handled by rotating per the steps above, not by incident response.

### Logging

Following the existing Alpha/FCL standard already in place in this repo:

- **Application logs**: CloudWatch Logs group `/ecs/beta` (30-day retention,
  matching `/ecs/app`), written via the `awslogs` driver.
- **ECS**: task/service events visible via the ECS console/CLI; no separate
  ECS Exec logging is enabled (ECS Exec is not enabled for Beta).
- **CloudFront**: access is via the shared distribution; enable/verify
  standard logging in line with however the alpha distribution's logging is
  configured (no separate logging config was added specifically for Beta).
- **S3**: the Beta model assets bucket (via the `s3` module) has a companion
  access-log bucket created by default, matching the module's standard
  behaviour used elsewhere in this repo.
- Access control on all of the above follows the same IAM boundaries as the
  rest of this stack (task roles, execution roles, and CI roles scoped as
  documented in `ecs-task-definition-beta-iam.tf`).

### Data recovery / audit posture (S3 Vectors and model assets)

- Model/embedding updates are manual today (see above); there is no automated
  backup beyond S3 bucket versioning already enabled on the Beta model assets
  bucket by the `s3` module.
- The S3 Vectors index itself does not currently have documented S3 data-event
  logging enabled specifically for Beta.
- A simple recovery improvement (e.g. a documented restore runbook, or
  extending data-event logging to the S3 Vectors bucket) is tracked as a
  **non-blocking follow-up**, not a blocker for this deployment.

### Model provenance

- Beta's search results are model-generated semantic associations (embedding
  similarity), not verified legal categorisation. This is an R&D prototype;
  full provenance, evidential audit, explanation of results, and
  production-grade governance are explicitly deferred until productionisation,
  per the ticket for this deployment.

### Out of scope for this deployment (tracked separately)

- CloudFront/WAF rate limiting — see the follow-up ticket recorded in
  `FOLLOW_UP_TICKETS.md` at the repo root.
- Any dependency vulnerability, unsupported runtime, or hardening finding
  surfaced while implementing this deployment is tracked as its own linked
  blocking ticket (see `FOLLOW_UP_TICKETS.md`), not fixed silently here.
