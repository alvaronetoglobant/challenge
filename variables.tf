variable "name" {
  description = "(Required) Specifies the name of the resources. Changing this forces a new resource to be created."
  type        = string
  default     = "challenge"
}

variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
  default     = "eastus"
}



