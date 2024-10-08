terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>5.66"
        }
    }
}

provider "aws" {
    region = "eu-central-1"
}

resource "aws_s3_bucket" "result_bucket" {
    # bucket = "ledidi-phd-terraform-results"
    force_destroy = true
}

resource "aws_vpc" "main" {
    cidr_block = "172.16.0.0/16"
}

resource "aws_subnet" "main" {
    vpc_id = aws_vpc.main.id
    cidr_block = "172.16.0.0/24"
    availability_zone = "eu-central-1a"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
}

resource "aws_route_table_association" "main" {
    subnet_id = aws_subnet.main.id
    route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
    name = "main"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "instance_key" {
    key_name = "mpc-key"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcQK5Naws5UrdVATzc0XjtXyIMaGoVOOFMbMI+zEe3r"
}

resource "aws_iam_policy" "enclave_actions" {
    name = "enclave_actions"

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

resource "aws_iam_role" "mpc_instance_role" {
    name = "mpc_instance_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "sts:AssumeRole"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

output "mpc_instance_role_arn" {
    value = aws_iam_role.mpc_instance_role.arn
    sensitive = true
}

resource "aws_iam_role_policy_attachment" "enclave_actions_attachment" {
    role = aws_iam_role.mpc_instance_role.name
    policy_arn = aws_iam_policy.enclave_actions.arn
}

resource "aws_iam_instance_profile" "mpc_instance_profile" {
    name = "mpc_instance_profile"
    role = aws_iam_role.mpc_instance_role.name
}

resource "aws_instance" "mpc_instance" {
    ami = "ami-077e7b988e15f909f"  # Amazon Linux 2023 AMI
    instance_type = "c7g.large"  # Graviton 3 (ARM), 2 vCPUs, 4 GiB RAM
    availability_zone = "eu-central-1a"
    key_name = aws_key_pair.instance_key.key_name
    enclave_options {
        enabled = true
    }
    iam_instance_profile = aws_iam_instance_profile.mpc_instance_profile.name
    vpc_security_group_ids = [aws_security_group.main.id]
    subnet_id = aws_subnet.main.id
    security_groups = [aws_security_group.main.id]
    root_block_device {
        volume_size = 16
        volume_type = "gp3"
        encrypted = true
        delete_on_termination = true
    }
    metadata_options {
        http_tokens = "required"
    }
    user_data = <<-EOF
        #!/bin/bash
        # Install Nitro Enclaves CLI
        sudo dnf -y install aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel
        # Update user permissions
        sudo usermod -aG ne ec2-user && sudo usermod -aG docker ec2-user
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
}