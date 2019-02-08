output "base_url" {
  description = "The URL that this API Gateway is accessible at."
  value       = "${var.domain == "" ? aws_api_gateway_deployment.deployment.invoke_url : "https://${var.domain}"}"
}
