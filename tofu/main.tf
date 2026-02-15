terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "8.1.0"
    }
  }
}

provider "oci" {
  region = var.region
  //auth                = "SecurityToken"
  //config_file_profile = "learn-terraform"
}

resource "oci_core_vcn" "vcn" {
	#Required
	compartment_id = var.compartment_id

	#Optional
	cidr_blocks = ["10.0.0.0/16"]
	display_name = "vcn"
	dns_label = "vcn"
}

resource "oci_core_internet_gateway" "gtw" {
	#Required
	compartment_id = var.compartment_id
	vcn_id = oci_core_vcn.vcn.id

	#Optional
	enabled = true
	display_name = "gtw"
}


resource "oci_core_route_table" "rt" {
	#Required
	compartment_id = var.compartment_id
	vcn_id = oci_core_vcn.vcn.id

	#Optional
	display_name = "rt"
	route_rules {
		#Required
		network_entity_id = oci_core_internet_gateway.gtw.id

		#Optional
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
	}
}

resource "oci_core_security_list" "fw" {
	#Required
	compartment_id = var.compartment_id
	vcn_id = oci_core_vcn.vcn.id

	#Optional
	display_name = "fw"
	egress_security_rules {
		#Required
		destination = "0.0.0.0/0"
		protocol = "all"

		#Optional		
	}
	ingress_security_rules {
		#Required
		protocol = "6"
		source = "0.0.0.0/0"

		#Optional
		tcp_options {

			#Optional
			max = 22
			min = 22
		}
		
	}
}

resource "oci_core_subnet" "subnet" {
	#Required
	compartment_id = var.compartment_id
	vcn_id = oci_core_vcn.vcn.id

	#Optional
	cidr_block = "10.0.0.0/24"
	display_name = "subnet"
	dns_label = "subnet"
	route_table_id = oci_core_route_table.rt.id
}
