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
	for_each = var.instances
	#Required
	compartment_id = var.compartment_id
	vcn_id = oci_core_vcn.vcn.id

	#Optional
	cidr_block = each.value.subnet
	display_name = "subnet-${each.key}"
	dns_label = each.key
	route_table_id = oci_core_route_table.rt.id
}

resource "oci_core_instance" "instance" {
	for_each = var.instances
	#Required
	availability_domain = "KqKw:EU-MADRID-1-AD-1"
	compartment_id = var.compartment_id

	#Optional
	display_name = each.key
	fault_domain = each.value.fault_domain
	source_details {
		#Required
		source_id = data.oci_core_images.img.images[0].id
		source_type = "image"
		boot_volume_size_in_gbs = "100"
	}
	shape = "VM.Standard.A1.Flex"
	shape_config {

		#Optional
		memory_in_gbs = 12
		ocpus = 2
	}

	create_vnic_details {
		subnet_id = oci_core_subnet.subnet[each.key].id
		assign_public_ip = true
	}
	metadata = {
	  ssh_authorized_keys = file("/mnt/c/Users/a2167/.ssh/id_rsa.pub")
	}
}		

data "oci_core_images" "img" {
	#Required
	compartment_id = var.compartment_id

	#Optional
	operating_system = "Canonical Ubuntu"
	operating_system_version = "24.04"
	shape = "VM.Standard.A1.Flex"	
}