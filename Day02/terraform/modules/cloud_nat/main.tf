resource "google_compute_router" "router" {
  name    = var.router_name
  network = var.network
  region  = var.region
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                       = var.nat_name
  router                     = google_compute_router.router.name
  region                     = var.region
  project                    = var.project_id
  nat_ip_allocate_option     = "AUTO_ONLY"
  min_ports_per_vm           = 64
  enable_dynamic_port_allocation = true

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
