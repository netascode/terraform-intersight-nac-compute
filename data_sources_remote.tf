# Data sources for cross-workspace moid resolution.
# Each block is only populated when its category flag is false (remotely managed).

# ---------------------------------------------------------------------------
# Policies (manage_intersight_policies = false)
# ---------------------------------------------------------------------------

data "intersight_access_policy" "imc_access_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._imc_access_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_bios_policy" "bios_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._bios_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_boot_precision_policy" "boot_precision_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._boot_precision_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_fabric_eth_network_policy" "vlan_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._vlan_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_fabric_fc_network_policy" "vsan_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._vsan_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_fabric_port_policy" "port_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._port_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_fabric_switch_control_policy" "switch_control_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._switch_control_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_fabric_system_qos_policy" "system_qos_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._system_qos_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_firmware_policy" "firmware_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._firmware_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_iam_end_point_user_policy" "local_user_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._local_user_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_ipmioverlan_policy" "ipmi_over_lan_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._ipmi_over_lan_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_kvm_policy" "virtual_kvm_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._virtual_kvm_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_networkconfig_policy" "network_connectivity_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._network_connectivity_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_ntp_policy" "ntp_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._ntp_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_power_policy" "power_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._power_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_smtp_policy" "smtp_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._smtp_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_snmp_policy" "snmp_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._snmp_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_sol_policy" "serial_over_lan_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._serial_over_lan_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_ssh_policy" "ssh_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._ssh_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_storage_storage_policy" "storage_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._storage_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_syslog_policy" "syslog_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._syslog_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_thermal_policy" "thermal_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._thermal_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_vmedia_policy" "virtual_media_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._virtual_media_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_vnic_lan_connectivity_policy" "lan_connectivity_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._lan_connectivity_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_vnic_san_connectivity_policy" "san_connectivity_policy" {
  for_each = var.manage_intersight_policies ? {} : {
    for k in local._san_connectivity_policy_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Pools (manage_intersight_pools = false)
# ---------------------------------------------------------------------------

data "intersight_uuidpool_pool" "uuid_pool" {
  for_each = var.manage_intersight_pools ? {} : {
    for k in local._uuid_pool_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Templates (manage_intersight_templates = false)
# ---------------------------------------------------------------------------

data "intersight_chassis_profile_template" "chassis_template" {
  for_each = var.manage_intersight_templates ? {} : {
    for k in local._chassis_template_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}

data "intersight_fabric_switch_cluster_profile_template" "domain_template" {
  for_each = var.manage_intersight_templates ? {} : {
    for k in local._domain_template_ref_keys : k => {
      name = split("/", k)[1]
    }
  }
  name = each.value.name
}
