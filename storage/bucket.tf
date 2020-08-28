locals {
  rightnow = timestamp()
}

resource azurerm_resource_group controller-demo-rg {
  name     = format("%s%s", "controller-storage-rg", random_id.server.hex)
  location = var.location
}

resource azurerm_storage_account controller-demo-storage-account {
  name                     = format("%s%s", "controllersa", random_id.server.hex)
  resource_group_name      = azurerm_resource_group.controller-demo-rg.name
  location                 = azurerm_resource_group.controller-demo-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "dev"
  }
}

resource azurerm_storage_container controller-demo-storage-container {
  name                  = format("%s%s", "controller-demo", random_id.server.hex)
  storage_account_name  = azurerm_storage_account.controller-demo-storage-account.name
  container_access_type = "private"
}
resource azurerm_storage_blob controller-file {
  name                   = "controller-installer-3.7.0.tar.gz"
  storage_account_name   = azurerm_storage_account.controller-demo-storage-account.name
  storage_container_name = azurerm_storage_container.controller-demo-storage-container.name
  type                   = "Block"
  source                 = "${path.module}/controller-installer-3.7.0.tar.gz"
}
data azurerm_storage_account_sas controller-sas {
  connection_string = azurerm_storage_account.controller-demo-storage-account.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = formatdate("YYYY-MM-DD", local.rightnow)
  expiry = formatdate("YYYY-MM-DD", timeadd(local.rightnow, "36h"))

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}
