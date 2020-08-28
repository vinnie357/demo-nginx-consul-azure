# iam

data azurerm_client_config current {
}

#https://www.terraform.io/docs/providers/azurerm/r/role_assignment.html
# Configure VMs to use a system-assigned managed identity
# resource azurerm_role_definition secrets {
#   role_definition_id = "00000000-0000-0000-0000-000000000000"
#   name               = "my-custom-role-definition"
#   scope              = data.azurerm_client_config.current.subscription_id

#   permissions {
#     actions     = ["Microsoft.Resources/subscriptions/resourceGroups/read"]
#     not_actions = []
#   }

#   assignable_scopes = [
#     data.azurerm_client_config.current.subscription_id,
#   ]
# }
# resource azurerm_role_assignment controller-secrets {
#   scope                = azurerm_resource_group.main.id
#   role_definition_name = "Contributor"
#   principal_id         = lookup(azurerm_linux_virtual_machine.controller.identity[0], "principal_id")
# }
##
# create compute lookup/ secret viewer role
# create secret viewer role

##assign secret viewer role
resource azurerm_role_assignment controller-secrets {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = lookup(azurerm_virtual_machine.controller.identity[0], "principal_id")
}
resource azurerm_role_assignment nginx-secrets {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = lookup(azurerm_virtual_machine.nginx.identity[0], "principal_id")
}
# assign compute lookup role
# resource azurerm_role_assignment nginx-compute {
#   scope                = azurerm_resource_group.main.id
#   role_definition_name = "Contributor"
#   principal_id         = lookup(azurerm_virtual_machine.nginx.identity[0], "principal_id")
# }

# service principal
# resource "azuread_application" "example" {
#   name                       = "example"
#   homepage                   = "http://homepage"
#   identifier_uris            = ["http://uri"]
#   reply_urls                 = ["http://replyurl"]
#   available_to_other_tenants = false
#   oauth2_allow_implicit_flow = true
# }

# resource "azuread_service_principal" "example" {
#   application_id               = azuread_application.example.application_id
#   app_role_assignment_required = false

#   tags = ["example", "tags", "here"]
# }