variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "DB_PASSWORD" {
  description = "Cloud SQL PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "BindPlane admin password"
  type        = string
  sensitive   = true
}
