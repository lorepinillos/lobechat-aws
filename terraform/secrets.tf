# Intentionally empty. The ESADE sandbox role denies both ssm:* and
# secretsmanager:CreateSecret, so the spec's two named secret stores are
# unavailable. App .env is written directly to the EC2 EBS volume by
# user_data.sh (root:root, mode 0600) as a documented deviation. Restore
# the aws_secretsmanager_secret resource here when the permission is granted.
