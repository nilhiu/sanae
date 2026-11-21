variable "origin_url" {
  type        = string
  description = "Origin URL of the Vault server"
  default     = "http://127.0.0.1:8200"
}

variable "eso_k8s_sa" {
  type        = string
  description = "ESO service account to authorize for Vault access"
  default     = "external-secrets"
}

variable "eso_k8s_namespace" {
  type        = string
  description = "Namespace where the ESO service account lives in"
  default     = "eso"
}
