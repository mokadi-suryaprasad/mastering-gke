variable "project_id" {}
variable "region" {}
variable "zone" {}
variable "cluster_name" {}
variable "network" {}
variable "subnetwork" {}
variable "master_ipv4_cidr_block" {}
variable "master_authorized_networks" {
  type = list(object({
    display_name = string
    cidr_block   = string
  }))
  default = []
}
variable "workload_pool" {}
variable "datapath_provider" {}
variable "release_channel" {}
variable "node_count_per_zone" {}
variable "machine_type" {}
variable "disk_size_gb" {}
variable "disk_type" {}
variable "image_type" {}
variable "zones" {
  type = list(string)
  default = ["us-central1-a", "us-central1-b", "us-central1-c"]
}
