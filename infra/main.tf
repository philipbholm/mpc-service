terraform {
  required_version = "~> 1.8.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.71.0"
    }
  }
}

provider "aws" {
  profile = "tofu-user"
  region  = "eu-central-1"
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
  instance_type          = "c7g.large"             # Graviton 3 (ARM), 2 vCPUs, 4 GiB RAM
  availability_zone      = "eu-central-1a"
  key_name               = aws_key_pair.mpc_server.key_name
  iam_instance_profile   = aws_iam_instance_profile.mpc_server.name
  vpc_security_group_ids = [data.aws_security_group.full_access.id]
  subnet_id              = data.aws_subnet.public.id

  root_block_device {
    volume_size           = 16
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
        # Install Nitro Enclaves CLI
        sudo dnf -y install aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel
        # Update user permissions
        sudo usermo'd -aG ne ec2-user && sudo usermod -aG docker ec2-user
        # Allocate cpu and memory for the enclave
        # TODO: Make this more user friendly
        sudo tee /etc/nitro_enclaves/allocator.yaml <<-EOT
        ---
        memory_mib: 3072
        cpu_count: 1
        EOT
        # Enable and start services
        sudo systemctl enable --now docker
        sudo systemctl enable --now nitro-enclaves-allocator.service
        sudo systemctl enable --now nitro-enclaves-vsock-proxy.service
        
        # Application dependencies
        sudo dnf -y install git-all
        # TODO: Use parent/requirements.txt
        sudo dnf -y install python3-pip
        sudo pip3 install boto3==1.33.13
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
  key_name   = "mpc-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcQK5Naws5UrdVATzc0XjtXyIMaGoVOOFMbMI+zEe3r"
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

resource "aws_iam_role_policy_attachment" "mpc_server_attachment" {
  role       = aws_iam_role.mpc_server.name
  policy_arn = aws_iam_policy.mpc_server.arn
}