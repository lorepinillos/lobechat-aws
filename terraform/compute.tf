data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "operator" {
  key_name   = "${var.project_name}-${var.environment}-operator"
  public_key = var.ssh_public_key
}

resource "aws_eip" "instance" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }
}

# Derived hostname used by Caddy / app config — nip.io resolves any
# <dashed-ip>.nip.io to the embedded IP. Caddy issues a Let's Encrypt
# cert at boot via HTTP-01 (port 80 is open and reaches the box).
#
# History: traefik.me DNS was failing on 2026-05-12, and sslip.io had
# been rate-limited by Let's Encrypt (250k certs/week hit). nip.io is
# the working alternative the spec also explicitly allows.
locals {
  ip_dashed       = replace(aws_eip.instance.public_ip, ".", "-")
  public_hostname = "${local.ip_dashed}.nip.io"        # LobeChat
  auth_hostname   = "auth-${local.ip_dashed}.nip.io"   # Casdoor
  s3_hostname     = "s3-${local.ip_dashed}.nip.io"     # MinIO
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = aws_key_pair.operator.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    aws_region      = var.aws_region
    public_hostname = local.public_hostname
    auth_hostname   = local.auth_hostname
    s3_hostname     = local.s3_hostname
    repo_url        = var.repo_url
    repo_ref        = var.repo_ref
  })

  # Containers reach IMDS via the docker bridge → host. Default hop limit (1)
  # blocks this; bump to 2 so LiteLLM/MCPHub boto3 can pick up the instance
  # role credentials.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Recreate the instance when user_data changes so we always get a fresh
  # bootstrap. Comment this out once the box is healthy and you only want
  # cosmetic re-applies.
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }

  depends_on = [
    aws_internet_gateway.main,
  ]
}

resource "aws_eip_association" "instance" {
  instance_id   = aws_instance.main.id
  allocation_id = aws_eip.instance.id
}
