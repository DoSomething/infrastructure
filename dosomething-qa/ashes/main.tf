resource "aws_instance" "haproxy_qa" {
  ami           = "ami-d05e75b8"
  instance_type = "t2.micro"

  tags = {
    Name        = "Thor-HA-Proxy"
    Role        = "Thor-HA-Proxy"
    Environment = "Thor"
  }
}

output "backend_qa" {
  value = "${aws_instance.haproxy_qa.public_ip}"
}
