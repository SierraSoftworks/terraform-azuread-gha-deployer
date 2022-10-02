variable "name" {
  description = "The name of the application which should be deployed."
}

variable "repositories" {
  description = "The repositories from which deployments will be conducted."
  type        = set(string)
  default     = []
}

variable "environments" {
  description = "The environments which will be deployed to and the list of scopes which can be deployed to as a result."
  type        = map(set(string))
  default = {
    "Staging"    = []
    "Production" = []
  }
}

variable "pull_requests" {
  description = "The list of environments that can be deployed to from pull requests."
  type        = set(string)
  default     = []
}

variable "deployment_role" {
  description = "The role which should be assigned to the deployment service principal."
  type        = string
  default     = "Contributor"
}

locals {
  environments = [
    for key, value in var.environments : {
      environment = key
      scopes      = value
    }
  ]

  environment_scopes = {
    for env_scope in flatten([
      for env in local.environments : [
        for scope in env.scopes : {
          environment = env.environment
          scope       = scope
        }
      ]
    ]) : "${env_scope.environment}:${env_scope.scope}" => env_scope
  }

  repository_environments = {
    for pair in setproduct(local.environments, var.repositories) : "${pair[1]}@${pair[0].environment}" => {
      environment = pair[0].environment
      scopes      = pair[0].scopes
      repository  = pair[1]
    }
  }

  pull_request_environments = setunion(keys(var.environments), var.pull_requests)
  pull_request_repositories = {
    for pair in setproduct(local.pull_request_environments, var.repositories) : "${pair[1]}@${pair[0]}" => {
      environment = pair[0]
      repository  = pair[1]
    }
  }
}
