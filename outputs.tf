output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.app.client_id
}

output "managed_identity_principal_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "bastion_name" {
  value = azurerm_bastion_host.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}