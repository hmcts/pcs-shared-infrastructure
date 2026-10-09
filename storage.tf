locals {
  sdp_export_container      = "sdp-export"
  sdp_export_retention_days = 14
}

module "sdp_export_storage" {
  source                   = "git@github.com:hmcts/cnp-module-storage-account?ref=5.x"
  env                      = var.env
  storage_account_name     = "pcssdp${var.env}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  access_tier              = "Hot"
  enable_data_protection   = true
  default_action           = "Allow"
  common_tags              = var.common_tags

  enable_versioning               = false
  blob_soft_delete_retention_days = 7

  containers = [
    { name = local.sdp_export_container, access_type = "private" },
  ]

  managed_identity_object_id = module.key-vault.managed_identity_objectid[0]
  role_assignments           = ["Storage Blob Data Contributor"]
}

resource "azurerm_storage_management_policy" "sdp_export_retention" {
  storage_account_id = module.sdp_export_storage.storageaccount_id

  rule {
    name    = "delete-exports-after-${local.sdp_export_retention_days}-days"
    enabled = true

    filters {
      prefix_match = ["${local.sdp_export_container}/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_creation_greater_than = local.sdp_export_retention_days
      }
      version {
        delete_after_days_since_creation = local.sdp_export_retention_days
      }
      snapshot {
        delete_after_days_since_creation_greater_than = local.sdp_export_retention_days
      }
    }
  }
}

# SDP's ingestion identities, granted on the container only. Contributor rather than Reader
# because Jenkins may only assign the roles in rbac_admin_roles (hmcts/cft-jenkins-infrastructure),
# and Storage Blob Data Reader isn't one of them outside sandbox.
resource "azurerm_role_assignment" "sdp_reader" {
  for_each             = var.sdp_readers
  scope                = "${module.sdp_export_storage.storageaccount_id}/blobServices/default/containers/${local.sdp_export_container}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}
