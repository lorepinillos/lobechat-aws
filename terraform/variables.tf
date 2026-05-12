variable "aws_region" {
  description = "AWS region. Spec mandates eu-west-1."
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "Local AWS credentials profile name (~/.aws/credentials)."
  type        = string
  default     = "esade"
}

variable "project_name" {
  description = "Short name used as resource prefix and in tags."
  type        = string
  default     = "lobechat"
}

variable "environment" {
  description = "Environment tag (dev / stage / prod)."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag for cost attribution."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the instance. Use your public IP / 32."
  type        = string
}

variable "ssh_public_key" {
  description = "Contents of the SSH public key to install on the instance."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. Spec requires >= 4 vCPU and >= 16 GB RAM."
  type        = string
  default     = "t3.xlarge"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB. Spec requires >= 60 GB gp3."
  type        = number
  default     = 60
}

variable "bedrock_inference_profile_arns" {
  description = "ARNs of the Bedrock inference profiles the instance is allowed to invoke."
  type        = list(string)
  default = [
    # EU profiles for cross-region inference (eu-west-1 is in the EU group).
    # Pattern: arn:aws:bedrock:<region>:<account>:inference-profile/<id>
    # We expand these dynamically in iam.tf using the account + region so
    # no account ID needs to be hardcoded here.
  ]
}

variable "bedrock_inference_profile_ids" {
  description = "Bedrock inference profile IDs (used to build ARNs in iam.tf)."
  type        = list(string)
  default = [
    "eu.anthropic.claude-haiku-4-5-20251001-v1:0",
    "eu.anthropic.claude-sonnet-4-5-20250929-v1:0",
    "eu.anthropic.claude-sonnet-4-6",
  ]
}

variable "repo_url" {
  description = "Git URL of the lobechat-aws fork the EC2 should clone at boot."
  type        = string
  default     = "https://github.com/lorepinillos/lobechat-aws.git"
}

variable "repo_ref" {
  description = "Branch or tag to check out from repo_url."
  type        = string
  default     = "main"
}

variable "bedrock_foundation_model_arns_extra" {
  description = "Optional extra Bedrock foundation model ARNs allowed (for cross-region inference, the underlying model ARNs are also required)."
  type        = list(string)
  default     = []
}
