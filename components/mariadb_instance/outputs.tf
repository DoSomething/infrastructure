output "address" {
  value = aws_db_instance.database.address
}

output "port" {
  value = aws_db_instance.database.port
}

output "name" {
  value = aws_db_instance.database.name
}

output "username" {
  value = join("", mysql_user.app.*.user)
}

output "password" {
  value = random_string.app_password.result
}

output "config_vars" {
  value = {
    DB_HOST     = aws_db_instance.database.address
    DB_PORT     = aws_db_instance.database.port
    DB_DATABASE = aws_db_instance.database.name
    DB_USERNAME = join("", mysql_user.app.*.user)
    DB_PASSWORD = random_string.app_password.result
  }
}
