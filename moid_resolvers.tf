# Unified moid accessor locals — callers use these regardless of which workspace
# owns the resource. When the category flag is true the resource map is used;
# when false the data source results are used, filtered by org moid to handle
# policies that share a name across multiple organisations.

locals {
  imc_access_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_access_policy.imc_access_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_access_policy.imc_access_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  bios_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_bios_policy.bios_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_bios_policy.bios_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  boot_precision_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_boot_precision_policy.boot_precision_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_boot_precision_policy.boot_precision_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  vlan_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_fabric_eth_network_policy.vlan_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_eth_network_policy.vlan_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  vsan_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_fabric_fc_network_policy.vsan_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_fc_network_policy.vsan_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  port_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_fabric_port_policy.port_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_port_policy.port_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  switch_control_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_fabric_switch_control_policy.switch_control_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_switch_control_policy.switch_control_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  system_qos_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_fabric_system_qos_policy.system_qos_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_system_qos_policy.system_qos_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  firmware_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_firmware_policy.firmware_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_firmware_policy.firmware_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  local_user_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_iam_end_point_user_policy.local_user_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_iam_end_point_user_policy.local_user_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  ipmi_over_lan_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_ipmioverlan_policy.ipmi_over_lan_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_ipmioverlan_policy.ipmi_over_lan_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  virtual_kvm_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_kvm_policy.virtual_kvm_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_kvm_policy.virtual_kvm_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  network_connectivity_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_networkconfig_policy.network_connectivity_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_networkconfig_policy.network_connectivity_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  ntp_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_ntp_policy.ntp_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_ntp_policy.ntp_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  power_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_power_policy.power_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_power_policy.power_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  smtp_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_smtp_policy.smtp_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_smtp_policy.smtp_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  snmp_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_snmp_policy.snmp_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_snmp_policy.snmp_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  serial_over_lan_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_sol_policy.serial_over_lan_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_sol_policy.serial_over_lan_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  ssh_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_ssh_policy.ssh_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_ssh_policy.ssh_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  storage_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_storage_storage_policy.storage_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_storage_storage_policy.storage_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  syslog_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_syslog_policy.syslog_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_syslog_policy.syslog_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  thermal_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_thermal_policy.thermal_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_thermal_policy.thermal_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  virtual_media_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vmedia_policy.virtual_media_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vmedia_policy.virtual_media_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  lan_connectivity_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vnic_lan_connectivity_policy.lan_connectivity_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_lan_connectivity_policy.lan_connectivity_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  san_connectivity_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vnic_san_connectivity_policy.san_connectivity_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_san_connectivity_policy.san_connectivity_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  # Pools
  uuid_pool_moids = var.manage_intersight_pools ? tomap({
    for k, r in intersight_uuidpool_pool.uuid_pool : k => r.moid
    }) : tomap({
    for k, d in data.intersight_uuidpool_pool.uuid_pool : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  # Templates
  chassis_template_moids = var.manage_intersight_templates ? tomap({
    for k, r in intersight_chassis_profile_template.chassis_template : k => r.moid
    }) : tomap({
    for k, d in data.intersight_chassis_profile_template.chassis_template : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  domain_template_moids = var.manage_intersight_templates ? tomap({
    for k, r in intersight_fabric_switch_cluster_profile_template.domain_template : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_switch_cluster_profile_template.domain_template : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  # vNIC-related policy moids (used by lan_connectivity_vnics and vnic_templates)
  ethernet_adapter_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vnic_eth_adapter_policy.ethernet_adapter_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_eth_adapter_policy.ethernet_adapter_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  ethernet_qos_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vnic_eth_qos_policy.ethernet_qos_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_eth_qos_policy.ethernet_qos_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  ethernet_network_group_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_fabric_eth_network_group_policy.ethernet_network_group_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_eth_network_group_policy.ethernet_network_group_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  ethernet_network_control_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_fabric_eth_network_control_policy.ethernet_network_control_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_eth_network_control_policy.ethernet_network_control_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  ethernet_network_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vnic_eth_network_policy.ethernet_network_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_eth_network_policy.ethernet_network_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  mac_pool_moids = var.manage_intersight_pools ? tomap({
    for k, r in intersight_macpool_pool.mac_pool : k => r.moid
    }) : tomap({
    for k, d in data.intersight_macpool_pool.mac_pool : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  vnic_template_moids = var.manage_intersight_templates ? tomap({
    for k, r in intersight_vnic_vnic_template.vnic_template : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_vnic_template.vnic_template : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  server_profile_template_moids = var.manage_intersight_templates ? tomap({
    for k, r in intersight_server_profile_template.server_profile_template : k => r.moid
    }) : tomap({
    for k, d in data.intersight_server_profile_template.server_profile_template : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  resource_pool_moids = var.manage_intersight_pools ? tomap({
    for k, r in intersight_resourcepool_pool.resource_pool : k => r.moid
    }) : tomap({
    for k, d in data.intersight_resourcepool_pool.resource_pool : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  # FC-related policy and pool moids (used by san_connectivity_vhbas and vhba_templates)
  fc_adapter_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vnic_fc_adapter_policy.fibre_channel_adapter_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_fc_adapter_policy.fibre_channel_adapter_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  fc_network_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vnic_fc_network_policy.fibre_channel_network_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_fc_network_policy.fibre_channel_network_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  fc_qos_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_vnic_fc_qos_policy.fibre_channel_qos_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_fc_qos_policy.fibre_channel_qos_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  wwpn_pool_moids = var.manage_intersight_pools ? tomap({
    for k, r in intersight_fcpool_pool.wwpn_pool : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fcpool_pool.wwpn_pool : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  vhba_template_moids = var.manage_intersight_templates ? tomap({
    for k, r in intersight_vnic_vhba_template.vhba_template : k => r.moid
    }) : tomap({
    for k, d in data.intersight_vnic_vhba_template.vhba_template : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })

  fc_zone_policy_moids = var.manage_intersight_policies ? tomap({
    for k, r in intersight_fabric_fc_zone_policy.fc_zone_policy : k => r.moid
    }) : tomap({
    for k, d in data.intersight_fabric_fc_zone_policy.fc_zone_policy : k => [
      for r in d.results : r.moid
      if try(r.organization[0].moid, "") == local.org_moids[split("/", k)[0]]
    ][0]
  })
}
