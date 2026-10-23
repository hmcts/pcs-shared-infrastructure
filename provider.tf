terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.11.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {}
}
