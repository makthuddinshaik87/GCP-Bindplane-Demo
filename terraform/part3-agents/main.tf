provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "agent" {
  name         = "bp-agent"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-12"
      size  = 10
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<SCRIPT
#!/bin/bash
set -e
curl -sSL https://observiq.com/install-agent.sh | bash
SCRIPT
}
