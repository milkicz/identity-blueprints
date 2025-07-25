

# Call API App Module
module "api_app" {
  source      = "./modules/entra_app_registration"
  display_name = "my-api-app"
  web_redirect_uris = ["https://localhost/api-callback"]
  expose_scope = true

  scope_id   = "11111111-1111-1111-1111-111111111111"
  scope_value = "access_as_user"
  scope_admin_consent_description  = "Allow access to the API"
  scope_admin_consent_display_name = "Access API"
}

# Call SPA App Module
module "spa_app" {
  source         = "./modules/entra_app_registration"
  display_name   = "my-spa-app"
  redirect_uris  = ["http://localhost:3000"]

  required_resource_access = [
    {
      resource_app_id = module.api_app.client_id
      resource_access = [
        {
          id   = module.api_app.scope_id
          type = "Scope"
        }
      ]
    },
    {
      resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
      resource_access = [
        {
          id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
          type = "Scope"
        },
        {
          id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
          type = "Scope"
        },
        {
          id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # user.read 
          type = "Scope"
        },
        {
          id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
          type = "Scope"
        }
      ]
    }
  ]
}


# --- Service Principals ---
resource "azuread_service_principal" "spa_sp" {
  client_id = module.spa_app.client_id
}

resource "azuread_service_principal" "api_sp" {
  client_id = module.api_app.client_id
}

# Microsoft Graph is global — just fetch it
data "azuread_service_principal" "microsoft_graph" {
  display_name = "Microsoft Graph"
}

# --- Admin Consent: SPA -> Custom API ---
resource "azuread_service_principal_delegated_permission_grant" "spa_to_api" {
  service_principal_object_id          = azuread_service_principal.spa_sp.object_id
  resource_service_principal_object_id = azuread_service_principal.api_sp.object_id
  claim_values                         = ["access_as_user"]
}

# --- Admin Consent: SPA -> Microsoft Graph (openid, profile, email) ---
resource "azuread_service_principal_delegated_permission_grant" "spa_to_graph" {
  service_principal_object_id          = azuread_service_principal.spa_sp.object_id
  resource_service_principal_object_id = data.azuread_service_principal.microsoft_graph.object_id
  claim_values                         = ["openid", "profile", "email"]
}

