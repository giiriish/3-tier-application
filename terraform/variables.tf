variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID (for Web Tier)"
  type        = string
}

variable "private_subnet_id" {
  description = "Private Subnet ID (for App Tier)"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair Name"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "my_ip" {
  description = "Your laptop public IP for SSH access"
  type        = string
}
