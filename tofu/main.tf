# main.tf
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
}

# ── Red ──────────────────────────────────────────────────────────────────────

resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "vcn"
  dns_label      = "vcn"
}

resource "oci_core_internet_gateway" "gtw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  enabled        = true
  display_name   = "gtw"
}

resource "oci_core_route_table" "rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.gtw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "fw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "fw"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = "1"        # ICMP
    source   = "0.0.0.0/0"
    icmp_options {
      type = 8            # (ping)
    }
  }
}

resource "oci_core_subnet" "subnet" {
  for_each = var.instances

  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.vcn.id
  cidr_block        = each.value.subnet_cidr
  display_name      = "subnet-${each.key}"
  dns_label         = each.key
  route_table_id    = oci_core_route_table.rt.id
  security_list_ids = [oci_core_security_list.fw.id]
}

# ── Imagen ───────────────────────────────────────────────────────────────────

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ── Instancias ───────────────────────────────────────────────────────────────

resource "oci_core_instance" "instance" {
  for_each = var.instances

  display_name        = each.key
  compartment_id      = var.compartment_id
  availability_domain = "KqKw:EU-MADRID-1-AD-1"
  fault_domain        = each.value.fault_domain

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = 100 
  }
  shape = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet[each.key].id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file("/mnt/c/Users/a2167/.ssh/id_rsa.pub")
  }
}