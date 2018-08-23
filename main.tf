provider "fastly" {
  version = "~> 0.3"
}

module "voting-app" {
  source = "voting-app"
}

module "voting-app-qa" {
  source = "voting-app-qa"
}

module "misc" {
  source = "misc"
}
