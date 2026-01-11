provider "google" {
  project = var.project_id
  region  = var.region
}

data "terraform_remote_state" "db" {
  backend = "gcs"
  config = {
    bucket = "bindplane-tf-state-demo"
    prefix = "bindplane/part1-db"
  }
}

resource "google_compute_instance" "control_plane" {
  name         = "bp-control-plane"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-12"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<EOF
#!/bin/bash
curl -sSL https://observiq.com/install-bindplane.sh | bash

bindplane setup \
  --db-host ${data.terraform_remote_state.db.outputs.db_ip} \
  --db-port 5432 \
  --db-user bindplane \
  --db-password ${var.db_password} \
  --admin-password ${var.admin_password}

bindplane api-keys create demo-agent --json > /tmp/api.json
EOF
}

output "control_plane_ip" {
  value = google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip
}
