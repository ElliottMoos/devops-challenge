output "web_service_url" {
  value = "http://${aws_lb.web.dns_name}"
}
