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

# Instance options:
# All 8g series are ARM-based Graviton 4 chips
# Uses always-on memory encryption, dedicated cache for every vCPU
# and support for pointer authentication. 
# Use 7g series if 8g is not available. 

# M8g series: General purpose workloads
# m8g.large: 2 vCPU, 8 GiB RAM
# m8g.48xlarge: 192 vCPU, 768 GiB RAM

# C8g series: Compute-intensive workloads
# c8g.large: 2 vCPU, 4 GiB RAM
# c8g.48xlarge: 192 vCPU, 382 GiB RAM

# R8g series: Memory-intensive workloads
# r8g.large: 2 vCPU, 16 GiB RAM
# r8g.48xlarge: 96 vCPU, 1536 GiB RAM

# X8g series: Even more memory-intensive workloads
# x8g.large:    2 vCPU,   32 GiB RAM (0.3019 USD/hour)
# x8g.48xlarge: 192 vCPU, 3072 GiB RAM (28.0608 USD/hour)
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m7g.large"
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