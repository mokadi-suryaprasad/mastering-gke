variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" { default = "us-central1" }
variable "zones" { default = ["us-central1-a", "us-central1-b", "us-central1-c"] }

variable "vpc_name" { default = "gke-private-vpc" }
variable "subnet_cidr" { default = "10.10.0.0/16" }
variable "subnetwork" {
  description = "Subnetwork self-link for GKE"
  type        = string
}

variable "router_name" { default = "gke-us-central1-cloud-router" }
variable "nat_name"    { default = "gke-us-central1-nat" }

variable "cluster_name" { default = "standard-cluster-private-1" }

variable "master_authorized_networks" {
  type = list(object({
    display_name = string
    cidr_block   = string
  }))
  default = [
    { display_name = "MY-NETWORK-1", cidr_block = "10.10.10.0/24" }
  ]
}

variable "node_count_per_zone" { default = 1 }
variable "datapath_provider" { default = "ADVANCED_DATAPATH" }
variable "workload_pool" { default = "" }

variable "machine_type"  { default = "e2-small" }
variable "disk_size_gb"  { default = 20 }
variable "disk_type"     { default = "PD_STANDARD" }
variable "image_type"    { default = "COS_CONTAINERD" }
variable "release_channel" { default = "RAPID" }
variable "master_ipv4_cidr_block" { default = "172.16.0.0/28" }
