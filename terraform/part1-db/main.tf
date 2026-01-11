provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "sqladmin" {
  service = "sqladmin.googleapis.com"
}

resource "google_sql_database_instance" "postgres" {
  name             = "bp-postgres"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = true
    }
  }

  depends_on = [google_project_service.sqladmin]
}

resource "google_sql_database" "bindplane" {
  name     = "bindplane"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "bindplane" {
  name     = "bindplane"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
