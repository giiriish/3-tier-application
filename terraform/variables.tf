variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private Subnet ID"
  type        = string
}

variable "key_name" {
  description = "Key pair"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "my_ip" {
  description = "Your IP"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "10.0.0.0/22"
}
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "external_alb_sg" {
  name   = "external-alb-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group" "internal_alb_sg" {
  name   = "internal-alb-sg"
  vpc_id = var.vpc_id
}
