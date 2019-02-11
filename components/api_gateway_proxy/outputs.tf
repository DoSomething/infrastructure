output "base_url" {
  description = "The URL that this API Gateway is accessible at."
  value       = "${module.api_gateway.base_url}"
}
