# consul
# data "http" "template_consul" {
#     url = var.onboardScript
# }
# Setup Onboarding scripts
data template_file consul_onboard {
  template = file("${path.module}/templates/consul/startup.sh.tpl")

  vars = {
    CONSUL_VERSION = "1.7.2"
    location       = azurerm_resource_group.main.location
    zone           = "123"
    project        = "123"
  }
}
# Create a Public IP for the Virtual Machines
resource azurerm_public_ip consul {
  name                = "${var.prefix}consul-mgmt-pip-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"

  tags = {
    Name = "${var.prefix}-consul-public-ip"
  }
}

# linuxbox
resource azurerm_network_interface consul-mgmt-nic {
  name                = "${var.prefix}-consul-mgmt-nic-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name      = "primary"
    subnet_id = azurerm_subnet.mgmt.id
    # private_ip_address_allocation = "Static"
    # private_ip_address            = var.consulIp
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.consul.id
  }

  tags = {
    Name        = "${var.environment}-consul-ext-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = "consul"
  }
}
resource azurerm_virtual_machine consul {
  name                = "${var.prefix}-consul-${random_pet.buildSuffix.id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  network_interface_ids = [azurerm_network_interface.consul-mgmt-nic.id]
  vm_size               = var.consulInstanceType

  storage_os_disk {
    name              = "consulOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.consulDiskType
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
    computer_name  = "consul"
    admin_username = var.adminAccountName
    admin_password = var.adminPassword == "" ? random_password.password.result : var.adminPassword
    custom_data    = data.template_file.consul_onboard.rendered
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
    Name        = "${var.environment}-consul"
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
resource azurerm_virtual_machine_extension consul-run-startup-cmd {
  name                 = "${var.prefix}-consul-run-startup-cmd${random_pet.buildSuffix.id}"
  depends_on           = [azurerm_virtual_machine.consul]
  virtual_machine_id   = azurerm_virtual_machine.consul.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "echo '${base64encode(data.template_file.consul_onboard.rendered)}' >> ./startup.sh && cat ./startup.sh | base64 -d >> ./startup-script.sh && chmod +x ./startup-script.sh && rm ./startup.sh && bash ./startup-script.sh"
        
    }
  SETTINGS

  tags = {
    Name        = "${var.environment}-consul-startup-cmd"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}