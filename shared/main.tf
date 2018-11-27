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

resource "aws_vpc" "quasar" {
  cidr_block = "10.255.0.0/16"

  tags {
    Name = "Quasar"
  }
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

output "quasar_vpc" {
  value = "${aws_vpc.quasar.id}"
}
