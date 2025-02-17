# Based on:
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "devopscoopterraform"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = true
      recover_soft_deleted_keys          = true
    }
  }
}

resource "azurerm_resource_group" "devopscoop" {
  name     = "devopscoop"
  location = "West US 2"
}

resource "azurerm_kubernetes_cluster" "devopscoop" {
  location            = azurerm_resource_group.devopscoop.location
  name                = "devopscoop"
  resource_group_name = azurerm_resource_group.devopscoop.name
  dns_prefix          = "devopscoop"
  kubernetes_version  = "1.28.5"

  # Enabling OIDC and Workload Identity so external-dns and cert-manager can manage DNS records in Azure DNS.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_B2as_v2"
    node_count = var.node_count

    # This "optional" setting is needed if you ever want to actually change one
    # of like 15 other settings in your cluster. More Azure nonsense - just
    # create a new node pool with timestamp to make it unique or something. WTF
    # Azure!
    temporary_name_for_rotation = "wtfazure"

  }

}

resource "azurerm_virtual_network" "devopscoop" {
  name                = "devopscoop"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devopscoop.location
  resource_group_name = azurerm_resource_group.devopscoop.name
}

resource "azurerm_subnet" "devopscoop" {
  name                 = "devopscoop"
  resource_group_name  = "devopscoop"
  virtual_network_name = azurerm_virtual_network.devopscoop.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

# Ran:
# terraform import azurerm_dns_zone.sandbox /subscriptions/86f3145a-48cc-4255-8757-dd3104d15e57/resourceGroups/devopscoop/providers/Microsoft.Network/dnszones/sandbox.devops.coop
# but it failed. I copied the id directly from the Azure portal, but lo and behold, you have to have a capital "Z" like this to make it work:
# terraform import azurerm_dns_zone.sandbox /subscriptions/86f3145a-48cc-4255-8757-dd3104d15e57/resourceGroups/devopscoop/providers/Microsoft.Network/dnsZones/sandbox.devops.coop
resource "azurerm_dns_zone" "sandbox" {
  name                = "sandbox.devops.coop"
  resource_group_name = azurerm_resource_group.devopscoop.name
}
resource "azurerm_dns_zone" "prod" {
  name                = "prod.devops.coop"
  resource_group_name = azurerm_resource_group.devopscoop.name
}
resource "azurerm_dns_zone" "dev" {
  name                = "dev.devops.coop"
  resource_group_name = azurerm_resource_group.devopscoop.name
}
