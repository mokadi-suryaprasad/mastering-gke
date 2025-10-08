terraform {
  backend "gcs" {
    bucket = "terraform-state-hero-gke"               
    prefix = "gke-private-cluster/terraform.tfstate"
  }
}
