
############################################
# Provider
############################################
provider "google" {
  project = var.project_id
  region  = var.region
}

############################################
# Read Cloud SQL details from Part 1 (remote state)
############################################
data "terraform_remote_state" "db" {
  backend = "gcs"
  config = {
    bucket = "bindplane-tf-state-demo"
    prefix = "bindplane/part1-db"
  }
}

############################################
# BindPlane Control Plane VM
############################################
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
    access_config {} # ephemeral public IP
  }

  # Startup script: install Bindplane Control Plane and configure DB
  # IMPORTANT:
  # - Use <<-EOF (literal) – not HTML &lt;&lt;EOF.
  # - Use "${var.*}" for HCL interpolation – not $var.*.
  # - Quote all interpolations for safety.
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -euo pipefail

    apt-get update -y
    apt-get install -y jq curl

    echo "Installing BindPlane Control Plane..."
    curl -sSL https://observiq.com/install-bindplane.sh | bash

    echo "Configuring BindPlane with Cloud SQL..."
    bindplane setup \
      --db-host "${data.terraform_remote_state.db.outputs.db_ip}" \
      --db-port "${data.terraform_remote_state.db.outputs.db_port}" \
      --db-user "${data.terraform_remote_state.db.outputs.db_user}" \
      --db-admin "${var.db_admin}" \
      --db-password "${var.db_password}" \
      --db-name "${data.terraform_remote_state.db.outputs.db_name}" \
      --admin-password "${var.admin_password}"

    echo "Creating agent API key locally on Control Plane..."
    bindplane api-keys create demo-agent --json | jq -r '.key' > /opt/bindplane/agent-api.key
    chmod 600 /opt/bindplane/agent-api.key

    echo "BindPlane Control Plane setup completed"
  EOF

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  labels = {
    app  = "bindplane"
    role = "control-plane"
    env  = "demo"
  }
}

############################################
# Outputs
############################################
output "control_plane_ip" {
  description = "Public IP of BindPlane Control Plane"
  value       = google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip
}
``
