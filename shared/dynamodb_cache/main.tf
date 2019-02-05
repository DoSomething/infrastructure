# Required variables:
variable "name" {
  description = "The application name."
}

variable "role" {
  description = "The IAM role which should have access to this resource."
}

resource "aws_dynamodb_table" "cache" {
  name         = "${var.name}"
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
}

data "template_file" "dynamodb_policy" {
  template = "${file("${path.module}/dynamodb-policy.json.tpl")}"

  vars {
    dynamodb_table_arn = "${aws_dynamodb_table.cache.arn}"
  }
}

resource "aws_iam_policy" "dynamodb_policy" {
  name = "${var.name}-dynamodb"
  path = "/"

  policy = "${data.template_file.dynamodb_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  role       = "${var.role}"
  policy_arn = "${aws_iam_policy.dynamodb_policy.arn}"
}

output "name" {
  value = "${var.name}"
}
