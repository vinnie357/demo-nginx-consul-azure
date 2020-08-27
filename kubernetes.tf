resource "azurerm_resource_group" "k8s" {
  name     = var.resourceName
  location = var.location
}
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.clusterName
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = var.dnsprefix
  default_node_pool {
    name       = "default"
    node_count = var.agentnode
    vm_size    = var.size
  }
  identity {
    type = "SystemAssigned"
  }
  #service_principal {
  #  client_id     = azuread_service_principal.app.id
  #  client_secret = random_password.sp_password.result
  #}
}