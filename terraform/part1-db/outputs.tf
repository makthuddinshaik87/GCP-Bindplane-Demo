output "db_host" {
  value = google_sql_database_instance.postgres.public_ip_address
}

output "db_port" {
  value = 5432
}

output "db_name" {
  value = google_sql_database.bindplane1.name
}

output "db_user" {
  value = google_sql_user.bindplane1.name
}
