# secrets

# nginx
# create secret
resource azurerm_key_vault nginx {
  name                = format("%s%s", "kv-nginx", random_id.server.hex)
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "premium"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
    ]

    secret_permissions = [
      "set",
      "get",
      "delete",
    ]
  }

  tags = {
    environment = "Dev"
  }
}
# create secret version
resource azurerm_key_vault_secret nginx {
  name         = format("%s%s", "secret-nginx", random_id.server.hex)
  key_vault_id = azurerm_key_vault.nginx.id

  tags = {
    environment = "Dev"
  }
  value = <<-EOF
  {
  "cert":"${var.nginxCert}",
  "key": "${var.nginxKey}",
  "cuser": "${var.controllerAccount}",
  "cpass": "${var.controllerPass}"
  }
  EOF
}
# controller
# create secret
resource azurerm_key_vault controller {
  name                = format("%s%s", "kv-controller", random_id.server.hex)
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "premium"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
    ]

    secret_permissions = [
      "set",
      "get",
      "delete",
    ]
  }

  tags = {
    environment = "Dev"
  }
}
# create secret version
resource azurerm_key_vault_secret controller {
  name         = format("%s%s", "secret-controller", random_id.server.hex)
  key_vault_id = azurerm_key_vault.nginx.id

  tags = {
    environment = "Dev"
  }
  value = <<-EOF
  {
  "license": ${jsonencode(var.controllerLicense)},
  "user": "${var.controllerAccount}",
  "pass": "${var.controllerPass}",
  "dbpass": "${var.dbPass}",
  "dbuser": "${var.dbUser}"
  }
  EOF
}