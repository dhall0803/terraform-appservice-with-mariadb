locals {
  name_suffix = "appservice-test-${random_integer.id.result}"
}

// Create random int to use as id

resource "random_integer" "id" {
  min = 100
  max = 999
}


// Create resource group

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_suffix}"
  location = var.location
}

// Configure networking

resource "azurerm_network_security_group" "appsrv-nsg" {
  name                = "DatabaseNsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "appsrv" {
  name                 = "snet-${local.name_suffix}-appsrv-backend"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
  service_endpoints = [
    "Microsoft.Sql"
  ]
}

resource "azurerm_subnet_network_security_group_association" "appsrv-backend" {
  subnet_id                 = azurerm_subnet.appsrv.id
  network_security_group_id = azurerm_network_security_group.appsrv-nsg.id
}

// Create app service

resource "azurerm_service_plan" "main" {
  name                = "asp-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

  app_settings = {
    "DB_HOSTNAME" = azurerm_mariadb_server.main.fqdn,
    "DB_NAME"     = azurerm_mariadb_server.main.name
  }

  site_config {
    application_stack {
      php_version = "8.0"
    }
  }

  virtual_network_subnet_id = azurerm_subnet.appsrv.id
}

// Create database
resource "random_password" "mdb_admin_password" {
  length  = 30
  special = false
}

resource "azurerm_mariadb_server" "main" {
  name                = "maria-${local.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  administrator_login          = "mdbadmin"
  administrator_login_password = random_password.mdb_admin_password.result

  sku_name   = "GP_Gen5_2"
  storage_mb = 5120
  version    = "10.2"

  auto_grow_enabled       = true
  ssl_enforcement_enabled = false
}

resource "azurerm_mariadb_firewall_rule" "main" {
  name                = "AllowDeploymetIp"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mariadb_server.main.name
  start_ip_address    = replace(data.http.myip.response_body, "\n", "")
  end_ip_address      = replace(data.http.myip.response_body, "\n", "")
}

resource "azurerm_mariadb_virtual_network_rule" "allow" {
  name                = "mariadb-vnet-rule"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mariadb_server.main.name
  subnet_id           = azurerm_subnet.appsrv.id
}