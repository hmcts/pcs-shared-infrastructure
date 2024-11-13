data "azurerm_client_config" "current" {}

module "key-vault" {
  source                  = "git@github.com:hmcts/cnp-module-key-vault?ref=master"
  product                 = var.product
  env                     = var.env
  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_id               = var.jenkins_AAD_objectId
  resource_group_name     = azurerm_resource_group.rg.name
  product_group_name      = var.product_group_name
  common_tags             = var.common_tags
  create_managed_identity = true
}

output "vaultName" {
  value = module.key-vault.key_vault_name
}

resource "random_string" "session-secret" {
  length = 16
}

resource "azurerm_key_vault_secret" "pcs-session-secret" {
  name         = "pcs-session-secret"
  value        = random_string.session-secret.result
  key_vault_id = module.key-vault.key_vault_id
}