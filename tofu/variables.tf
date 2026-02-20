variable "compartment_id" {
  description = "compartment id where to create all resources"
  type        = string
  sensitive   = true
  # no default value, asking user to explicitly set this variable's value. see codingconventions.adoc
}

variable "region" {
  description = "the oci region where resources will be created"
  type        = string
  # no default value, asking user to explicitly set this variable's value. see codingconventions.adoc
  # List of regions: https://docs.cloud.oracle.com/iaas/Content/General/Concepts/regions.htm#ServiceAvailabilityAcrossRegions
}

variable "instances" {
  type = map(object({
    fault_domain  = string
    subnet        =string
  }))
  default = {
    "beta" = {
      fault_domain="FAULT-DOMAIN-1"
      subnet="10.0.0.0/24"
    }
    "prod" = {
      fault_domain="FAULT-DOMAIN-2"
      subnet="10.0.1.0/24"
    }
  }
}