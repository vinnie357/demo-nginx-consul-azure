# iam

data azurerm_client_config current {
}
#
## controller
#
# service principal
# resource azuread_application controller {
#   name                       = "controller-sa-${random_pet.buildSuffix.id}"
#   homepage                   = "http://homepage"
#   identifier_uris            = ["http://controller/${random_pet.buildSuffix.id}"]
#   reply_urls                 = ["http://replyurl"]
#   available_to_other_tenants = false
#   oauth2_allow_implicit_flow = true
# }

# resource azuread_service_principal controller_sp {
#   application_id               = azuread_application.controller.application_id
#   app_role_assignment_required = false

#   tags = ["dev", "controller", "terraform"]
# }
resource azurerm_user_assigned_identity controller-sa {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  name = "controller-sa-${random_pet.buildSuffix.id}"
}
#
## k8s
#
# service principal
resource azuread_application k8s {
  name                       = "k8s-sa-${random_pet.buildSuffix.id}"
  homepage                   = "http://homepage"
  identifier_uris            = ["http://k8s/${random_pet.buildSuffix.id}"]
  reply_urls                 = ["http://replyurl"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
}

resource azuread_service_principal k8s_sp {
  application_id               = azuread_application.k8s.application_id
  app_role_assignment_required = false

  tags = ["dev", "k8s", "terraform"]
}
# Create a Password for  Service Principal
resource azuread_service_principal_password k8s-cs {
  service_principal_id = azuread_service_principal.k8s_sp.id
  value                = random_password.password.result
  end_date_relative    = "17520h" #expire in 2 years
}
#
## nginx
#
# service principal
# resource azuread_application nginx {
#   name                       = "nginx-sa-${random_pet.buildSuffix.id}"
#   homepage                   = "http://homepage"
#   identifier_uris            = ["http://nginx/${random_pet.buildSuffix.id}"]
#   reply_urls                 = ["http://replyurl"]
#   available_to_other_tenants = false
#   oauth2_allow_implicit_flow = true
# }

# resource azuread_service_principal nginx_sp {
#   application_id               = azuread_application.nginx.application_id
#   app_role_assignment_required = false

#   tags = ["dev", "nginx", "terraform"]
# }
resource azurerm_user_assigned_identity nginx-sa {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  name = "nginx-sa-${random_pet.buildSuffix.id}"
}
#
## role assignments
#
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
  #principal_id         = azuread_service_principal.controller_sp.id
  #principal_id         = lookup(azurerm_virtual_machine.controller.identity[0], "principal_id")
  principal_id = azurerm_user_assigned_identity.nginx-sa.principal_id
}
resource azurerm_role_assignment nginx-secrets {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  #principal_id         = azuread_service_principal.nginx_sp.id
  #principal_id         = lookup(azurerm_virtual_machine.nginx.identity[0], "principal_id")
  principal_id = azurerm_user_assigned_identity.controller-sa.principal_id
}
# assign compute lookup role
# resource azurerm_role_assignment nginx-compute {
#   scope                = azurerm_resource_group.main.id
#   role_definition_name = "Contributor"
#   principal_id         = lookup(azurerm_virtual_machine.nginx.identity[0], "principal_id")
# }
#