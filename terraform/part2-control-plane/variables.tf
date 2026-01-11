
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "db_password" {
  description = "Cloud SQL PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "BindPlane admin password"
  type        = string
  sensitive   = true
}

variable "db_admin" {
  description = "Database admin user (e.g., postgres)"
  type        = string
  sensitive   = true
}
