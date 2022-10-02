
resource "azurerm_role_assignment" "deploy" {
  scope                = each.value.scope
  principal_id         = azuread_service_principal.deploy[each.value.environment].object_id
  role_definition_name = var.deployment_role

  for_each = local.environment_scopes
}
