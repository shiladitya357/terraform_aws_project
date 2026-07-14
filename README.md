# Simple AWS three-tier Terraform project

This is a learning-focused, modular AWS Terraform example for a browser-based application.
It deploys one stack per environment and AWS region:

```text
Browser -> public Application Load Balancer -> web EC2 Auto Scaling Group
        -> private Application Load Balancer -> app EC2 Auto Scaling Group
        -> PostgreSQL RDS database
```

The load balancers and compute layers span two Availability Zones. Web and app instances are private; only the public ALB accepts internet traffic.

## Layout

- `modules/network`: VPC, subnets, routing, and a single NAT gateway.
- `modules/security`: security groups and their tier-to-tier rules.
- `modules/compute`: launch templates, Auto Scaling Groups, and ALB listener/target-group resources.
- `modules/database`: PostgreSQL RDS subnet group and instance.
- `environments/<environment>/<region>`: small root modules and independent state settings.

## Prerequisites

- Terraform >= 1.6
- AWS credentials with permissions to create the resources
- An existing S3 bucket and DynamoDB table for Terraform state locking. See `bootstrap-state/`.
- An EC2 key pair if you want SSH access (optional; set `key_name`).

## Deploy an environment

1. Create a remote-state bucket/table once using `bootstrap-state` (or use existing ones).
2. Copy the environment's `backend.hcl.example` to `backend.hcl` and set your state bucket name.
3. Copy `terraform.tfvars.example` to `terraform.tfvars`; set `db_password` to a strong secret.
4. Initialise and apply, for example:

```bash
cd environments/dev/us-east-1
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

`backend.hcl` and `terraform.tfvars` are ignored by Git. Each environment/region has a unique state key such as `three-tier/dev/us-east-1/terraform.tfstate`.

## Jenkins CI/CD

The included `Jenkinsfile` validates and plans every run, then pauses for approval before an `apply` or `destroy` operation. Configure these Jenkins credentials before running it:

- `aws-terraform`: an **AWS Credentials** entry with rights to manage the target infrastructure and read/write the state bucket.
- `terraform-db-password`: a **Secret Text** entry containing the RDS password.

Run the pipeline with the target `ENVIRONMENT`, `AWS_REGION`, existing `STATE_BUCKET`, and operation (`plan`, `apply`, or `destroy`). State keys are calculated automatically by environment and region. The Jenkins agent needs Terraform installed and the AWS Credentials Binding, Credentials Binding, and Workspace Cleanup plugins.

## GitHub Actions CI/CD

`.github/workflows/terraform.yml` provides the equivalent manually triggered workflow. Select the environment, region, action, state bucket, and lock table in the **Run workflow** form. It initializes, formats, validates, and plans every run; `apply` and `destroy` then use the generated plan artifact.

Configure these repository secrets:

- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`: credentials with permission to manage the target infrastructure and access the remote state bucket. Set `AWS_SESSION_TOKEN` too when using temporary credentials.
- `TF_VAR_DB_PASSWORD`: the RDS password passed to Terraform as a sensitive input.

To retain Jenkins-style approval before changing infrastructure, create GitHub Environments named `dev`, `stage`, and `prod`, then add required reviewers in each environment's protection rules. The workflow's `apply` job targets the selected environment and waits for that approval; `plan` runs without it.

## Learning notes

- The single NAT gateway reduces cost and keeps the network module approachable, but is not highly available. Use one NAT gateway per AZ for production workloads.
- Database credentials are supplied as a sensitive Terraform variable for simplicity. In production, use Secrets Manager and avoid placing secrets in Terraform state.
- The included user data serves a basic page and uses a simple health endpoint. Replace it with AMIs or a deployment pipeline when learning application delivery.
- Before deleting a stack, set `deletion_protection = false` for production and run `terraform destroy` from the same environment folder.
