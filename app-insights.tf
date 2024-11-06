module "application_insights" {
  source   = "git@github.com:hmcts/terraform-module-application-insights?ref=main"
  env      = var.env
  product  = var.product
  location = var.location

  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
  common_tags         = var.common_tags
}

resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "app-insights-connection-string"
  value        = module.application_insights.connection_string
  key_vault_id = module.key-vault.key_vault_id
}
