# Secure Captures backend

AWS backend and website for Secure Captures: a signed-in user takes encrypted photos on Android,
and this backend proves each photo and its time and GPS metadata were not changed, stores a
verified copy, and lets the user browse their photos. Everything runs in `eu-west-2` (London)
and is provisioned by Terraform. The Android app lives in
[secure-captures-android](https://github.com/torqueing/secure-captures-android).

## Layout

| Path | What it is |
| --- | --- |
| `backend/` | Node.js Lambda functions in TypeScript, bundled by esbuild |
| `infra/bootstrap/` | One-off: Terraform state bucket and the GitHub Actions roles |
| `infra/stack/` | The whole backend for one environment |
| `infra/modules/` | `kms`, `auth`, `database`, `storage`, `lambdas`, `lambda-function`, `api`, `monitoring` |
| `infra/envs/dev`, `infra/envs/prod` | Environment roots that call the stack |
| `web/` | Website (milestone 4) |

## What is deployed so far (milestone 1)

- KMS keys: storage (symmetric, yearly rotation), upload wrapping (RSA 4096) and receipt signing (ECC P-256).
- Cognito user pool with email sign-up confirmed by an emailed code, optional TOTP, Android and web app clients.
- DynamoDB table with a `captureId` index, TTL and point-in-time recovery, encrypted with the storage key.
- S3 buckets `web`, `incoming`, `vault` (versioned, Object Lock enabled) and `logs`.
- HTTP API with a Cognito JWT authoriser: `GET /api/v1/health` (public) and `GET /api/v1/me`.
- Lambda functions `api` and `cognito-post-confirm`, which creates the user profile on sign-up.
- Alarms on Lambda errors and API 5xx rate, sent to an SNS email topic.

## First-time setup

You need Terraform 1.10 or later, Node.js 24, and AWS credentials for an administrator in the
target account (for example `aws sso login`).

1. Create the state bucket and the GitHub Actions roles. This uses local state and runs once:

   ```sh
   cd infra/bootstrap
   terraform init
   terraform apply
   ```

   Note the outputs `state_bucket`, `plan_role_arn` and `apply_role_arn`.

2. In this repository on GitHub, open **Settings > Secrets and variables > Actions** and add
   these as repository variables (the **Variables** tab) or repository secrets; either works:

   | Variable | Value |
   | --- | --- |
   | `TF_STATE_BUCKET` | `state_bucket` output |
   | `AWS_PLAN_ROLE_ARN` | `plan_role_arn` output |
   | `AWS_APPLY_ROLE_ARN` | `apply_role_arn` output |
   | `ALARM_EMAIL` | address that should receive alarms |

3. Under **Settings > Environments**, create `dev` and `prod`. Give `prod` yourself as a
   required reviewer so prod deploys wait for your approval.

4. Push to `main` (or run the **Deploy** workflow) to deploy dev. AWS sends a confirmation email
   to `ALARM_EMAIL`; click it to start receiving alarms.

To deploy from your own machine instead:

```sh
(cd backend && npm ci && npm run build)
cd infra/envs/dev
terraform init -backend-config="bucket=<state_bucket>"
terraform apply -var "alarm_email=<you@example.com>"
```

## Checking milestone 1

Sign up a real address against dev and confirm it with the emailed code:

```sh
cd backend
SC_CLIENT_ID=$(terraform -chdir=../infra/envs/dev output -raw android_client_id) \
SC_API_URL=$(terraform -chdir=../infra/envs/dev output -raw api_url) \
npm run smoke:signup -- you@example.com
```

The script calls the health endpoint, signs up, asks for the code from your inbox and confirms
it. The user's profile then appears in the DynamoDB table as `USER#<sub>` / `PROFILE`.

## Development

```sh
cd backend
npm ci
npm run typecheck
npm test
npm run build      # writes dist/<function>.zip, which Terraform deploys
```

CI runs the tests, builds the bundles, then runs `terraform fmt`, `validate`, `tflint` and
Checkov on every pull request, and a dev plan once the AWS variables are set. Checks skipped on
purpose are listed with reasons in `infra/.checkov.yaml`.

## Notes and known limits

- Bucket names end in the AWS account ID because S3 names are global.
- Cognito sends email from its own sender, which allows about 50 emails a day. Move to Amazon SES
  before real users sign up.
- HTTP APIs throttle per stage (50 requests per second, bursts of 100), not per user. A per-IP
  limit arrives with WAF in milestone 5.
- Cognito threat protection is on in prod only; it needs the Plus tier, billed per active user.
