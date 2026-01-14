module "spa_app" {
  source      = "../modules/entra_app"
  display_name = "my-spa-app"
  redirect_uris = ["http://localhost:3000"]

  required_resource_access = [
    {
      resource_app_id = module.api_app.client_id
      resource_access = [
        {
          id   = module.api_app.scope_id
          type = "Scope"
        }
      ]
    }
  ]
}
