# variables
variable "resourceName" {
  default = "AKS-NGINX-TF-DEMO"
}
variable "clusterName" {
  default = "kubernetes-aks1"
}
variable "location" {
  default = "northeurope"
}
variable "dnsPrefix" {
  default = "kubecluster"
}
variable "instanceSize" {
  default = "Standard_D2_v2"
}
variable "agentNodes" {
  default = "1"
}