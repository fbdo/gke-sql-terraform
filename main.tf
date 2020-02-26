terraform {
  required_version = ">= 0.12.7"
}

locals {
  project = "dish-co"
  region  = "europe-west3"
}

locals {
  cluster_region                      = local.region
  cluster_zone                        = "${local.region}-a"
  cluster_service_account_name        = "gke-cluster"
  cluster_service_account_description = "GKE cluster service account"
}

provider "google" {
  version = "~> 2.9.0"
  project = local.project
  region  = local.region
}

provider "google-beta" {
  version = "~> 2.9.0"
  project = local.project
  region  = local.region
}

provider "random" {
  version = "~> 2.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

module "devops" {
  source = "./modules/gke-public-cluster"

  cluster_name                 = "devops"
  project                      = local.project
  location                     = local.cluster_zone
  region                       = local.region
  cluster_service_account_name = "devops-cluster-sa"
  machine_type                 = "n1-highcpu-2"
}

module "qa" {
  source = "./modules/gke-public-cluster"

  cluster_name                 = "qa"
  project                      = local.project
  location                     = local.cluster_zone
  region                       = local.region
  cluster_service_account_name = "qa-cluster-sa"
  machine_type                 = "n1-highcpu-2"
}

module "qa-mysql" {
  source = "./modules/mysql-private-ip"

  project              = local.project
  region               = local.region
  name_prefix          = "qa"
  master_user_name     = "qa"
  master_user_password = "pa22w0rd"
}

module "pre-prod" {
  source = "./modules/gke-public-cluster"

  cluster_name                 = "pre-prod"
  project                      = local.project
  location                     = local.cluster_region
  region                       = local.region
  max_node_count               = 10
  cluster_service_account_name = "preprod-cluster-sa"
  machine_type                 = "n1-highcpu-2"
}
