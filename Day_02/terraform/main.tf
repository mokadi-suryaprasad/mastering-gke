terraform {
  required_providers {
    google = { source = "hashicorp/google", version = ">= 5.0" }
    google-beta = { source = "hashicorp/google-beta", version = ">= 5.0" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  alias   = "beta"
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = var.cluster_name
  project  = var.project_id
  region   = var.region

  network    = var.vpc_name
  subnetwork = var.subnetwork

  initial_node_count = 1

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      cidr_blocks = [
        for net in var.master_authorized_networks : {
          display_name = net.display_name
          cidr_block   = net.cidr_block
        }
      ]
    }
  }

  workload_identity_config {
    workload_pool = var.workload_pool
  }

  datapath_provider = var.datapath_provider

  release_channel {
    channel = var.release_channel
  }

 ip_allocation_policy {
  use_ip_aliases           = true
  cluster_ipv4_cidr_block  = "10.10.0.0/19"  # CIDR for pod IPs
  services_ipv4_cidr_block = "10.10.32.0/20" # CIDR for service IPs
}


  addons_config {}
}

resource "google_container_node_pool" "default_pool" {
  provider = google-beta
  name     = "default-pool"
  cluster  = google_container_cluster.primary.name
  project  = var.project_id
  region   = var.region

  node_count = var.node_count_per_zone * length(var.zones)

  node_config {
    machine_type = var.machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    image_type   = var.image_type

    spot = true

    metadata = { disable-legacy-endpoints = "true" }

    shielded_instance_config { enable_secure_boot = false }
  }

  management {
  auto_repair  = true
  auto_upgrade = true
}

}

output "cluster_name" { value = google_container_cluster.primary.name }
output "cluster_endpoint" { value = google_container_cluster.primary.endpoint }
output "node_pool_name" { value = google_container_node_pool.default_pool.name }
