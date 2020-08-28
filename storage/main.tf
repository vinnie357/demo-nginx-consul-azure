provider "azurerm" {
  #version = "=1.38.0"
  version = "=2.0.0"
  features {}
}
resource random_id server {
  byte_length = 2
}