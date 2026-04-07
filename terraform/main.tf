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

  # ✅ Attach existing IAM Role (Instance Profile)
  iam_instance_profile = "3-tier-role"

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

  # ✅ Attach existing IAM Role (Instance Profile)
  iam_instance_profile = "3-tier-role"

  tags = {
    Name = "app-tier"
  }
}
