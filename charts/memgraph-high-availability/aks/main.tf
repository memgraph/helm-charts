terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                = var.subscription_id
  resource_provider_registrations = "none"
}

# ──────────────────────────────────────────────
# Resource Group
# ──────────────────────────────────────────────
resource "azurerm_resource_group" "mg" {
  name     = var.resource_group_name
  location = var.location
}

# ──────────────────────────────────────────────
# AKS Cluster
# ──────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "memgraph_ha" {
  name                = var.cluster_name
  location            = azurerm_resource_group.mg.location
  resource_group_name = azurerm_resource_group.mg.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

# ──────────────────────────────────────────────
# Providers configured from AKS output
# ──────────────────────────────────────────────
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.memgraph_ha.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.memgraph_ha.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.memgraph_ha.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.memgraph_ha.kube_config[0].cluster_ca_certificate)
  }
}

# ──────────────────────────────────────────────
# Label nodes: first 3 → coordinator, last 2 → data
# Uses a single script to avoid for_each on
# values unknown at plan time.
# ──────────────────────────────────────────────
resource "null_resource" "label_nodes" {
  provisioner "local-exec" {
    command     = "bash ${path.module}/label_nodes.sh ${azurerm_resource_group.mg.name} ${azurerm_kubernetes_cluster.memgraph_ha.name}"
  }

  depends_on = [azurerm_kubernetes_cluster.memgraph_ha]
}

# ──────────────────────────────────────────────
# Helm release: Memgraph HA
# ──────────────────────────────────────────────
resource "helm_release" "memgraph_ha" {
  name  = "memgraph-db"
  chart = "../"

  values = [
    file("${path.module}/${var.values_file}")
  ]

  timeout = 600

  depends_on = [null_resource.label_nodes]
}
