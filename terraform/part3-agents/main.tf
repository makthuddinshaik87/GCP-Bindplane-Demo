############################################
# Provider
############################################
provider "google" {
  project = var.project_id
  region  = var.region
}

############################################
# Read Control Plane details from Part 2
############################################
data "terraform_remote_state" "control_plane" {
  backend = "gcs"
  config = {
    bucket = "bindplane-tf-state-demo"
    prefix = "bindplane/part2-control-plane"
  }
}

############################################
# BindPlane Agent VM
############################################
resource "google_compute_instance" "agent" {
  name         = "bp-agent"
  machine_type = "e2-micro"          # demo / free-tier friendly
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-12"
      size  = 10
    }
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -e

echo "Installing BindPlane Agent..."
curl -sSL https://observiq.com/install-agent.sh | bash

echo "Fetching API key from Control Plane securely..."

API_KEY=$(gcloud compute ssh bp-control-plane \
  --zone us-central1-a \
  --command "sudo cat /opt/bindplane/agent-api.key")

echo "Registering agent with BindPlane Control Plane..."

observiq-agent register \
  --endpoint http://${data.terraform_remote_state.control_plane.outputs.control_plane_ip}:3001 \
  --api-key "$API_KEY"

echo "BindPlane Agent registration completed"
EOF
}
