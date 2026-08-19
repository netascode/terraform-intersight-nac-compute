# Data sources for cross-workspace moid resolution.
# Each block activates only when both conditions hold:
#   1. The dependency category is NOT managed locally (flag = false)
#   2. At least one category that consumes this resource IS managed locally
#
# Consumer scope shorthand used in for_each conditions:
#   tmpl_only   = var.manage_intersight_templates
#   prof_or_tmpl = var.manage_intersight_profiles || var.manage_intersight_templates

locals {
  _any_prof_or_tmpl = var.manage_intersight_profiles || var.manage_intersight_templates
}

# ---------------------------------------------------------------------------
# Policies consumed ONLY by templates (server profile templates)
# Activate when: !manage_intersight_policies && manage_intersight_templates
# ---------------------------------------------------------------------------

data "intersight_bios_policy" "bios_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._bios_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_boot_precision_policy" "boot_precision_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._boot_precision_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_firmware_policy" "firmware_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._firmware_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_iam_end_point_user_policy" "local_user_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._local_user_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_ipmioverlan_policy" "ipmi_over_lan_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._ipmi_over_lan_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_kvm_policy" "virtual_kvm_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._virtual_kvm_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_smtp_policy" "smtp_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._smtp_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_sol_policy" "serial_over_lan_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._serial_over_lan_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_ssh_policy" "ssh_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._ssh_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_storage_storage_policy" "storage_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._storage_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vmedia_policy" "virtual_media_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._virtual_media_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_lan_connectivity_policy" "lan_connectivity_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._lan_connectivity_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_san_connectivity_policy" "san_connectivity_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._san_connectivity_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Policies consumed by BOTH profiles and templates
# Activate when: !manage_intersight_policies && (manage_intersight_profiles || manage_intersight_templates)
# ---------------------------------------------------------------------------

data "intersight_access_policy" "imc_access_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._imc_access_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_eth_network_policy" "vlan_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._vlan_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_fc_network_policy" "vsan_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._vsan_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_port_policy" "port_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._port_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_switch_control_policy" "switch_control_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._switch_control_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_system_qos_policy" "system_qos_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._system_qos_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_networkconfig_policy" "network_connectivity_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._network_connectivity_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_ntp_policy" "ntp_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._ntp_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_power_policy" "power_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._power_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_snmp_policy" "snmp_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._snmp_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_syslog_policy" "syslog_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._syslog_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_thermal_policy" "thermal_policy" {
  for_each = (var.manage_intersight_policies || !local._any_prof_or_tmpl) ? {} : {
    for k in local._thermal_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Pools (manage_intersight_pools = false)
# Activate when: !manage_intersight_pools && manage_intersight_templates
# ---------------------------------------------------------------------------

data "intersight_uuidpool_pool" "uuid_pool" {
  for_each = (var.manage_intersight_pools || !var.manage_intersight_templates) ? {} : {
    for k in local._uuid_pool_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_macpool_pool" "mac_pool" {
  for_each = (var.manage_intersight_pools || !var.manage_intersight_templates) ? {} : {
    for k in local._mac_pool_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# vNIC-related policies consumed by vnic_templates and lan_connectivity_vnics
# Activate when: !manage_intersight_policies && manage_intersight_templates
# ---------------------------------------------------------------------------

data "intersight_vnic_eth_adapter_policy" "ethernet_adapter_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._ethernet_adapter_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_eth_qos_policy" "ethernet_qos_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._ethernet_qos_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_eth_network_group_policy" "ethernet_network_group_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._ethernet_network_group_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_eth_network_control_policy" "ethernet_network_control_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._ethernet_network_control_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_eth_network_policy" "ethernet_network_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._ethernet_network_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Templates (manage_intersight_templates = false)
# Activate when: !manage_intersight_templates && manage_intersight_profiles
# ---------------------------------------------------------------------------

data "intersight_chassis_profile_template" "chassis_template" {
  for_each = (var.manage_intersight_templates || !var.manage_intersight_profiles) ? {} : {
    for k in local._chassis_template_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_switch_cluster_profile_template" "domain_template" {
  for_each = (var.manage_intersight_templates || !var.manage_intersight_profiles) ? {} : {
    for k in local._domain_template_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_vnic_template" "vnic_template" {
  for_each = (var.manage_intersight_templates || !var.manage_intersight_policies) ? {} : {
    for k in local._vnic_template_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Templates consumed by servers (manage_intersight_templates = false)
# Activate when: !manage_intersight_templates && manage_servers
# ---------------------------------------------------------------------------

data "intersight_server_profile_template" "server_profile_template" {
  for_each = (var.manage_intersight_templates || !var.manage_servers) ? {} : {
    for k in local._server_profile_template_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Pools consumed by servers (manage_intersight_pools = false)
# Activate when: !manage_intersight_pools && manage_servers
# ---------------------------------------------------------------------------

data "intersight_resourcepool_pool" "resource_pool" {
  for_each = (var.manage_intersight_pools || !var.manage_servers) ? {} : {
    for k in local._resource_pool_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# FC policies and WWPN pool consumed by vhba_templates and san_connectivity_vhbas
# Activate when: !manage_intersight_policies && manage_intersight_templates
# ---------------------------------------------------------------------------

data "intersight_vnic_fc_adapter_policy" "fibre_channel_adapter_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._fc_adapter_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_fc_network_policy" "fibre_channel_network_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._fc_network_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_fc_qos_policy" "fibre_channel_qos_policy" {
  for_each = (var.manage_intersight_policies || !var.manage_intersight_templates) ? {} : {
    for k in local._fc_qos_policy_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fcpool_pool" "wwpn_pool" {
  for_each = (var.manage_intersight_pools || !var.manage_intersight_templates) ? {} : {
    for k in local._wwpn_pool_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_vhba_template" "vhba_template" {
  for_each = (var.manage_intersight_templates || !var.manage_intersight_policies) ? {} : {
    for k in local._vhba_template_ref_keys : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}
