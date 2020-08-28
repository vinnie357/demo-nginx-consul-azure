# outputs

# hcl
# rg
output bucketRgName {
  value = azurerm_resource_group.controller-demo-rg.name
}
output bucketRgLocation {
  value = azurerm_resource_group.controller-demo-rg.location
}
# bucket
output bucketName {
  value = azurerm_storage_container.controller-demo-storage-container.name
}
# object url
output file_url {
  value = azurerm_storage_blob.controller-file.url
}
output sas_url_query_string {
  value = data.azurerm_storage_account_sas.controller-sas.sas
}
# json
output bucketInfo {
  value = <<-EOF
  {
  "rg":"${azurerm_resource_group.controller-demo-rg.name}",
  "location": "${azurerm_resource_group.controller-demo-rg.location}",
  "name": "${azurerm_storage_container.controller-demo-storage-container.name}",
  "fileUrl": "${azurerm_storage_blob.controller-file.url}${data.azurerm_storage_account_sas.controller-sas.sas}"
  }
  EOF
}
