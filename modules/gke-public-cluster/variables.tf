# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
  description = "The project ID where all resources will be launched."
  type        = string
}

variable "location" {
  description = "The location (region or zone) of the GKE cluster."
  type        = string
}

variable "region" {
  description = "The region for the network. If the cluster is regional, this must be the same region. Otherwise, it should be the region of the zone."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string
  default     = "example-cluster"
}

variable "cluster_service_account_name" {
  description = "The name of the custom service account used for the GKE cluster. This parameter is limited to a maximum of 28 characters."
  type        = string
  default     = "example-cluster-sa"
}

variable "cluster_service_account_description" {
  description = "A description of the custom service account used for the GKE cluster."
  type        = string
  default     = "Example GKE Cluster Service Account managed by Terraform"
}

variable "cluster_service_account_roles" {
  description = "Additional roles to be added to the service account used by GKE cluster."
  type        = list(string)
  default     = []
}

variable "max_node_count" {
  description = "The max number of nodes in the cluster"
  type        = number
  default     = 5
}

variable "machine_type" {
  description = "The machine type used by the cluster nodes"
  type        = string
  default     = "n1-standard-1"
}

# For the example, we recommend a /16 network for the VPC. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_cidr_block" {
  description = "The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27."
  type        = string
  default     = "10.6.0.0/16"
}

# For the example, we recommend a /16 network for the secondary range. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_secondary_cidr_block" {
  description = "The IP address range of the VPC's secondary address range in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27."
  type        = string
  default     = "10.7.0.0/16"
}

# ---------------------------------------------------------------------------------------------------------------------
# TEST PARAMETERS
# These parameters are only used during testing and should not be touched.
# ---------------------------------------------------------------------------------------------------------------------

variable "override_default_node_pool_service_account" {
  description = "When true, this will use the service account that is created for use with the default node pool that comes with all GKE clusters"
  type        = bool
  default     = false
}
