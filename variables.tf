variable "project" {
  description = "The project ID to host the solution."
  type        = string
}

variable "region" {
  description = "The region for deployment."
  type        = string
  default     = "europe-west3"
}

variable "cluster_location" {
  description = "The location (region or zone) of the GKE cluster. (Optional)"
  type        = string
  default     = null
}

variable "cluster_machine_type" {
  description = "The machine type of each gke node in the pool (Optional)"
  type        = string
  default     = "n1-standard-2"
}

variable "cluster_name" {
  description = "The cluster name (Optional)"
  type        = string
  default     = "dev"
}

variable "environments" {
  type    = "list"
  default = ["dev", "qa", "prod"]
}
