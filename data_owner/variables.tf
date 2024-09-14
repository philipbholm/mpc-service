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
