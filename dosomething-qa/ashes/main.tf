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

resource "aws_instance" "haproxy_qa" {
  ami = "ami-d05e75b8"
  instance_type = "t2.micro"

  tags = {
    Name = "Thor-HA-Proxy"
    Role = "Thor-HA-Proxy"
    Environment = "Thor"
  }
}

output "backend_staging" {
  value = "${aws_instance.staging.public_ip}"
}

output "backend_haproxy_qa" {
  value = "${aws_instance.haproxy_qa.public_ip}"
}
