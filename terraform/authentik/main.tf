terraform {
  required_version = ">= 1.0"

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2025.12.0"
    }
  }
}

provider "authentik" {
  url      = var.authentik_url
  token    = var.authentik_token
  insecure = var.authentik_insecure
}

# Users
resource "authentik_user" "admin" {
  username = "admin"
  name     = "Admin User"
  password = var.admin_password
}

# Groups
resource "authentik_group" "devops" {
  name         = "devops"
  is_superuser = true
  users        = [authentik_user.admin.id]
}

resource "authentik_group" "users" {
  name         = "users"
  is_superuser = false
}

# Flows (Data Source for defaults)
data "authentik_flow" "default_authorization_flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}

resource "authentik_provider_proxy" "garlic_door" {
  name               = "GarlicDoor"
  external_host      = "https://home.beutra.fr"
  authorization_flow = data.authentik_flow.default_authorization_flow.id
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id
  mode               = "forward_single"
}

resource "authentik_application" "garlic_door" {
  name              = "GarlicDoor"
  slug              = "garlic-door"
  protocol_provider = authentik_provider_proxy.garlic_door.id
}

resource "authentik_service_connection_kubernetes" "local" {
  name  = "Local Kubernetes"
  local = true
}

resource "authentik_outpost" "garlic_door" {
  name               = "GarlicDoor"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = [
    authentik_provider_proxy.garlic_door.id
  ]
  config             = jsonencode({
    kubernetes_replicas = 1
    kubernetes_namespace = "authentik"
  })
}