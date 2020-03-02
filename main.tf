terraform {
  required_version = ">= 0.12.7"
  backend "gcs" {
    bucket = "dish-co-devops"
    prefix = "terraform/state"
  }
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
  project = local.project
  region  = local.region

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

module "dev-gke" {
  source = "./modules/gke-public-cluster"

  cluster_name                 = "dev"
  project                      = local.project
  location                     = local.cluster_zone
  region                       = local.region
  cluster_service_account_name = "dev-cluster-sa"
  machine_type                 = "n1-highcpu-2"
}

# configure kubectl with the credentials of the GKE cluster
#resource "null_resource" "configure_dev_kubectl" {
#  provisioner "local-exec" {
#    command = "gcloud container clusters get-credentials dev --zone ${local.cluster_zone} --project ${local.project}"
#  }
#
#  depends_on = [module.dev-gke]
#}

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

module "dev-mysql" {
  source = "./modules/mysql-private-ip"

  project              = local.project
  region               = local.region
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
}

resource "kubernetes_namespace" "devops" {
  provider = kubernetes.dev
  metadata {
    annotations = {
      name = "devops"
    }

    name = "devops"
  }
}

resource "kubernetes_secret" "dev-mysql" {
  provider = kubernetes.dev
  metadata {
    name      = "dev-db-secret"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  data = {
    username = "this is a username"
    password = "this is a password"
    host     = "this is a host"
  }
}

#module "prod-gke" {
#  source = "./modules/gke-public-cluster"

#  cluster_name                 = "pre-prod"
#  project                      = local.project
#  location                     = local.cluster_region
#  region                       = local.region
#  max_node_count               = 10
#  cluster_service_account_name = "preprod-cluster-sa"
#  machine_type                 = "n1-highcpu-2"
#}
