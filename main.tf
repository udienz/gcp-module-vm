###############################################################################
# Google Compute Instance Configuration Module
# -----------------------------------------------------------------------------
# main.tf
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.0"
}

# Get the existing DNS zone
data "google_dns_managed_zone" "dns_zone" {
  count = var.dns_create_record ? 1 : 0
  name  = var.gcp_dns_zone_name
}

# Create additional disk volume for instance
resource "google_compute_disk" "storage_disk" {
  count = var.disk_storage_enabled ? 1 : 0

  labels = var.labels
  name   = "${var.instance_name}-storage-disk"
  size   = var.disk_storage_size
  type   = var.disk_storage_type
  zone   = var.gcp_region_zone
}

# Attach additional disk to instance, so that we can move this
# volume to another instance if needed later.
# This will appear at /dev/disk/by-id/google-{NAME}
resource "google_compute_attached_disk" "attach_storage_disk" {
  count = var.disk_storage_enabled ? 1 : 0

  device_name = "storage-disk"
  disk        = google_compute_disk.storage_disk[0].self_link
  instance    = google_compute_instance.instance.self_link
}

# Create an external IP for the instance
resource "google_compute_address" "external_ip" {
  count = var.allocate_external_ip ? 1 : 0

  address_type = "EXTERNAL"
  description  = "External IP for ${var.instance_description}"
  /*
  # Although labels are supported according to the documentation, they were not
  # working during tests, so they have been commented out for now.
  labels = var.labels
  */
  name   = "${var.instance_name}-network-ip"
  region = var.gcp_region
}

# Create a Google Compute Engine VM instance
resource "google_compute_instance" "instance" {
  description         = var.instance_description
  deletion_protection = var.gcp_deletion_protection
  hostname            = var.dns_create_record ? trimsuffix("${var.instance_name}.${data.google_dns_managed_zone.dns_zone[0].dns_name}", ".") : null
  name                = var.instance_name
  machine_type        = var.gcp_machine_type
  zone                = var.gcp_region_zone
  desired_status      = var.desired_status

  # Base disk for the OS
  boot_disk {
    initialize_params {
      type  = var.disk_boot_type
      image = var.gcp_image
      size  = var.disk_boot_size
    }
    auto_delete = "true"
  }

  labels = var.labels

  # This ignored_changes is required since we use a separate resource for attaching the disk
  lifecycle {
    ignore_changes = [attached_disk]
  }

  # Attach the primary network interface to the VM
  network_interface {
    subnetwork = var.gcp_subnetwork
    network    = var.gcp_network_name
  }

  # This sets a custom SSH key on the instance and prevents the OS Login and GCP
  # project-level SSH keys from working. This is commented out since we use
  # project-level SSH keys.
  # https://console.cloud.google.com/compute/metadata?project=my-project-name&authuser=1&supportedpurview=project
  #
  # metadata {
  #   sshKeys = "ubuntu:${file("keys/${var.ssh_public_key}.pub")}"
  # }

  # Execute the script to format & mount /var/opt
  metadata = {
    # startup-script = var.disk_storage_enabled ? file("${path.module}/init/mnt_dir.sh") : null
    startup-script = var.startup_script
    MOUNT_DIR      = var.disk_storage_mount_path
    REMOTE_FS      = "/dev/disk/by-id/google-storage-disk"
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = var.gcp_preemptible ? "false" : "true"
    preemptible         = var.gcp_preemptible
  }

  # Tags in GCP are only used for network and firewall rules. Any metadata is
  # defined as a label (see above).
  tags = var.gcp_network_tags

  service_account = var.service_account

}

# Create a DNS record
resource "google_dns_record_set" "dns_record" {
  count = var.dns_create_record ? 1 : 0

  managed_zone = data.google_dns_managed_zone.dns_zone[0].name
  name         = "${var.instance_name}.${data.google_dns_managed_zone.dns_zone[0].dns_name}"
  rrdatas      = [google_compute_instance.instance.network_interface[0].network_ip]
  ttl          = var.dns_ttl
  type         = "A"
}

