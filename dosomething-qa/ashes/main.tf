resource "aws_instance" "staging" {
  ami = "ami-cde952a6"
  instance_type = "m4.large"

  disable_api_termination = true
  ebs_optimized = true

  tags = {
    Application = "Phoenix-Ashes"
    Name = "Staging"
  }
}

output "backend_staging" {
  value = "${aws_instance.staging.public_ip}"
}
