###############################################################################
# Google Compute Instance Configuration Module
# -----------------------------------------------------------------------------
# variables.tf
###############################################################################

# Required variables

variable "gcp_machine_type" {
  type        = string
  description = "The GCP machine type (Example: e2-standard-2)"
}

variable "gcp_project" {
  type        = string
  description = "The GCP project ID (may be a alphanumeric slug) that the resources are deployed in. (Example: my-project-name)"
}

variable "gcp_region" {
  type        = string
  description = "The GCP region that the resources will be deployed in. (Ex. us-east1)"
}

variable "gcp_region_zone" {
  type        = string
  description = "The GCP region availability zone that the resources will be deployed in. This must match the region. (Example: us-east1-c)"
}

variable "gcp_subnetwork" {
  description = "The object or self link for the subnet created in the parent module (Example: google_compute_subnetwork.app_subnetwork.self_link)"
}
variable "gcp_network_name" {
  description = "VPC Name"
  nullable    = false
}

variable "instance_description" {
  type        = string
  description = "Instance description. (Example: App server for a cool purpose)"
}

variable "instance_name" {
  type        = string
  description = "The short name (hostname) of the VM instance that will become an A record in the DNS zone that you specify. (Example: app1)"
}

# Optional variables with default values

variable "disk_boot_size" {
  type        = string
  description = "The size in GB of the OS boot volume. (Default: 10)"
  default     = "10"
}

variable "disk_storage_enabled" {
  type        = bool
  description = "True to attach storage disk. False to only have boot disk. (Default: false)"
  default     = "false"
}

variable "disk_storage_mount_path" {
  type        = string
  description = "The Linux directory/path that the storage disk should be mounted to. This will depend on where your application and storage data resides by default. For GitLab Omnibus instances, this will reside in /var/opt, whereas Nginx sites may reside in /srv/www, and other applications may reside in /opt. The default value is chosen based on GitLab deployments being the primary use case of this module. (Default: /var/opt)"
  default     = "/var/opt"
}

variable "disk_storage_size" {
  type        = string
  description = "The size in GB of the storage volume. (Default: 100)"
  default     = "100"
}

variable "dns_create_record" {
  type        = bool
  description = "True to create a DNS record. False to only return an IP address. (Default: true)"
  default     = "true"
}

variable "dns_ttl" {
  type        = string
  description = "TTL of DNS Record for instance. (Default: 300)"
  default     = "300"
}

variable "gcp_deletion_protection" {
  type        = bool
  description = "Enable this to prevent Terraform from accidentally destroying the instance with terraform destroy command. (Default: false)"
  default     = "false"
}

variable "gcp_dns_zone_name" {
  type        = string
  description = "The GCP Cloud DNS zone name to create instance DNS A record in. This is not the FQDN. (Example: gitlab-sandbox-root-zone)"
  default     = null
}

variable "gcp_image" {
  type        = string
  description = "The GCP image name. (Default: ubuntu-1804-lts)"
  default     = "ubuntu-1804-lts"
}

variable "gcp_network_tags" {
  type        = list(any)
  description = "A comma separated array of tags that should be applied to the GCP compute instance that are used for network and firewall rules."
  default     = []
}

variable "gcp_preemptible" {
  type        = bool
  description = "Enable this to allow this instance to terminate for preemtible reasons. This can cause configuration and data loss. (Default: false)"
  default     = "false"
}

variable "labels" {
  type        = map(any)
  description = "A single-level map/object with key value pairs of metadata labels to apply to the GCP resources. All keys should use underscores and values should use hyphens. All values must be wrapped in quotes."
  default     = {}
}

variable "allocate_external_ip" {
  type        = bool
  description = "True to allocate external IP, Default: false"
  default     = false
}

variable "startup_script" {
  description = "User startup script to run when instances spin up"
  type        = string
  default     = ""
}

variable "desired_status" {
  description = "Expected instance status when created"
  type        = string
  default     = "RUNNING"
}