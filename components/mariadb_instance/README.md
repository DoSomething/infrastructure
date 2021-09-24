# MariaDB Database

This module creates a [MariaDB](https://mariadb.org) database on [Amazon RDS](https://aws.amazon.com/rds/).

For all options, see the [variables](https://github.com/DoSomething/infrastructure/blob/main/components/mariadb_instance/variables.tf) this module accepts & [outputs](https://github.com/DoSomething/infrastructure/blob/main/components/mariadb_instance/outputs.tf) it generates.

### Usage

To deploy a new database with default settings:

```hcl
module "database" {
  source = "../../components/mariadb_instance"

  name        = var.name
  environment = var.environment
  stack       = "backend"
}
```

You can provide standard `DB_*` environment variables to your application via `module.database.config_vars`.