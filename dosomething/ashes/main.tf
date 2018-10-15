resource "aws_instance" "haproxy" {
  ami           = "ami-25d0ba40"
  instance_type = "t2.large"

  tags = {
    Name        = "HAProxy-Fastly-1B"
    Role        = "HAProxy-Fastly"
    Environment = "Production"
  }
}

output "backend" {
  value = "${aws_instance.haproxy.public_ip}"
}
