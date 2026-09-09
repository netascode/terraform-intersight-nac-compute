# Data sources for cross-workspace moid resolution AND for individual
# `managed: false` objects within an otherwise-managed category.
#
# Each block's for_each covers every key that some managed object references
# (local._<x>_ref_keys) minus the keys already present in this workspace's own
# resource map (which only ever contains managed:true objects, or is empty when
# the whole category is unmanaged). That subtraction is a no-op when the category
# is off (resource map is empty) and, when the category is on, picks up exactly
# the referenced-but-individually-unmanaged objects.
#
# The remaining condition below is purely a consumer-side optimization to avoid
# firing needless data sources when nothing downstream would consume the result;
# it does not gate on the dependency category itself.
#
# Consumer scope shorthand used in for_each conditions:
#   tmpl_only   = var.manage_intersight_templates
#   prof_or_tmpl = var.manage_intersight_profiles || var.manage_intersight_templates

locals {
  _any_prof_or_tmpl = var.manage_intersight_profiles || var.manage_intersight_templates
}

# ---------------------------------------------------------------------------
# Policies consumed ONLY by templates (server profile templates)
# Activates for referenced-but-unmanaged objects; consumer gate: manage_intersight_templates
# ---------------------------------------------------------------------------

data "intersight_bios_policy" "bios_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._bios_policy_ref_keys, toset(keys(intersight_bios_policy.bios_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_certificatemanagement_policy" "certificate_management_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._certificate_management_policy_ref_keys, toset(keys(intersight_certificatemanagement_policy.certificate_management_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_boot_precision_policy" "boot_precision_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._boot_precision_policy_ref_keys, toset(keys(intersight_boot_precision_policy.boot_precision_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_firmware_policy" "firmware_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._firmware_policy_ref_keys, toset(keys(intersight_firmware_policy.firmware_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_iam_end_point_user_policy" "local_user_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._local_user_policy_ref_keys, toset(keys(intersight_iam_end_point_user_policy.local_user_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_ipmioverlan_policy" "ipmi_over_lan_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._ipmi_over_lan_policy_ref_keys, toset(keys(intersight_ipmioverlan_policy.ipmi_over_lan_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_kvm_policy" "virtual_kvm_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._virtual_kvm_policy_ref_keys, toset(keys(intersight_kvm_policy.virtual_kvm_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_smtp_policy" "smtp_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._smtp_policy_ref_keys, toset(keys(intersight_smtp_policy.smtp_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_sol_policy" "serial_over_lan_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._serial_over_lan_policy_ref_keys, toset(keys(intersight_sol_policy.serial_over_lan_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_compute_scrub_policy" "scrub_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._scrub_policy_ref_keys, toset(keys(intersight_compute_scrub_policy.scrub_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_storage_drive_security_policy" "drive_security_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._drive_security_policy_ref_keys, toset(keys(intersight_storage_drive_security_policy.drive_security_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_adapter_config_policy" "adapter_configuration_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._adapter_configuration_policy_ref_keys, toset(keys(intersight_adapter_config_policy.adapter_configuration_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_deviceconnector_policy" "device_connector_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._device_connector_policy_ref_keys, toset(keys(intersight_deviceconnector_policy.device_connector_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_sdcard_policy" "sd_card_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._sd_card_policy_ref_keys, toset(keys(intersight_sdcard_policy.sd_card_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_memory_policy" "memory_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._memory_policy_ref_keys, toset(keys(intersight_memory_policy.memory_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_memory_persistent_memory_policy" "persistent_memory_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._persistent_memory_policy_ref_keys, toset(keys(intersight_memory_persistent_memory_policy.persistent_memory_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_mac_sec_policy" "mac_sec_policy" {
  for_each = {
    for k in setsubtract(local._mac_sec_policy_ref_keys, toset(keys(intersight_fabric_mac_sec_policy.mac_sec_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_ssh_policy" "ssh_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._ssh_policy_ref_keys, toset(keys(intersight_ssh_policy.ssh_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_storage_storage_policy" "storage_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._storage_policy_ref_keys, toset(keys(intersight_storage_storage_policy.storage_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vmedia_policy" "virtual_media_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._virtual_media_policy_ref_keys, toset(keys(intersight_vmedia_policy.virtual_media_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_iam_ldap_policy" "ldap_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._ldap_policy_ref_keys, toset(keys(intersight_iam_ldap_policy.ldap_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_lan_connectivity_policy" "lan_connectivity_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._lan_connectivity_policy_ref_keys, toset(keys(intersight_vnic_lan_connectivity_policy.lan_connectivity_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_san_connectivity_policy" "san_connectivity_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._san_connectivity_policy_ref_keys, toset(keys(intersight_vnic_san_connectivity_policy.san_connectivity_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Policies consumed by BOTH profiles and templates
# Activates for referenced-but-unmanaged objects; consumer gate: (manage_intersight_profiles || manage_intersight_templates)
# ---------------------------------------------------------------------------

data "intersight_access_policy" "imc_access_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._imc_access_policy_ref_keys, toset(keys(intersight_access_policy.imc_access_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_eth_network_policy" "vlan_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._vlan_policy_ref_keys, toset(keys(intersight_fabric_eth_network_policy.vlan_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_fc_network_policy" "vsan_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._vsan_policy_ref_keys, toset(keys(intersight_fabric_fc_network_policy.vsan_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_port_policy" "port_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._port_policy_ref_keys, toset(keys(intersight_fabric_port_policy.port_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_switch_control_policy" "switch_control_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._switch_control_policy_ref_keys, toset(keys(intersight_fabric_switch_control_policy.switch_control_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_system_qos_policy" "system_qos_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._system_qos_policy_ref_keys, toset(keys(intersight_fabric_system_qos_policy.system_qos_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_networkconfig_policy" "network_connectivity_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._network_connectivity_policy_ref_keys, toset(keys(intersight_networkconfig_policy.network_connectivity_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_ntp_policy" "ntp_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._ntp_policy_ref_keys, toset(keys(intersight_ntp_policy.ntp_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_power_policy" "power_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._power_policy_ref_keys, toset(keys(intersight_power_policy.power_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_snmp_policy" "snmp_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._snmp_policy_ref_keys, toset(keys(intersight_snmp_policy.snmp_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_syslog_policy" "syslog_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._syslog_policy_ref_keys, toset(keys(intersight_syslog_policy.syslog_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_thermal_policy" "thermal_policy" {
  for_each = !local._any_prof_or_tmpl ? {} : {
    for k in setsubtract(local._thermal_policy_ref_keys, toset(keys(intersight_thermal_policy.thermal_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Pools (manage_intersight_pools = false)
# Activates for referenced-but-unmanaged objects; consumer gate: manage_intersight_templates
# ---------------------------------------------------------------------------

data "intersight_uuidpool_pool" "uuid_pool" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._uuid_pool_ref_keys, toset(keys(intersight_uuidpool_pool.uuid_pool))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_macpool_pool" "mac_pool" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._mac_pool_ref_keys, toset(keys(intersight_macpool_pool.mac_pool))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# vNIC-related policies consumed by vnic_templates and lan_connectivity_vnics
# Activates for referenced-but-unmanaged objects; consumer gate: manage_intersight_templates
# ---------------------------------------------------------------------------

data "intersight_vnic_eth_adapter_policy" "ethernet_adapter_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._ethernet_adapter_policy_ref_keys, toset(keys(intersight_vnic_eth_adapter_policy.ethernet_adapter_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_eth_qos_policy" "ethernet_qos_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._ethernet_qos_policy_ref_keys, toset(keys(intersight_vnic_eth_qos_policy.ethernet_qos_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_eth_network_group_policy" "ethernet_network_group_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._ethernet_network_group_policy_ref_keys, toset(keys(intersight_fabric_eth_network_group_policy.ethernet_network_group_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_eth_network_control_policy" "ethernet_network_control_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._ethernet_network_control_policy_ref_keys, toset(keys(intersight_fabric_eth_network_control_policy.ethernet_network_control_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_eth_network_policy" "ethernet_network_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._ethernet_network_policy_ref_keys, toset(keys(intersight_vnic_eth_network_policy.ethernet_network_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Templates (manage_intersight_templates = false)
# Activates for referenced-but-unmanaged objects; consumer gate: manage_intersight_profiles
# ---------------------------------------------------------------------------

data "intersight_chassis_profile_template" "chassis_template" {
  for_each = !var.manage_intersight_profiles ? {} : {
    for k in setsubtract(local._chassis_template_ref_keys, toset(keys(intersight_chassis_profile_template.chassis_template))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_switch_cluster_profile_template" "domain_template" {
  for_each = !var.manage_intersight_profiles ? {} : {
    for k in setsubtract(local._domain_template_ref_keys, toset(keys(intersight_fabric_switch_cluster_profile_template.domain_template))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_vnic_template" "vnic_template" {
  for_each = !var.manage_intersight_policies ? {} : {
    for k in setsubtract(local._vnic_template_ref_keys, toset(keys(intersight_vnic_vnic_template.vnic_template))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Templates consumed by servers (manage_intersight_templates = false)
# Activates for referenced-but-unmanaged objects; consumer gate: manage_servers
# ---------------------------------------------------------------------------

data "intersight_server_profile_template" "server_profile_template" {
  for_each = !var.manage_servers ? {} : {
    for k in setsubtract(local._server_profile_template_ref_keys, toset(keys(intersight_server_profile_template.server_profile_template))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Pools consumed by servers (manage_intersight_pools = false)
# Activates for referenced-but-unmanaged objects; consumer gate: manage_servers
# ---------------------------------------------------------------------------

data "intersight_resourcepool_pool" "resource_pool" {
  for_each = !var.manage_servers ? {} : {
    for k in setsubtract(local._resource_pool_ref_keys, toset(keys(intersight_resourcepool_pool.resource_pool))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# Policies consumed by pools (manage_intersight_policies = false)
# Activates for referenced-but-unmanaged objects; consumer gate: manage_intersight_pools
# ---------------------------------------------------------------------------

data "intersight_resourcepool_qualification_policy" "qualification_policy" {
  for_each = !var.manage_intersight_pools ? {} : {
    for k in setsubtract(local._qualification_policy_ref_keys, toset(keys(intersight_resourcepool_qualification_policy.qualification_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

# ---------------------------------------------------------------------------
# FC policies and WWPN pool consumed by vhba_templates and san_connectivity_vhbas
# Activates for referenced-but-unmanaged objects; consumer gate: manage_intersight_templates
# ---------------------------------------------------------------------------

data "intersight_vnic_fc_adapter_policy" "fibre_channel_adapter_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._fc_adapter_policy_ref_keys, toset(keys(intersight_vnic_fc_adapter_policy.fibre_channel_adapter_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_fc_network_policy" "fibre_channel_network_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._fc_network_policy_ref_keys, toset(keys(intersight_vnic_fc_network_policy.fibre_channel_network_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_fc_qos_policy" "fibre_channel_qos_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._fc_qos_policy_ref_keys, toset(keys(intersight_vnic_fc_qos_policy.fibre_channel_qos_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fcpool_pool" "wwpn_pool" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._wwpn_pool_ref_keys, toset(keys(intersight_fcpool_pool.wwpn_pool))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_vhba_template" "vhba_template" {
  for_each = !var.manage_intersight_policies ? {} : {
    for k in setsubtract(local._vhba_template_ref_keys, toset(keys(intersight_vnic_vhba_template.vhba_template))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_fabric_fc_zone_policy" "fc_zone_policy" {
  for_each = {
    for k in setsubtract(local._fc_zone_policy_ref_keys, toset(keys(intersight_fabric_fc_zone_policy.fc_zone_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_ippool_pool" "ip_pool" {
  for_each = !var.manage_intersight_policies ? {} : {
    for k in setsubtract(local._ip_pool_ref_keys, toset(keys(intersight_ippool_pool.ip_pool))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_iscsi_adapter_policy" "iscsi_adapter_policy" {
  for_each = {
    for k in setsubtract(local._iscsi_adapter_policy_ref_keys, toset(keys(intersight_vnic_iscsi_adapter_policy.iscsi_adapter_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_iscsi_static_target_policy" "iscsi_static_target_policy" {
  for_each = {
    for k in setsubtract(local._iscsi_static_target_policy_ref_keys, toset(keys(intersight_vnic_iscsi_static_target_policy.iscsi_static_target_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}

data "intersight_vnic_iscsi_boot_policy" "iscsi_boot_policy" {
  for_each = !var.manage_intersight_templates ? {} : {
    for k in setsubtract(local._iscsi_boot_policy_ref_keys, toset(keys(intersight_vnic_iscsi_boot_policy.iscsi_boot_policy))) : k => { name = split("/", k)[1] }
  }
  name = each.value.name
}
