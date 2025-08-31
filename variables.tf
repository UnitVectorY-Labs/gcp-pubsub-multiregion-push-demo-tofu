variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "regions" {
  description = "List of regions to deploy resources in"
  type        = list(string)
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "root_repository" {
  description = "Root repository for Docker images"
  type        = string
  default     = "https://ghcr.io"
}

variable "image" {
  description = "The Docker image name"
  type        = string
  default     = "unitvectory-labs/gologhttpjson"
}

variable "image_tag" {
  description = "The Docker image tag"
  type        = string
  default     = "latest"
}

variable "enable_publish_messages" {
  description = "Whether to create the Cloud Scheduler job that triggers every minute"
  type        = bool
  default     = true
}
