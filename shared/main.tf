resource "heroku_pipeline" "graphql" {
  name = "graphql"
}

resource "heroku_pipeline" "northstar" {
  name = "northstar"
}

resource "heroku_pipeline" "rogue" {
  name = "rogue"
}

resource "heroku_pipeline" "phoenix" {
  name = "phoenix"
}

output "graphql_pipeline" {
  value = "${heroku_pipeline.graphql.id}"
}

output "northstar_pipeline" {
  value = "${heroku_pipeline.northstar.id}"
}

output "rogue_pipeline" {
  value = "${heroku_pipeline.rogue.id}"
}

output "phoenix_pipeline" {
  value = "${heroku_pipeline.phoenix.id}"
}