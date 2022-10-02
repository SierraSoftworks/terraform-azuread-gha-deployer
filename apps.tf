data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azuread_application" "deploy" {
  display_name     = "deploy.${var.name}.${lower(each.key)}"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  for_each = var.environments
}

resource "azuread_service_principal" "deploy" {
  application_id               = each.value.application_id
  app_role_assignment_required = false
  owners = [
    data.azuread_client_config.current.object_id,
  ]

  for_each = azuread_application.deploy
}

resource "azuread_application_federated_identity_credential" "environment" {
  application_object_id = azuread_application.deploy[each.value.environment].object_id
  display_name          = "${replace(each.value.repository, "/", "-")}-${each.value.environment}"
  description           = "Allows deployments from GitHub Actions running in ${each.value.repository} to the '${each.value.environment}' environment."
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${each.value.repository}:environment:${each.value.environment}"

  for_each = local.repository_environments
}

resource "azuread_application_federated_identity_credential" "pull_request" {
  application_object_id = azuread_application.deploy[each.value.environment].object_id
  display_name          = "${replace(each.value.repository, "/", "-")}-pull_requests"
  description           = "Allows deployments from Pull Requests runinng GitHub Actions in ${each.value.repository} to the '${each.value.environment}' environment."
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${each.value.repository}:pull_request"

  for_each = local.pull_request_repositories
}
