module "api_app" {
  source      = "../modules/entra_app"
  display_name = "my-api-app"
  web_redirect_uris = ["https://localhost/api-callback"]
  expose_scope = true

  scope_id   = "11111111-1111-1111-1111-111111111111"
  scope_value = "access_as_user"
  scope_admin_consent_description  = "Allow access to API"
  scope_admin_consent_display_name = "Access API"
}
