terraform {
  required_version = ">= 0.12.7"
  backend "gcs" {
    bucket = "dish-co-devops"
    prefix = "terraform/state"
  }
}

locals {
  cluster_region                      = var.region
  cluster_location                    = "${var.cluster_location == null ? "${var.region}-a" : var.cluster_location}"
  cluster_service_account_name        = "gke-cluster"
  cluster_service_account_description = "GKE cluster service account"
}

provider "google" {
  version = "~> 2.9.0"
  project = var.project
  region  = var.region

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  version = "~> 2.9.0"
  project = var.project
  region  = var.region

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
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
  version = "1.10.0"
}

module "gke" {
  source = "./modules/gke-public-cluster"

  cluster_name                 = var.cluster_name
  project                      = var.project
  location                     = local.cluster_location
  region                       = var.region
  cluster_service_account_name = "${var.cluster_name}-cluster-sa"
  machine_type                 = var.cluster_machine_type
  max_node_count               = 10
}

data "google_client_config" "client" {}

data "google_client_openid_userinfo" "terraform_user" {}

data "template_file" "dev-gke_host_endpoint" {
  template = module.dev-gke.cluster_endpoint
}

data "template_file" "access_token" {
  template = data.google_client_config.client.access_token
}

data "template_file" "dev-gke_cluster_ca_certificate" {
  template = module.dev-gke.cluster_ca_certificate
}

provider "kubernetes" {
  alias = "dev"

  load_config_file       = "false"
  host                   = data.template_file.dev-gke_host_endpoint.rendered
  token                  = data.template_file.access_token.rendered
  cluster_ca_certificate = data.template_file.dev-gke_cluster_ca_certificate.rendered
}

module "mysql" {
  source = "./modules/mysql-private-ip"

  project              = var.project
  region               = var.region
  name_prefix          = "dev"
  master_user_name     = "dev"
  master_user_password = "pa22w0rd"
}

resource "kubernetes_namespace" "dev" {
  provider = kubernetes.dev
  metadata {
    annotations = {
      name = "dev"
    }

    name = "dev"
  }

  depends_on = [module.gke]
}

resource "kubernetes_secret" "mysql" {
  provider = kubernetes.dev
  metadata {
    name      = "dev-db-secret"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  data = {
    username = "dev"
    password = "pa22w0rd"
    host     = module.mysql.master_private_ip
  }

  depends_on = [module.gke]
}
