# Use google-beta for cluster resource if you need datapath/spot features
provider "google-beta" {
  alias   = "beta"
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_container_cluster" "primary" {
  provider = google-beta   # using beta provider to enable dataplane & spot attributes if needed
  name     = var.cluster_name
  project  = var.project_id
  region   = var.region

  network    = var.network
  subnetwork = var.subnetwork

  initial_node_count = 1   # required but we will define separate node pools

  # Private cluster config (nodes have private IPs)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # leave control plane endpoint public by default per your note
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master authorized networks (control plane CIDR allowlist)
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      cidr_blocks = [
        for item in var.master_authorized_networks : {
          display_name = item.display_name
          cidr_block   = item.cidr_block
        }
      ]
    }
  }

  workload_identity_config {
    workload_pool = var.workload_pool
  }

  # Dataplane v2 / advanced datapath
  datapath_provider = var.datapath_provider  # "ADVANCED_DATAPATH" to enable Dataplane V2

  # Add some recommended security flags
  release_channel {
    channel = var.release_channel
  }

  # Add addons and features as required (CSI drivers)
  addons_config {
    # enable GCE PD CSI driver via addons if desired (or enable via Feature)
    # leave defaults - many CSI drivers are automatically available
  }

  ip_allocation_policy {
    use_ip_aliases = true
  }

  # disable legacy metadata endpoints, enable Shielded nodes etc as needed
}

# Separate node pool resource to avoid cluster replacement when changing node pool size
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

    # Spot VMs (may require google-beta; if not supported, use preemptible = true)
    spot = true
    # For older providers:
    # preemptible = true

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Enable shielded nodes if desired
    shielded_instance_config {
      enable_secure_boot = false
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
