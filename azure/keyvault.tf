# TODO: Merge this with keyvault-argo.tf - this keyvault.tf is no longer needed - we're using the sops key in the other keyvault.
# Based on:
# https://techcommunity.microsoft.com/t5/azure-global/gitops-and-secret-management-with-aks-flux-cd-sops-and-azure-key/ba-p/2280068
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key
# This is for the sops key that we use to encrypted all Kubernetes secrets.

# Updated provider in main.tf to use these features.
#provider "azurerm" {
#  features {
#    key_vault {
#      purge_soft_deleted_keys_on_destroy = true
#      recover_soft_deleted_keys          = true
#    }
#  }
#}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "devopscoop" {
  name                       = "devopscoop"
  location                   = azurerm_resource_group.devopscoop.location
  resource_group_name        = azurerm_resource_group.devopscoop.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  # It's probably dumb to add the "evans" user (object_id ending in c5e7)
  # directly. There's probably some smart way to do it with roles or something.
  # I am not an Azure expert.

  # TODO: DANGER! This code originally had `object_id =
  # data.azurerm_client_config.current.object_id` in the first access_policy
  # below. This sets the object_id to whatever entity runs `terraform apply`,
  # so if someone runs it locally, it will set the access_policy to their Azure
  # User. This breaks the pipeline, because the first access_policy is for the
  # `terraform` Application. To work around this issue, I've hard-coded the
  # object_id to the `terraform` Application. The proper fix is to do a data
  # lookup on the `terraform` Application and get it's object_id.

  access_policy = [
    {
      application_id          = ""
      certificate_permissions = []
      key_permissions = [
        "Create",
        "Decrypt",
        "Delete",
        "Encrypt",
        "Get",
        "GetRotationPolicy",
        "List",
        "Purge",
        "Recover",
        "SetRotationPolicy",
        "Update"
      ]
      object_id = "e4536f07-8f5a-4501-be90-6a3d2a09b0f3"
      secret_permissions = [
        "Set"
      ]
      storage_permissions = []
      tenant_id           = data.azurerm_client_config.current.tenant_id
    },
    {
      application_id          = ""
      certificate_permissions = []
      key_permissions = [
        "Get",
        "List",
        "Update",
        "Create",
        "Delete",
        "Recover",
        "Decrypt",
        "Encrypt",
        "Purge",
        "GetRotationPolicy",
        "SetRotationPolicy",
      ]
      object_id = "60552b74-872f-4449-b8ab-bc528a45c5e7"
      secret_permissions = [
        "Set",
      ]
      storage_permissions = []
      tenant_id           = data.azurerm_client_config.current.tenant_id
    }
  ]
}

resource "azurerm_key_vault_key" "sops" {
  name         = "sops"
  key_vault_id = azurerm_key_vault.devopscoop.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
  ]
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}
