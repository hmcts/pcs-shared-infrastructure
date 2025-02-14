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

variable "hmc_service_id" {
  default     = "AAA3"
  description = "Service Id used to filter the messages to subscription"
}
