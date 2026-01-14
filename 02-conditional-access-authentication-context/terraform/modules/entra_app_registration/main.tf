resource "azuread_application" "this" {
  display_name = var.display_name

  public_client {
    redirect_uris = var.redirect_uris
  }

  web {
    redirect_uris = var.web_redirect_uris
  }

  api {
    dynamic "oauth2_permission_scope" {
      for_each = var.expose_scope ? [1] : []
      content {
        admin_consent_description  = var.scope_admin_consent_description
        admin_consent_display_name = var.scope_admin_consent_display_name
        enabled                    = true
        id                         = var.scope_id
        type                       = "User"
        value                      = var.scope_value
      }
    }
  }

  dynamic "required_resource_access" {
  for_each = var.required_resource_access
  content {
    resource_app_id = required_resource_access.value.resource_app_id

    dynamic "resource_access" {
      for_each = required_resource_access.value.resource_access
      content {
        id   = resource_access.value.id
        type = resource_access.value.type
      }
    }
  }
}

}
