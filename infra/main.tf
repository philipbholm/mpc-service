terraform {
  required_version = "~> 1.7.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.71.0"
    }
  }
}

provider "aws" {
  profile = "tofu-user"
  region  = var.aws_region
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["main"]
  }
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["public"]
  }
}

data "aws_security_group" "full_access" {
  filter {
    name   = "tag:Name"
    values = ["full-access"]
  }
}

resource "aws_instance" "mpc_server" {
  ami                    = "ami-077e7b988e15f909f" # Amazon Linux 2023 AMI
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone
  key_name               = aws_key_pair.mpc_server.key_name
  iam_instance_profile   = aws_iam_instance_profile.mpc_server.name
  vpc_security_group_ids = [data.aws_security_group.full_access.id]
  subnet_id              = data.aws_subnet.public.id
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  enclave_options {
    enabled = true
  }

  metadata_options {
    http_tokens = "required"
  }

  user_data = <<-EOF
        #!/bin/bash
        # Install dependencies
        sudo dnf -y install aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel git-all

        # Update user permissions
        sudo usermod -aG ne ec2-user && sudo usermod -aG docker ec2-user
        
        # Allocate resources to enclave 
        # Leaves 1 vCPU and 1024 GiB RAM for the parent
        MEMORY_AVAILABLE=$(awk '/MemTotal/ {printf "%d", $2/1024 - 1024}' /proc/meminfo)
        CPU_AVAILABLE=$(($(nproc) - 1))
        sudo sed -i "s/^memory_mib:.*/memory_mib: ${MEMORY_AVAILABLE}/" /etc/nitro_enclaves/allocator.yaml
        sudo sed -i "s/^cpu_count:.*/cpu_count: ${CPU_AVAILABLE}/" /etc/nitro_enclaves/allocator.yaml
        
        # Enable and start services
        sudo systemctl enable --now docker
        sudo systemctl enable --now nitro-enclaves-allocator.service
        sudo systemctl enable --now nitro-enclaves-vsock-proxy.service
        
        # Install gvproxy
        sudo dnf -y install golang
        git clone https://github.com/containers/gvisor-tap-vsock.git /home/ec2-user/gvisor-tap-vsock
        sudo chown -R ec2-user:ec2-user /home/ec2-user/gvisor-tap-vsock
        cd /home/ec2-user/gvisor-tap-vsock
        go build -o gvproxy ./cmd/gvproxy
        sudo mv gvproxy /usr/local/bin
        cd -

        # Pull enclave code
        git clone https://github.com/philipbholm/mpc-service.git /home/ec2-user/mpc-service
        sudo chown -R ec2-user:ec2-user /home/ec2-user/mpc-service

        # Aliases
        echo "alias stop='nitro-cli terminate-enclave --all'" >> .bashrc
        echo "alias desc='nitro-cli describe-enclaves'" >> .bashrc
        
        sudo reboot
    EOF

  tags = {
    Name = "mpc-server"
  }
}

resource "aws_key_pair" "mpc_server" {
  key_name   = var.key_name
  public_key = var.ssh_public_key
}

resource "aws_iam_instance_profile" "mpc_server" {
  name = "mpc-server"
  role = aws_iam_role.mpc_server.name
}

resource "aws_iam_role" "mpc_server" {
  name = "mpc-server"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mpc_server_attachment" {
  role       = aws_iam_role.mpc_server.name
  policy_arn = aws_iam_policy.mpc_server.arn
}

resource "aws_iam_policy" "mpc_server" {
  name = "mpc-server"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "sts:AssumeRole",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}