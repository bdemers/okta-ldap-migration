terraform {
  required_providers {
    okta = {
      source = "okta/okta"
      version = "~> 3.20"
    }
  }
}

# Create an OIDC application
resource "okta_app_oauth" "app_oauth" {
  label                      = "ldap-migration-example"
  type                       = "web"
  grant_types                = ["authorization_code"]
  redirect_uris              = ["http://localhost:8080/login/oauth2/code/okta"]
  post_logout_redirect_uris  = ["http://localhost:8080/"]
  response_types             = ["code"]
  lifecycle {
     ignore_changes = [groups]
  }
}

# Create a user role group
resource "okta_group" "everyone" {
  name        = "Everyone"
  description = "All users in your organization"
}

# Add the "ROLE_USER" group to the OIDC app
resource "okta_app_group_assignment" "user-role-to-app" {
  app_id   = okta_app_oauth.app_oauth.id
  group_id = okta_group.everyone.id
}

# get the ID of the 'default' auth server
resource "okta_auth_server" "default" {
  name        = "default"
  audiences   = ["api://default"]
}

# Write .env file used by docker compose
resource "local_file" "env" {
    filename = "${path.module}/.env"
    file_permission = "0600"
    content = <<-EOT
      ISSUER=${okta_auth_server.default.issuer}
      CLIENT_ID=${okta_app_oauth.app_oauth.client_id}
      CLIENT_SECRET=${okta_app_oauth.app_oauth.client_secret}
      OKTA_URL=# TODO resolve this from properties
      OKTA_LDAP_ID=
      OKTA_LDAP_HOST=
      OKTA_LDAP_BASE=
      OKTA_LDAP_USERNAME=
      OKTA_LDAP_PASSWORD=
    EOT
}


# If not using docker compose use these values to configure the web app
output "ISSUER" {
  value = okta_auth_server.default.issuer
}

output "CLIENT_ID" {
  value = okta_app_oauth.app_oauth.client_id
}

output "CLIENT_SECRET" {
  value = okta_app_oauth.app_oauth.client_secret
  sensitive = true
}
