# EC2 instance configuration
resource "aws_instance" "tf_server" {
  ami                         = "ami-0e2c8caa4b6378d8c" # change according to region
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id] # associate security group
  associate_public_ip_address = true
  key_name                    = "Jenkins_shared_library" # private aws key name
  user_data                   = <<-EOF
                                #!/bin/bash

                                # Git clone 
                                git clone https://github.com/SamipDave/Nodejs_mysql_app_Terraform_project.git
                                cd /home/ubuntu/Nodejs_mysql_app_Terraform_project

                                # install nodejs
                                sudo apt update -y
                                sudo apt install -y nodejs npm

                                # edit env vars
                                echo "DB_HOST=${local.rds_endpoint}" | sudo tee .env
                                echo "DB_USER=${aws_db_instance.tf_rds_instance.username}" | sudo tee -a .env
                                sudo echo "DB_PASS=${aws_db_instance.tf_rds_instance.password}" | sudo tee -a .env
                                echo "DB_NAME=${aws_db_instance.tf_rds_instance.db_name}" | sudo tee -a .env
                                echo "TABLE_NAME=users" | sudo tee -a .env
                                echo "PORT=3000" | sudo tee -a .env

                                # start server
                                npm install
                                EOF
  depends_on                  = [aws_s3_bucket.tf_s3_bucket] # attach s3 bucket

  tags = {
    Name = "nodejs-server"
  }
}

# Security group for EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = "vpc-0be511e226990406b" # default VPC

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allow from all IPs
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP"
    from_port   = 3000 # for nodejs app
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for EC2 instance (using terraform module)
# module "tf_ec2_module" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "5.2.0"
#   vpc_id  = "" # default VPC
#   name    = "ec2-security-group"

#   ingress_cidr_blocks = [
#     {
#       from_port   = 3000
#       to_port     = 3000
#       protocol    = "tcp"
#       description = "for nodejs app"
#       cidr_blocks = "0.0.0.0/0"
#     },
#     {
#       rule        = "https-443-tcp"
#       cidr_blocks = "0.0.0.0/0"
#     },
#     {
#       rule        = "ssh-tcp"
#       cidr_blocks = "0.0.0.0/0"
#     },

#   ]
#   egress_rules = ["all-all"]
# }


# output
output "ec2_public_ip" {
  value = aws_instance.tf_server.public_ip
}
