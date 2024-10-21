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
