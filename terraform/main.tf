########################################
# WEB INSTANCE
########################################

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name

  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.web_sg]

  associate_public_ip_address = true

  tags = {
    Name = "web-tier"
  }
}

########################################
# APP INSTANCE
########################################

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name

  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.app_sg]

  associate_public_ip_address = false

  tags = {
    Name = "app-tier"
  }
}

terraform {
  backend "s3" {
    bucket         = "guru-3-tier"
    key            = "terraform/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
