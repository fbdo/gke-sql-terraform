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
