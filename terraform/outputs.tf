output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "app_instance_id" {
  value = aws_instance.app.id
}

