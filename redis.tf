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


module "pcs_managed_redis" {

  source = "git@github.com:hmcts/terraform-module-azure-managed-redis?ref=main"

  product                      = var.product
  component                    = "redis"
  env                          = var.env
  location                     = var.location
  common_tags                  = var.common_tags
  existing_resource_group_name = azurerm_resource_group.rg.name

  sku_name                = var.managed_redis_sku_name
  public_network_access   = "Disabled"
  create_private_endpoint = true
  subnet_id               = data.azurerm_subnet.redis_private_endpoint.id
  private_dns_zone_ids = [
    "/subscriptions/${var.private_dns_subscription_id}/resourceGroups/core-infra-intsvc-rg/providers/Microsoft.Network/privateDnsZones/privatelink.redis.azure.net"
  ]

  clustering_policy = "EnterpriseCluster"

  moved {
    from = module.pcs_managed_redis["aat"]
    to   = module.pcs_managed_redis
  }

  moved {
    from = azurerm_key_vault_secret.managed_redis_connection_string["aat"]
    to   = azurerm_key_vault_secret.managed_redis_connection_string
  }


  access_keys_authentication_enabled = true
  persistence_rdb_backup_frequency   = "6h"
}

resource "azurerm_key_vault_secret" "managed_redis_connection_string" {


  name         = "azure-managed-redis-connection-string"
  value        = "rediss://:${urlencode(module.pcs_managed_redis.primary_access_key)}@${module.pcs_managed_redis.hostname}:${module.pcs_managed_redis.port}?tls=true"
  key_vault_id = module.key-vault.key_vault_id
}

data "azurerm_subnet" "redis_private_endpoint" {
  name                 = "core-infra-subnet-2-${var.env}"
  resource_group_name  = "core-infra-${var.env}"
  virtual_network_name = "core-infra-vnet-${var.env}"
}