data "azurerm_client_config" "current" {}

module "key-vault" {
  source                       = "git@github.com:hmcts/cnp-module-key-vault?ref=DTSPO-31965/remove-jenkins-ptl-access"
  product                      = var.product
  env                          = var.env
  tenant_id                    = data.azurerm_client_config.current.tenant_id
  object_id                    = var.jenkins_AAD_objectId
  jenkins_object_id            = data.azurerm_user_assigned_identity.jenkins.principal_id
  resource_group_name          = azurerm_resource_group.rg.name
  product_group_name           = var.product_group_name
  common_tags                  = var.common_tags
  create_managed_identity      = true
  grant_preview_jenkins_access = var.env == "aat"
}

data "azurerm_user_assigned_identity" "jenkins" {
  name                = "jenkins-${var.env}-mi"
  resource_group_name = "managed-identities-${var.env}-rg"
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


data "azurerm_key_vault" "s2s_vault" {
  name                = "s2s-${var.env}"
  resource_group_name = "rpe-service-auth-provider-${var.env}"
}

data "azurerm_key_vault_secret" "api_s2s_key_from_vault" {
  name         = "microservicekey-pcs-api"
  key_vault_id = data.azurerm_key_vault.s2s_vault.id
}

resource "azurerm_key_vault_secret" "pcs-api-s2s-secret" {
  name         = "pcs-api-s2s-secret"
  value        = data.azurerm_key_vault_secret.api_s2s_key_from_vault.value
  key_vault_id = module.key-vault.key_vault_id
}

data "azurerm_key_vault_secret" "frontend_s2s_key_from_vault" {
  name         = "microservicekey-pcs-frontend"
  key_vault_id = data.azurerm_key_vault.s2s_vault.id
}

resource "azurerm_key_vault_secret" "pcs-frontend-s2s-secret" {
  name         = "pcs-frontend-s2s-secret"
  value        = data.azurerm_key_vault_secret.frontend_s2s_key_from_vault.value
  key_vault_id = module.key-vault.key_vault_id
}
