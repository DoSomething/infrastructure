data "aws_ssm_parameter" "ghost_inspector_webhook" {
  count = var.environment == "qa" ? 1 : 0
  name  = "/ghost-inspector/webhooks/qa"
}

resource "heroku_addon" "webhook" {
  count = var.environment == "qa" ? 1 : 0
  app   = var.name
  plan  = "deployhooks:http"

  config = {
    url = data.aws_ssm_parameter.ghost_inspector_webhook[0].value
  }
}
