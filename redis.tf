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

# Azure Managed Redis, replacing the Azure Cache for Redis instance above.
# Deployed alongside the old instance so both can run side by side: the new
# connection string lands in a separate key vault secret
# (azure-managed-redis-connection-string), so cutting an app over, and rolling
# it back, is a flux-only change. Widen the for_each to roll out further, then
# remove the module "pcs_redis" block above once every environment has cut over.
module "pcs_managed_redis" {
  for_each = toset(contains(["sandbox", "aat"], var.env) ? [var.env] : [])

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

  # pcs-frontend builds its session store on a plain, non-cluster-aware ioredis
  # client. EnterpriseCluster routes everything through a single proxy endpoint
  # so the instance still looks non-clustered to that client; the OSSCluster
  # default would need the app to switch to Redis.Cluster and handle MOVED.
  clustering_policy = "EnterpriseCluster"

  # Connection strings are still key-based; the module defaults to Entra ID only.
  access_keys_authentication_enabled = true
  persistence_rdb_backup_frequency   = "6h"
}

resource "azurerm_key_vault_secret" "managed_redis_connection_string" {
  for_each = module.pcs_managed_redis

  name         = "azure-managed-redis-connection-string"
  value        = "rediss://:${urlencode(each.value.primary_access_key)}@${each.value.hostname}:${each.value.port}?tls=true"
  key_vault_id = module.key-vault.key_vault_id
}

data "azurerm_subnet" "redis_private_endpoint" {
  name                 = "core-infra-subnet-2-${var.env}"
  resource_group_name  = "core-infra-${var.env}"
  virtual_network_name = "core-infra-vnet-${var.env}"
}
