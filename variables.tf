variable "product" {}

variable "location" {
  default = "UK South"
}

variable "env" {}

variable "jenkins_AAD_objectId" {}

variable "common_tags" {
  type = map(string)
}

variable "product_group_name" {
  default = "DTS Possession Claim Service"
}

variable "family" {
  default     = "C"
  description = "The SKU family/pricing group to use. Valid values are `C` (for Basic/Standard SKU family) and `P` (for Premium). Use P for higher availability, but beware it costs a lot more."
}

variable "sku_name" {
  default     = "Basic"
  description = "The SKU of Redis to use. Possible values are `Basic`, `Standard` and `Premium`."
}

variable "capacity" {
  default     = "1"
  description = "The size of the Redis cache to deploy. Valid values are 1, 2, 3, 4, 5"
}

variable "managed_redis_sku_name" {
  default     = "Balanced_B1"
  description = "The Azure Managed Redis SKU, in <Tier>_<Size> form. Tiers are Balanced (B), ComputeOptimized (X), FlashOptimized (A) and MemoryOptimized (M)."
}

variable "private_dns_subscription_id" {
  default     = "1baf5470-1c3e-40d3-a6f7-74bfbce4b348"
  description = "Subscription holding the core-infra private DNS zones."
}

variable "hmc_service_id" {
  default     = "AAA3"
  description = "Service Id used to filter the messages to subscription"
}

variable "sampling_percentage" {
  default     = null
  description = "Specifies the sampling percentage for Application Insights"
  type        = number
}
