data "azurerm_servicebus_namespace" "hmc_servicebus_namespace" {
  name                = join("-", ["hmc-servicebus", var.env])
  resource_group_name = join("-", ["hmc-shared", var.env])
}

module "servicebus-subscription" {
  source       = "git@github.com:hmcts/terraform-module-servicebus-subscription?ref=4.x"
  name         = "hmc-to-${var.product}-subscription-${var.env}"
  namespace_id = data.azurerm_servicebus_namespace.hmc_servicebus_namespace.id
  topic_name   = "hmc-to-cft-${var.env}"
}

resource "azurerm_servicebus_subscription_rule" "topic_service_id_filter_rule" {
  name            = "hmc-servicebus-${var.env}-filter-rule"
  subscription_id = module.servicebus-subscription.id
  filter_type     = "CorrelationFilter"

  correlation_filter {
    properties = {
      hmctsServiceId = var.hmc_service_id
    }
  }
}

data "azurerm_key_vault" "hmc-key-vault" {
  name                = "hmc-${var.env}"
  resource_group_name = "hmc-shared-${var.env}"
}

data "azurerm_key_vault_secret" "hmc-servicebus-connection-string" {
  key_vault_id = data.azurerm_key_vault.hmc-key-vault.id
  name         = "hmc-servicebus-connection-string"
}

resource "azurerm_key_vault_secret" "hmc-servicebus-connection-string" {
  name         = "hmc-servicebus-connection-string"
  value        = data.azurerm_key_vault_secret.hmc-servicebus-connection-string.value
  key_vault_id = module.key-vault.key_vault_id

  content_type = "secret"
  tags = merge(var.common_tags, {
    "source" : "Vault ${module.key-vault.key_vault_id}"
  })
}

data "azurerm_key_vault_secret" "hmc-servicebus-shared-access-key" {
  key_vault_id = data.azurerm_key_vault.hmc-key-vault.id
  name         = "hmc-servicebus-shared-access-key"
}

resource "azurerm_key_vault_secret" "hmc-servicebus-shared-access-key-tf" {
  name         = "hmc-servicebus-shared-access-key"
  value        = data.azurerm_key_vault_secret.hmc-servicebus-shared-access-key.value
  key_vault_id = module.key-vault.key_vault_id

  content_type = "secret"
  tags = merge(var.common_tags, {
    "source" : "Vault ${module.key-vault.key_vault_id}"
  })
}
