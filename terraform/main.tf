# External ALB → Internet
resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  security_group_id = aws_security_group.external_alb_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_https" {
  type              = "ingress"
  security_group_id = aws_security_group.external_alb_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ALB → WEB
resource "aws_security_group_rule" "alb_to_web" {
  type                     = "ingress"
  security_group_id        = aws_security_group.web_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.external_alb_sg.id
}

# SSH to WEB
resource "aws_security_group_rule" "ssh_web" {
  type              = "ingress"
  security_group_id = aws_security_group.web_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.my_ip]
}

# WEB → INTERNAL ALB
resource "aws_security_group_rule" "web_to_internal_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.internal_alb_sg.id
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_sg.id
}

# INTERNAL ALB → APP
resource "aws_security_group_rule" "internal_alb_to_app" {
  type                     = "ingress"
  security_group_id        = aws_security_group.app_sg.id
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb_sg.id
}

# APP → DB
resource "aws_security_group_rule" "app_to_db" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sg.id
}


########################################
# WEB INSTANCE
########################################

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "web-tier"
  }
}

########################################
# APP INSTANCE
########################################

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = data.aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "app-tier"
  }
}
