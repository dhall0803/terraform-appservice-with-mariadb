# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.1.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

provider "random" {
  # Configuration options
}

provider "http" {

}