# variables
# admin
variable adminSrcAddr {
  description = "admin src address in cidr"
}
variable adminAccount {
  description = "admin account"
}
variable adminPass {
  description = "admin password"
}
# aks
variable podCidr {
  description = "k8s pod cidr"
  default     = "10.56.0.0/14"
}

# consul

# nginx
variable nginxKey {
  description = "key for nginxplus"
}
variable nginxCert {
  description = "cert for nginxplus"
}
# controller
variable controllerLicense {
  description = "license for controller"
  default     = "none"
}
variable controllerBucket {
  description = "name of controller installer bucket"
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