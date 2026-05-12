data "aws_caller_identity" "current" {}

# Build inference-profile ARNs from IDs + account + region. Cross-region
# inference for Bedrock requires permission on BOTH the inference profile and
# the underlying foundation model in every region the profile fans out to.
locals {
  inference_profile_arns = [
    for id in var.bedrock_inference_profile_ids :
    "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${id}"
  ]
}

resource "aws_iam_role" "instance" {
  name        = "${var.project_name}-${var.environment}-instance-role"
  description = "Role assumed by the LobeChat EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_invoke" {
  name = "bedrock-invoke"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeInferenceProfiles"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
        ]
        Resource = local.inference_profile_arns
      },
      {
        Sid    = "InvokeUnderlyingFoundationModels"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
        ]
        # Cross-region inference profiles call the underlying model in every
        # region in the profile's region group. We grant access broadly to the
        # foundation-model resource type so eu-central-1, eu-north-1, etc. are
        # covered. Anthropic models (chat) + Amazon Titan embed (files RAG).
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.*",
          "arn:aws:bedrock:*::foundation-model/amazon.titan-embed-*",
        ]
      },
      {
        Sid    = "ListAndDescribe"
        Effect = "Allow"
        Action = [
          "bedrock:ListFoundationModels",
          "bedrock:ListInferenceProfiles",
          "bedrock:GetInferenceProfile",
          "bedrock:GetFoundationModel",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.project_name}-${var.environment}-instance-profile"
  role = aws_iam_role.instance.name
}
