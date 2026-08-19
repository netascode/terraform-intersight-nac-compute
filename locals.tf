locals {
  # ---------------------------------------------------------------------------
  # Tag-match helper — evaluates whether an object's tags satisfy all filters.
  # filter_tags: list of "key=value" strings (all must match — AND semantics)
  # obj_tags:    list of {key, value} objects from the data model
  # Returns true when filter_tags is empty OR every filter tag is found in obj_tags.
  # ---------------------------------------------------------------------------
  _tag_filter_intersight_orgs = [
    for t in var.managed_intersight_organization_tags :
    { key = split("=", t)[0], value = split("=", t)[1] }
  ]
  _tag_filter_intersight_domains = [
    for t in var.managed_intersight_domain_tags :
    { key = split("=", t)[0], value = split("=", t)[1] }
  ]
  _tag_filter_intersight_chassis = [
    for t in var.managed_intersight_chassis_tags :
    { key = split("=", t)[0], value = split("=", t)[1] }
  ]
  _tag_filter_servers = [
    for t in var.managed_server_tags :
    { key = split("=", t)[0], value = split("=", t)[1] }
  ]

  # ---------------------------------------------------------------------------
  # filtered_intersight_organizations — orgs that pass the name/tag filters.
  # An org is included when:
  #   - both lists are empty (include all), OR
  #   - its name is in managed_intersight_organizations, OR
  #   - it carries ALL tags in managed_intersight_organization_tags
  # ---------------------------------------------------------------------------
  filtered_intersight_organizations = [
    for org in try(local.intersight.organizations, []) : org
    if(
      length(var.managed_intersight_organizations) == 0
      && length(var.managed_intersight_organization_tags) == 0
      ) || contains(var.managed_intersight_organizations, org.name
      ) || (
      length(local._tag_filter_intersight_orgs) > 0
      && alltrue([
        for tf in local._tag_filter_intersight_orgs :
        anytrue([for ot in try(org.tags, []) : ot.key == tf.key && ot.value == tf.value])
      ])
    )
  ]

  # ---------------------------------------------------------------------------
  # filtered_servers — servers scoped to this workspace (Intersight-managed only).
  # A server is included when:
  #   - both lists are empty (include all), OR
  #   - its name is in managed_servers, OR
  #   - it carries ALL tags in managed_server_tags
  # Only servers with managed_by=intersight are considered.
  # ---------------------------------------------------------------------------
  filtered_servers = [
    for server in try(local.compute.servers, []) : server
    if try(server.provisioning.managed_by, "") == "intersight"
    && (
      (length(var.managed_servers) == 0 && length(var.managed_server_tags) == 0)
      || contains(var.managed_servers, server.name)
      || (
        length(local._tag_filter_servers) > 0
        && alltrue([
          for tf in local._tag_filter_servers :
          anytrue([for ot in try(server.tags, []) : ot.key == tf.key && ot.value == tf.value])
        ])
      )
    )
  ]
}

locals {
  # ---------------------------------------------------------------------------
  # Reference collection locals — collect all keys that consuming resources
  # actually reference, so data sources only look up what is needed.
  # ---------------------------------------------------------------------------

  # Policies (manage_intersight_policies)
  _imc_access_policy_ref_keys = toset(compact(flatten([
    [for p in local.chassis_profiles : p.imc_access_policy_key],
    [for t in local.chassis_templates : t.imc_access_policy_key],
    [for t in local.server_templates : t.imc_access_policy_key],
  ])))
  _bios_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.bios_policy_key],
  ])))
  _boot_precision_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.boot_order_policy_key],
  ])))
  _vlan_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.vlan_policy_key],
    [for st in local.domain_switch_profile_templates : st.vlan_policy_key],
  ])))
  _vsan_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.vsan_policy_key],
    [for st in local.domain_switch_profile_templates : st.vsan_policy_key],
  ])))
  _port_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.port_policy_key],
    [for st in local.domain_switch_profile_templates : st.port_policy_key],
  ])))
  _switch_control_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.switch_control_policy_key],
    [for st in local.domain_switch_profile_templates : st.switch_control_policy_key],
  ])))
  _system_qos_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.system_qos_policy_key],
    [for st in local.domain_switch_profile_templates : st.system_qos_policy_key],
  ])))
  _firmware_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.firmware_policy_key],
  ])))
  _local_user_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.local_user_policy_key],
  ])))
  _ipmi_over_lan_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.ipmi_over_lan_policy_key],
  ])))
  _virtual_kvm_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.virtual_kvm_policy_key],
  ])))
  _network_connectivity_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.network_connectivity_policy_key],
    [for st in local.domain_switch_profile_templates : st.network_connectivity_policy_key],
    [for t in local.server_templates : t.network_connectivity_policy_key],
  ])))
  _ntp_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.ntp_policy_key],
    [for st in local.domain_switch_profile_templates : st.ntp_policy_key],
    [for t in local.server_templates : t.ntp_policy_key],
  ])))
  _power_policy_ref_keys = toset(compact(flatten([
    [for p in local.chassis_profiles : p.power_policy_key],
    [for t in local.chassis_templates : t.power_policy_key],
    [for t in local.server_templates : t.power_policy_key],
  ])))
  _smtp_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.smtp_policy_key],
  ])))
  _snmp_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.snmp_policy_key],
    [for st in local.domain_switch_profile_templates : st.snmp_policy_key],
    [for p in local.chassis_profiles : p.snmp_policy_key],
    [for t in local.chassis_templates : t.snmp_policy_key],
    [for t in local.server_templates : t.snmp_policy_key],
  ])))
  _serial_over_lan_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.serial_over_lan_policy_key],
  ])))
  _ssh_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.ssh_policy_key],
  ])))
  _storage_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.storage_policy_key],
  ])))
  _syslog_policy_ref_keys = toset(compact(flatten([
    [for sp in local.domain_switch_profiles : sp.syslog_policy_key],
    [for st in local.domain_switch_profile_templates : st.syslog_policy_key],
    [for t in local.server_templates : t.syslog_policy_key],
  ])))
  _thermal_policy_ref_keys = toset(compact(flatten([
    [for p in local.chassis_profiles : p.thermal_policy_key],
    [for t in local.chassis_templates : t.thermal_policy_key],
    [for t in local.server_templates : t.thermal_policy_key],
  ])))
  _virtual_media_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.virtual_media_policy_key],
  ])))
  _lan_connectivity_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.lan_connectivity_policy_key],
  ])))
  _san_connectivity_policy_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.san_connectivity_policy_key],
  ])))

  # Pools (manage_intersight_pools)
  _uuid_pool_ref_keys = toset(compact(flatten([
    [for t in local.server_templates : t.uuid_pool_key],
  ])))

  _ethernet_adapter_policy_ref_keys = toset(compact(flatten([
    [for v in local.lan_connectivity_vnics : v.ethernet_adapter_policy_key],
    [for t in local.vnic_templates : t.ethernet_adapter_policy_key],
  ])))
  _ethernet_qos_policy_ref_keys = toset(compact(flatten([
    [for v in local.lan_connectivity_vnics : v.ethernet_qos_policy_key],
    [for t in local.vnic_templates : t.ethernet_qos_policy_key],
  ])))
  _ethernet_network_group_policy_ref_keys = toset(compact(flatten([
    [for v in local.lan_connectivity_vnics : v.ethernet_network_group_policy_key],
    [for t in local.vnic_templates : t.ethernet_network_group_policy_key],
  ])))
  _ethernet_network_control_policy_ref_keys = toset(compact(flatten([
    [for v in local.lan_connectivity_vnics : v.ethernet_network_control_policy_key],
    [for t in local.vnic_templates : t.ethernet_network_control_policy_key],
  ])))
  _ethernet_network_policy_ref_keys = toset(compact(flatten([
    [for v in local.lan_connectivity_vnics : v.ethernet_network_policy_key],
    [for t in local.vnic_templates : t.ethernet_network_policy_key],
  ])))
  _mac_pool_ref_keys = toset(compact(flatten([
    [for v in local.lan_connectivity_vnics : v.mac_pool_key],
    [for t in local.vnic_templates : t.mac_pool_key],
  ])))
  _vnic_template_ref_keys = toset(compact(flatten([
    [for v in local.lan_connectivity_vnics : try(v.vnic_template_key, null)],
  ])))

  # Templates (manage_intersight_templates)
  _chassis_template_ref_keys = toset(compact(flatten([
    [for p in local.chassis_profiles : p.chassis_template_key],
  ])))
  _domain_template_ref_keys = toset(compact(flatten([
    [for p in local.domain_profiles : p.ucs_domain_template_key],
  ])))
  _server_profile_template_ref_keys = toset(compact(flatten([
    [for s in local.intersight_servers : s.profile_template_key],
  ])))
  _resource_pool_ref_keys = toset(compact(flatten([
    [for s in local.intersight_servers : s.resource_pool_key],
  ])))
}
