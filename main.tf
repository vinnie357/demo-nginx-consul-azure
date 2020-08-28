# terraform/providers
provider "azurerm" {
  #version = "=1.38.0"
  version = "=2.1.0"
  features {}
}

# Resource Group
resource azurerm_resource_group main {
  name     = "${var.prefix}_rg_${random_pet.buildSuffix.id}"
  location = var.location
}

resource random_pet buildSuffix {
  keepers = {
    prefix = "${var.prefix}"
  }
  separator = "-"
}
resource random_id server {
  byte_length = 2
}