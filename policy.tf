# ── CUSTOM POLICY: REQUIRE MANDATORY TAGS ────────────────
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-mandatory-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require mandatory resource tags"
  description  = "Requires Environment, Owner, CostCenter, ManagedBy on all indexed resources."

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Tags"
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['Environment']", exists = "false" },
        { field = "tags['Owner']", exists = "false" },
        { field = "tags['CostCenter']", exists = "false" },
        { field = "tags['ManagedBy']", exists = "false" }
      ]
    }
    then = {
      effect = "Audit"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_tags" {
  name                 = "assign-require-tags"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.require_tags.id
  display_name         = "Require mandatory tags — ${var.environment}"
}

# ── BUILT-IN: DENY PUBLIC IP ON VM ───────────────────────
resource "azurerm_resource_group_policy_assignment" "deny_public_ip_vm" {
  name                 = "deny-public-ip-vm"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
  display_name         = "Deny public IPs on VMs — use Azure Bastion"
}

# ── BUILT-IN: REQUIRE HTTPS ON STORAGE ───────────────────
resource "azurerm_resource_group_policy_assignment" "require_https_storage" {
  name                 = "require-https-storage"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
  display_name         = "Require HTTPS on storage accounts"
}