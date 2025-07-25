output "client_id" {
  value = azuread_application.this.client_id
}

output "object_id" {
  value = azuread_application.this.id
}

output "scope_id" {
  value = try(
    [
      for scope in azuread_application.this.api[0].oauth2_permission_scope :
      scope.id
    ][0],
    null
  )
}