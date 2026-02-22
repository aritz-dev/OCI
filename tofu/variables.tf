# variables.tf
variable "compartment_id" {
  description = "compartment id where to create all resources"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "the oci region where resources will be created"
  type        = string
}

variable "instances" {
  type = map(object({
    fault_domain = string
    subnet_cidr  = string
  }))
  default = {
    beta = {
      fault_domain = "FAULT-DOMAIN-1"
      subnet_cidr  = "10.0.0.0/24"
    }
    prod = {
      fault_domain = "FAULT-DOMAIN-2"
      subnet_cidr  = "10.0.1.0/24"
    }
  }
}