variable "authentik_url" {
  type        = string
  description = "The URL of the Authentik instance (e.g., https://auth.example.com)"
}

variable "authentik_token" {
  type        = string
  sensitive   = true
  description = "The API token for Authentik"
}

variable "authentik_insecure" {
  type        = bool
  default     = false
  description = "Skip SSL verification for the Authentik API"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Initial password for the admin user"
}