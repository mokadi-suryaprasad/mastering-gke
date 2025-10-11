project_id  = "gcp-zero-to-hero-467513"
region      = "us-central1"
zones       = ["us-central1-a","us-central1-b","us-central1-c"]

vpc_name    = "gke-private-vpc"
subnet_cidr = "10.10.0.0/16"
subnetwork  = "/projects/gcp-zero-to-hero-467513/regions/us-central1/subnetworks/gke-private-subnet" # <- output from network module

router_name = "gke-us-central1-cloud-router"
nat_name    = "gke-us-central1-nat"

cluster_name = "standard-cluster-private-1"

master_authorized_networks = [
  { display_name = "MY-NETWORK-1", cidr_block = "10.10.10.0/24" }
]

node_count_per_zone = 1
datapath_provider   = "ADVANCED_DATAPATH"
workload_pool       = "gcp-zero-to-hero-467513.svc.id.goog"

machine_type    = "e2-small"
disk_size_gb    = 20
disk_type       = "PD_STANDARD"
image_type      = "COS_CONTAINERD"
release_channel = "RAPID"

master_ipv4_cidr_block = "172.16.0.0/28"
