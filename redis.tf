data "azurerm_subnet" "core_infra_redis_subnet" {
  name                 = "core-infra-subnet-1-${var.env}"
  virtual_network_name = "core-infra-vnet-${var.env}"
  resource_group_name  = "core-infra-${var.env}"
}


module "pcs_redis" {
  source                        = "git@github.com:hmcts/cnp-module-redis?ref=master"
  product                       = var.product
  location                      = azurerm_resource_group.rg.location
  env                           = var.env
  common_tags                   = var.common_tags
  redis_version                 = "6"
  business_area                 = "cft"
  private_endpoint_enabled      = true
  public_network_access_enabled = false
  sku_name                      = var.sku_name
  family                        = var.family
  capacity                      = var.capacity
  resource_group_name           = azurerm_resource_group.rg.name
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"
  value        = "rediss://:${urlencode(module.pcs_redis.access_key)}@${module.pcs_redis.host_name}:${module.pcs_redis.redis_port}?tls=true"
  key_vault_id = module.key-vault.key_vault_id
}
