# nginx
# data "http" "template_nginx" {
#     url = var.onboardScript
# }
# Setup Onboarding scripts
data template_file nginx_onboard {
  template = file("${path.module}/templates/nginx/startup.sh.tpl")

  vars = {
    controllerAddress = "12134"
  }
}
# Create a Public IP for the Virtual Machines
resource azurerm_public_ip nginx {
  name                = "${var.prefix}nginx-mgmt-pip-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"

  tags = {
    Name = "${var.prefix}-nginx-public-ip"
  }
}

# linuxbox
resource azurerm_network_interface nginx-mgmt-nic {
  name                = "${var.prefix}-nginx-mgmt-nic-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name      = "primary"
    subnet_id = azurerm_subnet.mgmt.id
    # private_ip_address_allocation = "Static"
    # private_ip_address            = var.nginxIp
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.nginx.id
  }

  tags = {
    Name        = "${var.environment}-nginx-ext-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = "nginx"
  }
}
resource azurerm_virtual_machine nginx {
  name                = "${var.prefix}-nginx-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  network_interface_ids = [azurerm_network_interface.nginx-mgmt-nic.id]
  vm_size               = var.nginxInstanceType

  storage_os_disk {
    name              = "nginxOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.nginxDiskType
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
    computer_name  = "nginx"
    admin_username = var.adminAccountName
    admin_password = var.adminPassword == "" ? random_password.password.result : var.adminPassword
    custom_data    = data.template_file.nginx_onboard.rendered
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
    Name        = "${var.environment}-nginx"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}
# https://staffordwilliams.com/blog/2019/04/14/executing-custom-scripts-during-arm-template-vm-deployment/
# "commandToExecute": "[concat('curl -o ./custom-script.sh, ' && chmod +x ./custom-script.sh && ./custom-script.sh')]"
# Run Startup Script
resource azurerm_virtual_machine_extension nginx-run-startup-cmd {
  name                 = "${var.prefix}-nginx-run-startup-cmd${random_pet.buildSuffix.id}"
  depends_on           = [azurerm_virtual_machine.nginx]
  virtual_machine_id   = azurerm_virtual_machine.nginx.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "echo '${base64encode(data.template_file.nginx_onboard.rendered)}' >> ./startup.sh && cat ./startup.sh | base64 -d >> ./startup-script.sh && chmod +x ./startup-script.sh && rm ./startup.sh && bash ./startup-script.sh"
        
    }
  SETTINGS

  tags = {
    Name        = "${var.environment}-nginx-startup-cmd"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}