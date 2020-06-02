# This is the Quasar VPC layout.

resource "aws_vpc" "quasar_vpc" {
  description = "Quasar VPC IP range."
  cidr_block  = "10.255.0.0/16"

  tags = {
    Name = "Quasar"
  }
}

resource "aws_subnet" "subnet-a" {
  description = "1st RDS subnet for multi-AZ DB setup."
  vpc_id      = aws_vpc.quasar_vpc.id
  cidr_block  = "10.255.100.0/24"

  tags = {
    Name = "Quasar RDS - 1A"
  }
}

resource "aws_subnet" "subnet-b" {
  description = "2nd RDS subnet for multi-AZ DB setup."
  vpc_id      = aws_vpc.quasar_vpc.id
  cidr_block  = "10.255.101.0/24"

  tags = {
    Name = "Quasar RDS - 1E"
  }
}

# Next 3 "bastion" blocks define rules for our bastion server
# as the only entry entry point for SSH'ing into our EC2 instances.
# Setup this way to reduce attach surface.
resource "aws_security_group" "bastion" {
  name        = "Quasar-Bastion"
  description = "22 from Everywhere"
  vpc_id      = aws_vpc.quasar_vpc.id

  tags = {
    Name = "Quasar-Bastion"
  }
}

resource "aws_security_group_rule" "bastion" {
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-egress" {
  security_group_id = aws_security_group.bastion.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

# Next 4 sections define security rules for our Jenkins instances. 
# The rules allow for SSH access from the "bastion" server defined above,
# and opens up port 8080 (default Jenkins port) to communicate with the "haproxy" 
# load-balancer section below that provides front-end routing and certificate
# management/decryption (now with Nginx instead of HA Proxy, similar to https://bit.ly/3gsjRo9).
resource "aws_security_group" "jenkins" {
  name        = "Quasar-Jenkins"
  description = "22 from Quasar-Bastion, 8080 from Quasar-HA-Proxy"
  vpc_id      = aws_vpc.quasar_vpc.id

  tags = {
    Name = "Quasar-Jenkins"
  }
}

resource "aws_security_group_rule" "jenkins-bastion" {
  security_group_id        = aws_security_group.jenkins.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "jenkins-haproxy" {
  security_group_id        = aws_security_group.jenkins.id
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.haproxy.id
}

resource "aws_security_group_rule" "jenkins-egress" {
  security_group_id = aws_security_group.jenkins.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "haproxy" {
  name        = "Quasar-HA-Proxy"
  description = "80/443 Everywhere, 22 from Quasar Bastion"
  vpc_id      = aws_vpc.quasar_vpc.id

  tags = {
    Name = "Quasar-HA-Proxy"
  }
}

# The next 4 sections define load-balancer securty rules.
# The "haproxy" moniker is misleading and we now use Nginx for
# load-balancing similar details in https://bit.ly/3gsjRo9.
# Accepts 80/443 from the world and SSH access from "bastion".
resource "aws_security_group_rule" "haproxy-http" {
  security_group_id = aws_security_group.haproxy.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "haproxy-https" {
  security_group_id = aws_security_group.haproxy.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "haproxy-bastion" {
  security_group_id        = aws_security_group.haproxy.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "haproxy-egress" {
  security_group_id = aws_security_group.haproxy.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security groups for our ETL compute nodes.
# SSH access allowed from "bastion" and "Jenkins" since data pipeline
# runs happen on compute nodes instead of on Jenkins server itself.
resource "aws_security_group" "etl" {
  name        = "Quasar-ETL"
  description = "22 from Quasar-Bastion and Quasar-Jenkins"
  vpc_id      = aws_vpc.quasar_vpc.id

  tags = {
    Name = "Quasar-ETL"
  }
}

resource "aws_security_group_rule" "etl-bastion" {
  security_group_id        = aws_security_group.etl.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "etl-jenkins" {
  security_group_id        = aws_security_group.etl.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins.id
}

resource "aws_security_group_rule" "etl-egress" {
  security_group_id = aws_security_group.etl.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security rules for our RDS instance.
# TODO: Lockdown PostgreSQL to whitelist appropriate IP's only, e.g. from Fivetran, Looker, etc.
resource "aws_security_group" "rds" {
  name        = "Quasar-PostgreSQL"
  description = "Quasar PostgreSQL Connectivity"
  vpc_id      = aws_vpc.quasar_vpc.id

  tags = {
    Name = "Quasar-RDS"
  }
}

resource "aws_security_group_rule" "rds" {
  security_group_id = aws_security_group.rds.id
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rds-etl" {
  security_group_id        = aws_security_group.rds.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.etl.id
}

resource "aws_security_group_rule" "rds-egress" {
  security_group_id = aws_security_group.rds.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols.
  cidr_blocks       = ["0.0.0.0/0"]
}

output "rds_security_group" {
  description = "The security group for RDS instances in this VPC."
  value       = aws_security_group.rds
}
