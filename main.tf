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

module "gke" {
  source = "./modules/gke-public-cluster"

  cluster_name                  = var.cluster_name
  project                       = var.project
  location                      = local.cluster_location
  region                        = var.region
  cluster_service_account_name  = "${var.cluster_name}-cluster-sa"
  cluster_service_account_roles = ["roles/cloudsql.client"]
  machine_type                  = var.cluster_machine_type
  max_node_count                = 10
}

data "google_client_config" "client" {}

data "google_client_openid_userinfo" "terraform_user" {}

data "template_file" "dev-gke_host_endpoint" {
  template = module.gke.cluster_endpoint
}

data "template_file" "access_token" {
  template = data.google_client_config.client.access_token
}

data "template_file" "gke_cluster_ca_certificate" {
  template = module.gke.cluster_ca_certificate
}

provider "kubernetes" {
  version = "1.10.0"

  load_config_file       = "false"
  host                   = data.template_file.dev-gke_host_endpoint.rendered
  token                  = data.template_file.access_token.rendered
  cluster_ca_certificate = data.template_file.gke_cluster_ca_certificate.rendered
}

resource "kubernetes_namespace" "envs" {
  for_each = toset(var.environments)

  metadata {
    annotations = {
      name = each.key
    }

    name = each.key
  }

  depends_on = [module.gke]
}

resource "random_password" "mysql" {
  length  = 16
  special = true
}

module "mysql" {
  source = "./modules/mysql-private-ip"

  project              = var.project
  region               = var.region
  name_prefix          = var.cluster_name
  master_user_name     = var.cluster_name
  master_user_password = random_password.mysql.result
}

resource "google_sql_database" "envs" {
  for_each = toset(var.environments)
  instance = module.mysql.master_instance_name

  name = each.key
}

resource "google_sql_user" "users" {
  for_each = toset(var.environments)

  name     = "notejam-${each.key}"
  instance = module.mysql.master_instance_name
  password = "changeme"
}

resource "kubernetes_secret" "mysql" {
  for_each = toset(var.environments)

  metadata {
    name      = "db-secret"
    namespace = each.key
  }
  data = {
    username = "notejam-${each.key}"
    password = "changeme"
    host     = module.mysql.master_private_ip
  }

  depends_on = [kubernetes_namespace.envs]
}
