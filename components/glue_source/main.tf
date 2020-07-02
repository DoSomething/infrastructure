variable "name" {
  description = "The name for this AWS Glue source."
}

variable "bucket" {
  description = "The S3 bucket to use as an AWS Glue source."
}

resource "aws_iam_role" "glue_role" {
  name = "AWSGlueServiceRole-dosomething-bertly-qa"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "glue.amazonaws.com"
          }
        },
      ]
    }
  )
}

resource "aws_iam_policy" "s3_policy" {
  name   = "${var.name}-s3-glue"
  policy = templatefile("${path.module}/iam-role.json.tpl", { bucket_arn : var.bucket.arn })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = "${aws_iam_role.glue_role.name}"
  policy_arn = "${aws_iam_policy.s3_policy.arn}"
}

resource "aws_glue_catalog_database" "catalog" {
  name = var.name
}

resource "aws_glue_crawler" "s3_crawler" {
  database_name = "${aws_glue_catalog_database.catalog.name}"
  name          = var.name
  role          = aws_iam_role.glue_role.arn
  schedule      = "cron(22 00 * * ? *)" # Daily at 10:00pm.

  s3_target {
    path = "s3://${var.bucket.bucket}"
  }
}

resource "aws_glue_trigger" "example" {
  name     = "${var.name}-nightly"
  schedule = "cron(00 00 * * ? *)" # Daily at 00:00am.
  type     = "SCHEDULED"

  actions {
    job_name = "${aws_glue_job.ingestion_job.name}"
  }
}

resource "aws_glue_job" "ingestion_job" {
  name     = var.name
  role_arn = "${aws_iam_role.glue_role.arn}"

  command {
    # This script, stored in our Glue bucket, defines the job's steps:
    script_location = "s3://dosomething-glue/${var.name}.py"
  }

  default_arguments = {
    "--job-language" = "scala"
  }
}
