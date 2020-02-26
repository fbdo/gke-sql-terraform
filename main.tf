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

provider "kubernetes" {
  version = "~> 1.11"
}

module "dev-gke" {
  source = "./modules/gke-public-cluster"

  cluster_name                 = "dev"
  project                      = local.project
  location                     = local.cluster_zone
  region                       = local.region
  cluster_service_account_name = "dev-cluster-sa"
  machine_type                 = "n1-highcpu-2"
}

provider "kubernetes" {
  alias = "dev"
  host  = module.dev-gke.cluster_endpoint
  //username               = "${google_container_cluster.cluster.master_auth.0.username}"
  //password               = "${google_container_cluster.cluster.master_auth.0.password}"
  client_certificate     = base64decode(module.dev-gke.client_certificate)
  client_key             = base64decode(module.dev-gke.client_key)
  cluster_ca_certificate = module.dev-gke.cluster_ca_certificate
}

module "dev-mysql" {
  source = "./modules/mysql-private-ip"

  project              = local.project
  region               = local.region
  name_prefix          = "dev"
  master_user_name     = "dev"
  master_user_password = "pa22w0rd"
}

resource "kubernetes_secret" "dev-mysql" {
  provider = kubernetes.dev
  metadata {
    name = "dev-db-secret"
  }
  data = {
    username = "this is a username"
    password = "this is a password"
    host     = "this is a host"
  }
}

module "prod-gke" {
  source = "./modules/gke-public-cluster"

  cluster_name                 = "pre-prod"
  project                      = local.project
  location                     = local.cluster_region
  region                       = local.region
  max_node_count               = 10
  cluster_service_account_name = "preprod-cluster-sa"
  machine_type                 = "n1-highcpu-2"
}
