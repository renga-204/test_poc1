terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
 
}



# Create a VPC
resource "aws_vpc" "poc-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.poc-vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.poc-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_security_group" "poc_sg" {
  name        = "poc_sg"
  vpc_id      = aws_vpc.poc-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "poc_sg"
  }
}

resource "aws_ebs_volume" "poc_volume_1" {
  availability_zone = "ap-south-1a"
  size              = 40  
}

resource "aws_ebs_volume" "poc_volume_2" {
  availability_zone = "ap-south-1b"
  size              = 40  
}

resource "aws_instance" "poc-instance-1" {
   ami = var.ami
   instance_type = var.instance_type
   #key_name = "poc-key"
   subnet_id = aws_subnet.public_subnet_1.id
   #availability_zone = "ap-south-1c"
   
   root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sda1"
   # volume_id             = aws_ebs_volume.poc_volume_1.id
    delete_on_termination = true
  }
   
   tags = {
      Name = "poc-machine-1"
           }
}

resource "aws_instance" "poc-instance-2" {
   ami = var.ami
   instance_type = var.instance_type
   #key_name = "poc-key"
   subnet_id = aws_subnet.public_subnet_2.id
   #availability_zone = "ap-south-1c"

   root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sda1"
    #volume_id             = aws_ebs_volume.poc_volume_2.id
    delete_on_termination = true
  }
   
   tags = {
      Name = "poc-machine-2"
           }
}

resource "aws_s3_bucket" "pocreng_bkt_1507" {
  bucket = "reng-tf-poc-bucket"

  tags = {
    Name        = "My poc bucket1"
    }
}

# Allow EC2 instances to access the S3 bucket
resource "aws_security_group_rule" "allow_s3_access" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.poc_sg.id
  source_security_group_id = aws_security_group.poc_sg.id
}