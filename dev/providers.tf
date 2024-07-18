terraform {
  required_version = ">=0.12"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }

  backend "azurerm" {
    storage_account_name="cdelapaztfc21345"
    resource_group_name="cdelapaz-tfc-21345"
    container_name="terraform-state"
    key = "migration-poc"
  }

  # cloud {
  #   organization = "chnw-poc"
  #   workspaces {
  #     name = "dev"
  #   }
  # }
}

data "azurerm_client_config" "current" {}

provider "azurerm" {
  features {}
}
