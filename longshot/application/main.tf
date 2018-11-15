variable "pipeline" {}
variable "pipeline_stage" {}
variable "name" {}
variable "host" {}

variable "web_size" {
  default = "Standard-1X"
}

variable "web_scale" {
  default = "1"
}

variable "queue_size" {
  default = "Standard-1X"
}

variable "queue_scale" {
  default = "1"
}

variable "redis_type" {
  default = "hobby-dev"
}

variable "database_name" {}

variable "database_type" {
  default = "db.t2.medium"
}

variable "database_scale" {
  default = 100
}

variable "email_name" {}
variable "email_address" {}

variable "papertrail_destination" {}

resource "heroku_app" "app" {
  name   = "dosomething-${var.name}"
  region = "us"

  organization {
    name = "dosomething"
  }

  config_vars {
    # App settings:
    APP_ENV   = "production"
    APP_DEBUG = "false"
    APP_LOG   = "errorlog"
    APP_URL   = "https://${var.host}"

    # Drivers:
    QUEUE_DRIVER   = "sqs"
    CACHE_DRIVER   = "redis"
    STORAGE_DRIVER = "s3"

    # Email:
    EMAIL_ADDRESS = "${var.email_address}"
    EMAIL_ADDRESS = "${var.email_name}"
    MAIL_HOST     = "smtp.mandrillapp.com"

    # Database:
    DB_HOST     = "${aws_db_instance.database.address}"
    DB_PORT     = "${aws_db_instance.database.port}"
    DB_DATABASE = "${var.database_name}"
    DB_USERNAME = "${data.aws_ssm_parameter.database_username.value}"
    DB_PASSWORD = "${data.aws_ssm_parameter.database_password.value}"

    # S3 Bucket & SQS Queue:
    AWS_ACCESS_KEY    = "${aws_iam_access_key.aws_key.id}"
    AWS_SECRET_KEY    = "${aws_iam_access_key.aws_key.secret}"
    SQS_DEFAULT_QUEUE = "${aws_sqs_queue.queue.id}"
    S3_REGION         = "${aws_s3_bucket.storage.region}"
    S3_BUCKET         = "${aws_s3_bucket.storage.id}"

    # Additional secrets, set manually:
    # APP_KEY = ...
    # MANDRILL_API_KEY = ...
  }

  buildpacks = [
    "heroku/nodejs",
    "heroku/php",
  ]

  acm = true
}

resource "heroku_formation" "web" {
  app      = "${heroku_app.app.name}"
  type     = "web"
  size     = "${var.web_size}"
  quantity = "${var.web_scale}"
}

resource "heroku_formation" "queue" {
  app      = "${heroku_app.app.name}"
  type     = "queue"
  size     = "${var.queue_size}"
  quantity = "${var.queue_scale}"
}

resource "heroku_domain" "domain" {
  app      = "${heroku_app.app.name}"
  hostname = "${var.host}"
}

resource "heroku_drain" "papertrail" {
  app = "${heroku_app.app.name}"
  url = "syslog+tls://${var.papertrail_destination}"
}

resource "heroku_pipeline_coupling" "app" {
  app      = "${heroku_app.app.name}"
  pipeline = "${var.pipeline}"
  stage    = "${var.pipeline_stage}"
}

resource "heroku_addon" "redis" {
  app  = "${heroku_app.app.name}"
  plan = "heroku-redis:${var.redis_type}"
}

resource "aws_db_instance" "database" {
  engine              = "mariadb"
  engine_version      = "10.0"
  instance_class      = "${var.database_type}"
  allocated_storage   = "${var.database_scale}"
  username            = "${data.aws_ssm_parameter.database_username.value}"
  password            = "${data.aws_ssm_parameter.database_password.value}"
  publicly_accessible = true
  skip_final_snapshot = true

  tags = {
    Application = "${var.name}"
  }
}

data "aws_ssm_parameter" "database_username" {
  name = "/${var.name}/rds/username"
}

data "aws_ssm_parameter" "database_password" {
  name = "/${var.name}/rds/password"
}

resource "aws_sqs_queue" "queue" {
  name                      = "${var.name}"
  message_retention_seconds = "${60 * 60 * 24 * 14}"
}

resource "aws_s3_bucket" "storage" {
  bucket = "dosomething-${var.name}"
  acl    = "public-read"

  tags {
    Application = "${var.name}"
  }
}

resource "aws_iam_user" "aws_user" {
  name = "${var.name}"
}

resource "aws_iam_access_key" "aws_key" {
  user = "${aws_iam_user.aws_user.name}"
}

data "template_file" "sqs_policy" {
  template = "${file("${path.root}/shared/sqs-policy.json.tpl")}"

  vars {
    queue_arn = "${aws_sqs_queue.queue.arn}"
  }
}

resource "aws_iam_user_policy" "sqs_policy" {
  name   = "${var.name}-sqs"
  user   = "${aws_iam_user.aws_user.name}"
  policy = "${data.template_file.sqs_policy.rendered}"
}

data "template_file" "s3_policy" {
  template = "${file("${path.root}/shared/s3-policy.json.tpl")}"

  vars {
    bucket_arn = "${aws_s3_bucket.storage.arn}"
  }
}

resource "aws_iam_user_policy" "s3_policy" {
  name   = "${var.name}-s3"
  user   = "${aws_iam_user.aws_user.name}"
  policy = "${data.template_file.s3_policy.rendered}"
}

output "name" {
  value = "${heroku_app.app.name}"
}

output "domain" {
  value = "${heroku_domain.domain.hostname}"
}

output "backend" {
  value = "${heroku_app.app.heroku_hostname}"
}
