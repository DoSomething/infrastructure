# Required variables:
variable "name" {
  description = "The DynamoDB table name."
}

variable "application" {
  description = "The application this cache is provisioned for (e.g. 'dosomething-graphql')."
}

variable "environment" {
  description = "The environment for this database: development, qa, or production."
}

variable "stack" {
  description = "The 'stack' for this database: web, sms, backend, data."
}

variable "roles" {
  description = "The IAM roles which should have access to this resource."
  type        = list(string)
}

resource "aws_dynamodb_table" "table" {
  name         = var.name
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "segment"
  range_key = "id"

  attribute {
    name = "segment"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Application = var.application
    Environment = var.environment
    Stack       = var.stack
  }
}

data "template_file" "dynamodb_policy" {
  template = file("${path.module}/dynamodb-policy.json.tpl")

  vars = {
    dynamodb_table_arn = aws_dynamodb_table.table.arn
  }
}

resource "aws_iam_policy" "dynamodb_policy" {
  name = "${var.name}-dynamodb"
  path = "/"

  policy = data.template_file.dynamodb_policy.rendered
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  count      = length(var.roles)
  role       = var.roles[count.index]
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

output "name" {
  value = var.name
}

