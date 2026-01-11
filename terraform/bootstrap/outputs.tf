output "service_account_email" {
  value = google_service_account.github.email
}

output "service_account_key" {
  value     = base64decode(google_service_account_key.github_key.private_key)
  sensitive = true
}

output "tf_state_bucket" {
  value = google_storage_bucket.tf_state.name
}
