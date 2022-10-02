output "deployment-apps" {
  description = "The applications corresponding to each environment which can be used for authentication."
  value = {
    for each in azuread_application.deploy : each.display_name => {
      tenant_id       = data.azuread_client_config.current.tenant_id
      subscription_id = data.azurerm_subscription.current.subscription_id
      client_id       = each.application_id
    }
  }
}
