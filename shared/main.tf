resource "heroku_pipeline" "graphql" {
  name = "graphql"
}

output "graphql_pipeline" {
  value = "${heroku_pipeline.graphql.id}"
}
