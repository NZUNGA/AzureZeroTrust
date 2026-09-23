# ── USER-ASSIGNED MANAGED IDENTITY ───────────────────────
# User-assigned (not system-assigned) so it survives
# resource replacement and can be reused across resources.
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.required_tags
}

# ── KEY VAULT ─────────────────────────────────────────────
# RBAC authorization model — NOT legacy access policies.
# RBAC provides operation-level audit logs in Azure Monitor.
# Public network access disabled — Private Endpoint only.
resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.required_tags
}

# App identity gets read-only access to secrets
resource "azurerm_role_assignment" "app_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# Terraform deployer gets admin access scoped to this vault only
resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ── AZURE SQL — ENTRA ID ONLY AUTH ────────────────────────
# SQL local authentication disabled entirely.
# No SQL passwords stored anywhere.
resource "azurerm_mssql_server" "main" {
  name                = "sql-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  version             = "12.0"

  azuread_administrator {
    login_username              = var.sql_aad_admin_login
    object_id                   = var.sql_aad_admin_object_id
    azuread_authentication_only = true
  }

  tags = local.required_tags
}

resource "azurerm_mssql_database" "main" {
  name      = "sqldb-${var.project_name}"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "S1"
  tags      = local.required_tags
}