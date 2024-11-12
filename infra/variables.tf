variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "availability_zone" {
  description = "Availability zone for the EC2 instance"
  type        = string
  default     = "eu-central-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "c7g.large"  # Graviton 3 (ARM), 2 vCPUs, 4 GiB RAM
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 16
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instance access"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcQK5Naws5UrdVATzc0XjtXyIMaGoVOOFMbMI+zEe3r"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "mpc-key"
}