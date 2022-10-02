# Azure GitHub Actions Deployment User
**Use Terraform to manage federated deployment identities on Azure**

This repository contains a Terraform module which will provision and configure
an Azure Service Principal with permissions to manage specific resources in an
Azure subscription. This Service Principal will be configured with GitHub Actions
OIDC Federated credentials to allow GitHub Actions workflows to authenticate to it.

## Usage
```hcl
module "my-deploy-user" {
    // Configure the name used to identify the Service Principal (must be unique)
    name = "my-application"

    // Configure the source of this module's code
    source = "github.com/SierraSoftworks/terraform-azuread-gha-deployer"

    // Configure the list of repositories which are allowed to deploy using this SP.
    repositories = [
        "my-org/my-repo"
    ]

    // Configure the deployment role which should be used (defaults to Contributor)
    deployment_role = "Contributor"

    // Configure the list of GitHub Actions environments which should be supported, and the list of resources which the SP should have access to in each.
    environments = {
        "Staging"    = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-app-staging"]
        "Production" = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-app-production"]
    }

    // Configure the environment(s) which can be deployed to from PR builds
    pull_requests = ["Staging"]
}
```

## Outputs
This module will output a `deployment-apps` value which contains a list of
objects matching the following schema:

```hcl
map[string]object(
    tenant_id = string
    subscription_id = string
    client_id = string
)
```

Here is an example of how that appears in JSON format.
```json
{
    "Production": {
        "tenant_id": "00000000-0000-0000-0000-000000000000",
        "subscription_id": "00000000-0000-0000-0000-000000000000",
        "client_id": "00000000-0000-0000-0000-000000000000"
    },
    "Staging": {
        "tenant_id": "00000000-0000-0000-0000-000000000000",
        "subscription_id": "00000000-0000-0000-0000-000000000000",
        "client_id": "00000000-0000-0000-0000-000000000000"
    }
}
```

## Configuring GitHub Actions
To configure GitHub Actions to use the Service Principal which is created by this
module, you will need to add the following to your workflow definition:

```yaml
permissions:
  id-token: write
```

This will allow the workflow to request an OIDC token which can be used to authenticate
to Azure using the Service Principal. The next step is to use the `azure/login` action
to perform that authentication. You should include both the environment name and the 
generated `client_id`, `tenant_id`, and `subscription_id` values as shown below.

```yaml
environment:
  name: Staging
steps:
   - uses: azure/login@v1
     with:
       tenant-id: 00000000-0000-0000-0000-000000000000
       subscription-id: 00000000-0000-0000-0000-000000000000
       client-id: 00000000-0000-0000-0000-000000000000
```