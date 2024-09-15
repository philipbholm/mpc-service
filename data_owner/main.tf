terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.67.0"
        }
    }
}

variable "region" {
    description = "The AWS region to deploy resources"
    type = string
    default = "eu-central-1"
}

variable "mpc_instance_role_arn" {
    description = "The ARN of the IAM instance role of the MPC server"
    type = string
}

variable "enclave_image_sha" {
    description = "The SHA hash of the enclave image"
    type = string
}

provider "aws" {
    region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "main" {
    force_destroy = true
}

output "s3_bucket_arn" {
    value = aws_s3_bucket.main.arn
    sensitive = true
}

resource "aws_kms_key" "main" {
    key_usage = "ENCRYPT_DECRYPT"
    customer_master_key_spec = "SYMMETRIC_DEFAULT"
    deletion_window_in_days = 7

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = "Enable IAM User Permissions",
                Effect = "Allow"
                Principal = {
                    AWS = [
                        data.aws_caller_identity.current.arn,
                        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                    ]
                }
                Action = "kms:*"
                Resource = "*"
            },
            {
                Sid = "Allow use of the key"
                Effect = "Allow"
                Action = [
                    "kms:Decrypt",
                    "kms:Encrypt",
                    "kms:GenerateDataKey"
                ]
                Principal = {
                    AWS = var.mpc_instance_role_arn
                }
                Resource = "*"
                Condition = {
                    StringEqualsIgnoreCase = {
                        "kms:RecipientAttestation:ImageSha384": var.enclave_image_sha
                    }
                }
            }
        ]
    })
}

output "kms_key_arn" {
    value = aws_kms_key.main.arn
    sensitive = true
}

output "kms_key_id" {
    value = aws_kms_key.main.key_id
    sensitive = true
}

resource "aws_iam_role" "data_owner_role" {
    name = "data_owner_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "sts:AssumeRole"
                Principal = {
                    "AWS": data.aws_caller_identity.current.arn
                }
            }
        ]
    })
}

output "data_owner_role_arn" {
    value = aws_iam_role.data_owner_role.arn
    sensitive = true
}

resource "aws_iam_policy" "data_owner_actions" {
    name = "data_owner_actions"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject",
                    "s3:ListBucket"
                ]
                Resource = [
                    aws_s3_bucket.main.arn,
                    "${aws_s3_bucket.main.arn}/*"
                ]
            },
            {
                Effect = "Allow"
                Action = [
                    "kms:Encrypt",
                    "kms:Decrypt",
                    "kms:GenerateDataKey"
                ]
                Resource = aws_kms_key.main.arn
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "data_owner_actions_attachment" {
    role = aws_iam_role.data_owner_role.name
    policy_arn = aws_iam_policy.data_owner_actions.arn
}
