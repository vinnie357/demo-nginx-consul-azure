# controller
# data "http" "template_controller" {
#     url = var.onboardScript
# }
# Setup Onboarding scripts
data template_file controller_onboard {
  template = file("${path.module}/templates/controller/startup.sh.tpl")

  vars = {
    # google
    bucket         = var.controllerBucket
    serviceAccount = var.controllerServiceAccount
    # azure
    controllerInstallUrl = var.controllerInstallUrl
    subscriptionId       = data.azurerm_client_config.current.subscription_id
    resourceGroupName    = azurerm_resource_group.main.name
    vaultName            = azurerm_key_vault.controller.name
    secretName           = azurerm_key_vault_secret.controller.name
    secretVersion        = azurerm_key_vault_secret.controller.version
  }
}
# Create a Public IP for the Virtual Machines
resource azurerm_public_ip controller {
  name                = "${var.prefix}-controller-mgmt-pip-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"

  tags = {
    Name = "${var.prefix}-controller-public-ip"
  }
}

# linuxbox
resource azurerm_network_interface controller-mgmt-nic {
  name                = "${var.prefix}-controller-mgmt-nic-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name      = "primary"
    subnet_id = azurerm_subnet.mgmt.id
    # private_ip_address_allocation = "Static"
    # private_ip_address            = var.controllerIp
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.controller.id
  }

  tags = {
    Name        = "${var.environment}-controller-ext-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = "controller"
  }
}
resource azurerm_virtual_machine controller {
  name                = "${var.prefix}-controller-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  network_interface_ids = [azurerm_network_interface.controller-mgmt-nic.id]
  vm_size               = var.controllerInstanceType
  # identity {
  #   type = "SystemAssigned"
  # }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.controller-sa.id]
  }
  storage_os_disk {
    name              = "controllerOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.controllerDiskType
    disk_size_gb      = var.controllerDiskSize
  }

  # 20
  # storage_image_reference {
  #     publisher = "Canonical"
  #     offer     = "0001-com-ubuntu-server-focal"
  #     sku       = "20_04-lts"
  #     version   = "latest"
  # }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "controller"
    admin_username = var.adminAccountName
    admin_password = var.adminPassword == "" ? random_password.password.result : var.adminPassword
    custom_data    = data.template_file.controller_onboard.rendered

  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      #NOTE: Due to a limitation in the Azure VM Agent the only allowed path is /home/{username}/.ssh/authorized_keys.
      path     = "/home/${var.adminAccountName}/.ssh/authorized_keys"
      key_data = var.sshPublicKey
    }
  }

  tags = {
    Name        = "${var.environment}-controller"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}
# https://staffordwilliams.com/blog/2019/04/14/executing-custom-scripts-during-arm-template-vm-deployment/
# "commandToExecute": "[concat('curl -o ./custom-script.sh, ' && chmod +x ./custom-script.sh && ./custom-script.sh')]"
# debug /var/lib/waagent/custom-script/download/0/startup-script.sh
# Run Startup Script
resource azurerm_virtual_machine_extension controller-run-startup-cmd {
  name                 = "${var.prefix}-controller-run-startup-cmd${random_pet.buildSuffix.id}"
  depends_on           = [azurerm_virtual_machine.controller, azurerm_role_assignment.controller-secrets]
  virtual_machine_id   = azurerm_virtual_machine.controller.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "echo '${base64encode(data.template_file.controller_onboard.rendered)}' >> ./startup.sh && cat ./startup.sh | base64 -d >> ./startup-script.sh && chmod +x ./startup-script.sh && rm ./startup.sh && bash ./startup-script.sh"
        
    }
  SETTINGS

  tags = {
    Name        = "${var.environment}-controller-startup-cmd"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}