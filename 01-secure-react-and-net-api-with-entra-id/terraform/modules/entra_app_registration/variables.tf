variable "display_name" { type = string }

variable "redirect_uris" {
  type    = list(string)
  default = []
}

variable "web_redirect_uris" {
  type    = list(string)
  default = []
}

variable "expose_scope" {
  type    = bool
  default = false
}

variable "scope_id" {
  type    = string
  default = ""
}

variable "scope_value" {
  type    = string
  default = ""
}

variable "scope_admin_consent_description" {
  type    = string
  default = ""
}

variable "scope_admin_consent_display_name" {
  type    = string
  default = ""
}

variable "required_resource_access" {
  type = list(object({
    resource_app_id = string
    resource_access = list(object({
      id   = string
      type = string
    }))
  }))
  default = []
}
