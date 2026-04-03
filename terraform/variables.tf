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
  default     = "192.168.0.0/25"
}

variable "web_sg" {
  description = "web sg"
  type        = string
}

variable "app_sg" {
  description = "app sg"
  type        = string
}
