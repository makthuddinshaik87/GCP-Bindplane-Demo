resource "google_compute_instance" "bindplane_agent_vm" {
  name         = "bindplane-agent-vm6"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    apt update -y
    apt install -y curl ca-certificates

    sudo sh -c "$(curl -fsSlL 'https://bdot.bindplane.com/v1.89.0/install_unix.sh')" install_unix.sh \
      -e 'ws://bindplane-control-2:3001/v1/opamp' \
      -s 'YOUR_BINDPLANE_TOKEN' \
      -v '1.89.0'
  EOF

  depends_on = [google_project_service.compute]
}
