variable "project_id" {}
variable "region" {}
variable "network_name" { default = "gke-private-vpc" }
variable "subnet_cidr" { default = "10.10.0.0/16" }
