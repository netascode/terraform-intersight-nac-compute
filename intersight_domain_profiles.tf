locals {
  domain_profiles = flatten([
    for org in try(local.intersight.organizations, []) : [
      for profile in try(org.profiles.domain, []) :
      try(profile.managed, true) ? [{
        key                             = format("%s/%s", org.name, profile.name)
        org_name                        = org.name
        name                            = profile.name
        description                     = try(profile.description, local.defaults.compute.intersight.organizations.profiles.domain.description, "")
        target_platform                 = try(profile.target_platform, local.defaults.compute.intersight.organizations.profiles.domain.target_platform)
        tags                            = try(profile.tags, [])
        serial_numbers                  = try(profile.serial_numbers, [])
        ucs_domain_template_key         = try(profile.ucs_domain_template, null) != null ? format("%s/%s", org.name, profile.ucs_domain_template) : null
        switch_a_port_policy_key        = try(profile.switch_a_port_policy, null) != null ? format("%s/%s", org.name, profile.switch_a_port_policy) : null
        switch_b_port_policy_key        = try(profile.switch_b_port_policy, null) != null ? format("%s/%s", org.name, profile.switch_b_port_policy) : null
        switch_control_policy_key       = try(profile.switch_control_policy, null) != null ? format("%s/%s", org.name, profile.switch_control_policy) : null
        system_qos_policy_key           = try(profile.system_qos_policy, null) != null ? format("%s/%s", org.name, profile.system_qos_policy) : null
        vlan_policy_key                 = try(profile.vlan_policy, null) != null ? format("%s/%s", org.name, profile.vlan_policy) : null
        vsan_policy_key                 = try(profile.vsan_policy, null) != null ? format("%s/%s", org.name, profile.vsan_policy) : null
        ntp_policy_key                  = try(profile.ntp_policy, null) != null ? format("%s/%s", org.name, profile.ntp_policy) : null
        snmp_policy_key                 = try(profile.snmp_policy, null) != null ? format("%s/%s", org.name, profile.snmp_policy) : null
        syslog_policy_key               = try(profile.syslog_policy, null) != null ? format("%s/%s", org.name, profile.syslog_policy) : null
        network_connectivity_policy_key = try(profile.network_connectivity_policy, null) != null ? format("%s/%s", org.name, profile.network_connectivity_policy) : null
      }] : []
    ]
  ])

  domain_switch_profiles = flatten([
    for profile in local.domain_profiles : [
      {
        key                             = format("%s/A", profile.key)
        cluster_key                     = profile.key
        name                            = format("%s-A", profile.name)
        switch_id                       = "A"
        serial_number                   = try(profile.serial_numbers[0], null)
        port_policy_key                 = profile.switch_a_port_policy_key
        switch_control_policy_key       = profile.switch_control_policy_key
        system_qos_policy_key           = profile.system_qos_policy_key
        vlan_policy_key                 = profile.vlan_policy_key
        vsan_policy_key                 = profile.vsan_policy_key
        ntp_policy_key                  = profile.ntp_policy_key
        snmp_policy_key                 = profile.snmp_policy_key
        syslog_policy_key               = profile.syslog_policy_key
        network_connectivity_policy_key = profile.network_connectivity_policy_key
      },
      {
        key                             = format("%s/B", profile.key)
        cluster_key                     = profile.key
        name                            = format("%s-B", profile.name)
        switch_id                       = "B"
        serial_number                   = try(profile.serial_numbers[1], null)
        port_policy_key                 = profile.switch_b_port_policy_key
        switch_control_policy_key       = profile.switch_control_policy_key
        system_qos_policy_key           = profile.system_qos_policy_key
        vlan_policy_key                 = profile.vlan_policy_key
        vsan_policy_key                 = profile.vsan_policy_key
        ntp_policy_key                  = profile.ntp_policy_key
        snmp_policy_key                 = profile.snmp_policy_key
        syslog_policy_key               = profile.syslog_policy_key
        network_connectivity_policy_key = profile.network_connectivity_policy_key
      },
    ]
  ])

  # Collect unique FI serial numbers needing lookup
  domain_fi_serials = toset([
    for sp in local.domain_switch_profiles : sp.serial_number
    if sp.serial_number != null
  ])
}

data "intersight_network_element_summary" "fi" {
  for_each = local.domain_fi_serials
  serial   = each.key
}

resource "intersight_fabric_switch_cluster_profile" "domain_profile" {
  for_each = { for p in local.domain_profiles : p.key => p }

  name            = each.value.name
  description     = each.value.description
  target_platform = each.value.target_platform

  dynamic "src_template" {
    for_each = each.value.ucs_domain_template_key != null ? [1] : []
    content {
      object_type = "fabric.SwitchClusterProfileTemplate"
      moid        = intersight_fabric_switch_cluster_profile_template.domain_template[each.value.ucs_domain_template_key].moid
    }
  }

  dynamic "tags" {
    for_each = each.value.tags
    content {
      key   = tags.value.key
      value = tags.value.value
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}

resource "intersight_fabric_switch_profile" "domain_switch_profile" {
  for_each = { for sp in local.domain_switch_profiles : sp.key => sp }

  name      = each.value.name
  switch_id = each.value.switch_id

  switch_cluster_profile {
    object_type = "fabric.SwitchClusterProfile"
    moid        = intersight_fabric_switch_cluster_profile.domain_profile[each.value.cluster_key].moid
  }

  dynamic "assigned_switch" {
    for_each = each.value.serial_number != null ? [1] : []
    content {
      object_type = "network.Element"
      moid        = data.intersight_network_element_summary.fi[each.value.serial_number].results[0].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.port_policy_key != null ? [1] : []
    content {
      object_type = "fabric.PortPolicy"
      moid        = intersight_fabric_port_policy.port_policy[each.value.port_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.switch_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.SwitchControlPolicy"
      moid        = intersight_fabric_switch_control_policy.switch_control_policy[each.value.switch_control_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.system_qos_policy_key != null ? [1] : []
    content {
      object_type = "fabric.SystemQosPolicy"
      moid        = intersight_fabric_system_qos_policy.system_qos_policy[each.value.system_qos_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.vlan_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkPolicy"
      moid        = intersight_fabric_eth_network_policy.vlan_policy[each.value.vlan_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.vsan_policy_key != null ? [1] : []
    content {
      object_type = "fabric.FcNetworkPolicy"
      moid        = intersight_fabric_fc_network_policy.vsan_policy[each.value.vsan_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ntp_policy_key != null ? [1] : []
    content {
      object_type = "ntp.Policy"
      moid        = intersight_ntp_policy.ntp_policy[each.value.ntp_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.snmp_policy_key != null ? [1] : []
    content {
      object_type = "snmp.Policy"
      moid        = intersight_snmp_policy.snmp_policy[each.value.snmp_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.syslog_policy_key != null ? [1] : []
    content {
      object_type = "syslog.Policy"
      moid        = intersight_syslog_policy.syslog_policy[each.value.syslog_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.network_connectivity_policy_key != null ? [1] : []
    content {
      object_type = "networkconfig.Policy"
      moid        = intersight_networkconfig_policy.network_connectivity_policy[each.value.network_connectivity_policy_key].moid
    }
  }
}
