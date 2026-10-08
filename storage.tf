locals {
  sdp_export_container = "sdp-export"
}

provider "azurerm" {
  alias           = "private_endpoints"
  subscription_id = var.aks_subscription_id
  features {}
  resource_provider_registrations = "none"
}

data "azurerm_subnet" "private_endpoints" {
  provider = azurerm.private_endpoints

  resource_group_name  = "cft-${var.env}-network-rg"
  virtual_network_name = "cft-${var.env}-vnet"
  name                 = "private-endpoints"
}

module "sdp_export_storage" {
  source                        = "git@github.com:hmcts/cnp-module-storage-account?ref=5.x"
  env                           = var.env
  storage_account_name          = "pcssdp${var.env}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = var.location
  account_kind                  = "StorageV2"
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  access_tier                   = "Hot"
  enable_data_protection        = true
  default_action                = "Deny"
  public_network_access_enabled = false
  private_endpoint_subnet_id    = data.azurerm_subnet.private_endpoints.id
  common_tags                   = var.common_tags

  containers = [
    { name = local.sdp_export_container, access_type = "private" },
  ]

  managed_identity_object_id = module.key-vault.managed_identity_objectid[0]
  role_assignments           = ["Storage Blob Data Contributor"]
}

# SDP's read identity, granted on the container only.
resource "azurerm_role_assignment" "sdp_reader" {
  count                = var.sdp_reader_principal_id == "" ? 0 : 1
  scope                = "${module.sdp_export_storage.storageaccount_id}/blobServices/default/containers/${local.sdp_export_container}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.sdp_reader_principal_id
}
