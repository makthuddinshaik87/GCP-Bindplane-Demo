variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "tf_state_bucket" {
  description = "GCS bucket for Terraform state"
  type        = string
}
