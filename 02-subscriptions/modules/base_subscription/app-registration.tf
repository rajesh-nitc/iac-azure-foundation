# web is Single Page Application
# api is backend api to web
# app is standalone server app

resource "random_uuid" "api" {
  for_each = { for k, v in var.uai_repos : k => v if can(regex(".*api.*", k)) }
}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

# If user provide web
resource "azuread_application" "web" {
  for_each         = { for k, v in var.uai_repos : k => v if can(regex(".*web.*", k)) }
  display_name     = format("%s-%s-%s-%s-%s", "app", var.bu, var.app, "web", var.env)
  identifier_uris  = ["api://${format("%s-%s-%s-%s", var.bu, var.app, "web", var.env)}"]
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  single_page_application {
    redirect_uris = []
  }

  web {
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  api {
    requested_access_token_version = 2
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  # Redirect uris will be updated manually by azure-devs group
  lifecycle {
    ignore_changes = [
      single_page_application[0].redirect_uris,
      required_resource_access,
    ]
  }

}

# Create client secret to use hybrid flow which will return access and refresh tokens
resource "azuread_application_password" "web" {
  for_each              = { for k, v in var.uai_repos : k => v if can(regex(".*web.*", k)) }
  application_object_id = azuread_application.web[each.key].id
}

# If user provide app
resource "azuread_application" "app" {
  for_each         = { for k, v in var.uai_repos : k => v if can(regex(".*app.*", k)) }
  display_name     = format("%s-%s-%s-%s-%s", "app", var.bu, var.app, each.key, var.env)
  identifier_uris  = ["api://${format("%s-%s-%s-%s", var.bu, var.app, each.key, var.env)}"]
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  web {
    redirect_uris = []
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  api {
    mapped_claims_enabled          = false
    requested_access_token_version = 2
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  # Redirect uris will be updated manually by azure-devs group
  lifecycle {
    ignore_changes = [
      web[0].redirect_uris,
      required_resource_access,
    ]
  }

}

# If user provide api
resource "azuread_application" "api" {
  for_each         = { for k, v in var.uai_repos : k => v if can(regex(".*api.*", k)) }
  display_name     = format("%s-%s-%s-%s-%s", "app", var.bu, var.app, each.key, var.env)
  identifier_uris  = ["api://${format("%s-%s-%s-%s", var.bu, var.app, each.key, var.env)}"]
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  web {
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  api {
    mapped_claims_enabled          = false
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Allow client to access backend api on behalf of the signed-in user."
      admin_consent_display_name = "Access backend api"
      enabled                    = true
      id                         = random_uuid.api[each.key].result
      type                       = "User"
      user_consent_description   = "Allow client to access backend api on your behalf."
      user_consent_display_name  = "Access backend api"
      value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  lifecycle {
    ignore_changes = [
      required_resource_access,
    ]
  }

}