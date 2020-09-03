## variables
# project
variable prefix {
  description = "prefix for objects in project"
  default     = "demonginx"
}
variable region {
  description = "(optional) describe your variable"
  default     = "East US 2"
}
variable location {
  default = "eastus2"
}
# admin
variable adminSourceAddress {
  description = "admin source address in cidr"
}
variable adminAccountName {
  description = "admin account"
  default     = "zadmin"
}
variable adminPassword {
  description = "admin password"
  default     = ""
}
variable sshPublicKey {
  description = "contents of admin ssh public key"
}
# tags
variable purpose { default = "public" }
variable environment { default = "dev" } #ex. dev/staging/prod
variable owner { default = "dev" }
variable group { default = "dev" }
variable costcenter { default = "dev" }
variable application { default = "workspace" }
# NETWORK
variable cidr { default = "10.90.0.0/16" }
variable "subnets" {
  type = map(string)
  default = {
    "subnet1" = "10.90.1.0/24"
  }
}
# AKS cluster
variable aksResourceName {
  default = "AKS-NGINX-TF-DEMO"
}
variable aksClusterName {
  default = "kubernetes-aks1"
}
variable aksDnsPrefix {
  default = "kubecluster"
}
variable aksInstanceSize {
  default = "Standard_DS3_v2"
}
variable aksAgentNodeCount {
  default = "1"
}
# aks
variable podCidr {
  description = "k8s pod cidr"
  default     = "10.56.0.0/14"
}

# consul
variable consulInstanceType {
  default = "Standard_DS2_v2"
}
variable consulDiskType {
  default = "Premium_LRS"
}
# nginx
variable nginxInstanceType {
  default = "Standard_DS2_v2"
}
variable nginxDiskType {
  default = "Premium_LRS"
}
variable nginxKey {
  description = "key for nginxplus"
}
variable nginxCert {
  description = "cert for nginxplus"
}
# controller
variable controllerInstallUrl {
  description = "URL path to controller tar file"
}
variable controllerInstanceType {
  default = "Standard_DS4_v2"
}
variable controllerDiskType {
  default = "Premium_LRS"
}
variable controllerDiskSize {
  description = "controller os disk size"
  default     = 80
}
variable controllerLicense {
  description = "license for controller"
  default     = "none"
}
variable controllerBucket {
  description = "name of controller installer bucket"
  default     = "none"
}
variable controllerServiceAccount {
  description = "service account with access to controller installer bucket"
  default     = "none"
}
variable controllerAccount {
  description = "name of controller admin account"
  default     = "admin@nginx-gcp.internal"
}
variable controllerPass {
  description = "pass of controller admin account"
  default     = "admin123!"
}
variable dbPass {
  description = "pass of controller admin account"
  default     = "naaspassword"
}
variable dbUser {
  description = "pass of controller admin account"
  default     = "naas"
}