
############################################
# Provider
############################################
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

############################################
# BindPlane Control Plane VM
############################################
resource "google_compute_instance" "control_plane" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = 20
    }
  }

  network_interface {
    network       = "default"
    access_config {} # ephemeral public IP
  }

  metadata_startup_script = <<-SCRIPT
    #!/usr/bin/env bash
    set -euo pipefail

    apt-get update -y
    apt-get install -y jq curl

    echo "Installing BindPlane Control Plane..."
    curl -sSL https://observiq.com/install-bindplane.sh | bash

    echo "Configuring BindPlane with provided PostgreSQL..."
    bindplane setup \
      --db-host "${var.db_host}" \
      --db-port "${var.db_port}" \
      --db-user "${var.db_user}" \
      --db-admin "${var.db_admin}" \
      --db-password "${var.db_password}" \
      --db-name "${var.db_name}" \
      --admin-password "${var.admin_password}"

    echo "BindPlane Control Plane setup completed"
  SCRIPT

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
# Wait until Control Plane is reachable
############################################
# This resource polls the UI until it responds
resource "null_resource" "wait_until_up" {
  depends_on = [google_compute_instance.control_plane]

  provisioner "local-exec" {
    command = <<-CMD
      set -e
      CP_IP="${IP}"
      echo "Waiting for BindPlane UI on http://${CP_IP}:3001 ..."
      for i in $(seq 1 40); do
        if curl -sf "http://${CP_IP}:3001/health" >/dev/null || \
           curl -sf "http://${CP_IP}:3001/login"  >/dev/null || \
           curl -sf "http://${CP_IP}:3001"        >/dev/null; then
          echo "BindPlane Control Plane is ACTIVE"
          exit 0
        fi
        echo "Attempt $i/40: not active yet..."
        sleep 15
      done
      echo "Control Plane did not become ACTIVE within timeout"
      exit 1
    CMD

    environment = {
      IP = google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip
    }
  }
}


############################################
# Outputs
############################################
output "control_plane_ip" {
  description = "Public IP of BindPlane Control Plane"
  value       = google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip
}

output "control_plane_url" {
  description = "BindPlane UI URL"
  value       = "http://${google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip}:3001"
}
