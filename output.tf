output "mdb_fqdn" {
    value = azurerm_mariadb_server.main.fqdn
}

output "mdb_admin_user" {
    value = azurerm_mariadb_server.main.administrator_login
}

output "commandmdb_admin_password" {
    value = azurerm_mariadb_server.main.administrator_login_password
    sensitive = true
}

output "mariadb_connection_command" {
  value = "mysql -h ${azurerm_mariadb_server.main.fqdn} -u ${azurerm_mariadb_server.main.administrator_login} -p --ssl"
}