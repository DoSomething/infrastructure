resource "aws_vpc" "vpc" {
  cidr_block = "10.255.0.0/16"

  tags {
    Name = "Quasar"
  }
}

resource "aws_subnet" "subnet-a" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.255.100.0/24"

  tags {
    Name = "Quasar RDS - 1A"
  }
}

resource "aws_subnet" "subnet-b" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.255.101.0/24"

  tags {
    Name = "Quasar RDS - 1E"
  }
}
