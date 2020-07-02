variable "name" {
  description = "The name for this destination."
}

variable "subnet" {
  description = "The subnet to use for this connection."
}

variable "warehouse" {
  description = "The PostgreSQL instance for this data warehouse."
}

variable "vpc_security_group_ids" {
  description = "The VPC security group IDs to use for this connection."
}

resource "aws_glue_connection" "connection" {
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${var.warehouse.endpoint}/${var.warehouse.name}"
    USERNAME            = var.warehouse.username
    PASSWORD            = var.warehouse.password
  }

  physical_connection_requirements {
    availability_zone      = var.subnet.availability_zone
    security_group_id_list = var.vpc_security_group_ids
    subnet_id              = var.subnet.id
  }

  name = var.name
}
