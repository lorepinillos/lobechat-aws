# Terraform — LobeChat AWS deploy

Infrastructure-as-Code for the DevOps final project. Provisions:

- VPC + public subnet + Internet Gateway + route table (10.0.0.0/16)
- Security group: SSH from operator IP, public 80/443
- EC2 instance (Ubuntu 24.04, x86_64, gp3 root volume)
- Elastic IP
- IAM instance role with `bedrock:InvokeModel` on the configured inference profiles

The instance bootstraps via `user_data.sh` and currently installs Docker +
the AWS CLI. The Caddy reverse proxy and LobeChat stack are added in a
subsequent iteration once the bare box is verified reachable.

**Note on secrets.** The ESADE sandbox role denies both `ssm:*` and
`secretsmanager:CreateSecret`, so the app `.env` is not managed through
either AWS service. Stage 2 of `user_data.sh` will write the `.env` directly
to the EC2 EBS volume (`/opt/lobechat/.env`, root:root, mode 0600). This
deviation from the spec is documented in `docs/evidence/REPORT.md`.

## Prerequisites

1. AWS credentials available locally as a named profile (default: `esade`):
   ```
   ~/.aws/credentials  → [esade] aws_access_key_id / aws_secret_access_key / aws_session_token
   ~/.aws/config       → [profile esade] region = eu-west-1
   ```
2. Terraform >= 1.5 on `$PATH`.
3. An SSH key pair (default lookup: `~/.ssh/id_ed25519`).

## First-time setup

```bash
cd terraform
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

The plan output should show ~15 resources to create. Inspect carefully.

## Useful outputs

```bash
terraform output public_ip          # Elastic IP
terraform output public_hostname    # <dashed-ip>.traefik.me
terraform output https_url          # https://<dashed-ip>.traefik.me
terraform output ssh_command        # ssh -i ... ubuntu@<eip>
```

## Tearing down

```bash
terraform destroy
```

Always destroy before letting sandbox credentials expire — orphaned EIPs and
EBS volumes accrue charges.
