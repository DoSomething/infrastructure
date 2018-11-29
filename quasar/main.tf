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

resource "aws_security_group" "bastion" {
  name        = "Quasar-Bastion"
  description = "22 from Everywhere"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins" {
  name        = "Quasar-Jenkins"
  description = "22 from Quasar-Bastion, 8080 from Quasar-HA-Proxy"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }
}

# Adding to clear up cycle error dependency between 
# haproxy and jenkins security groups.
resource "aws_security_group_rule" "haproxy-jenkins" {
  security_group_id        = "${aws_security_group.jenkins.id}"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.haproxy.id}"
}

resource "aws_security_group" "haproxy" {
  name        = "Quasar-HA-Proxy"
  description = "80/443 Everywhere, 22 from Quasar Bastion"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}, ${aws_security_group.jenkins.id}"]
  }
}

resource "aws_security_group" "etl" {
  name        = "Quasar-ETL"
  description = "22 from Quasar-Bastion and Quasar-Jenkins"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}, ${aws_security_group.jenkins.id}"]
  }
}

resource "aws_security_group" "rds" {
  name        = "Quasar-PostgreSQL"
  description = "Quasar PostgreSQL Connectivity"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${aws_security_group.etl.id}"]
  }
}
