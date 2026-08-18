locals {
  domain_templates = flatten([
    for org in local.filtered_intersight_organizations : [
      for tmpl in try(org.templates.domain, []) :
      try(tmpl.managed, true) ? [{
        key                             = format("%s/%s", org.name, tmpl.name)
        org_name                        = org.name
        name                            = tmpl.name
        description                     = try(tmpl.description, local.defaults.compute.intersight.organizations.templates.domain.description, "")
        target_platform                 = try(tmpl.target_platform, local.defaults.compute.intersight.organizations.templates.domain.target_platform)
        tags                            = try(tmpl.tags, [])
        switch_a_port_policy_key        = try(tmpl.switch_a_port_policy, null) != null ? format("%s/%s", org.name, tmpl.switch_a_port_policy) : null
        switch_b_port_policy_key        = try(tmpl.switch_b_port_policy, null) != null ? format("%s/%s", org.name, tmpl.switch_b_port_policy) : null
        switch_control_policy_key       = try(tmpl.switch_control_policy, null) != null ? format("%s/%s", org.name, tmpl.switch_control_policy) : null
        system_qos_policy_key           = try(tmpl.system_qos_policy, null) != null ? format("%s/%s", org.name, tmpl.system_qos_policy) : null
        vlan_policy_key                 = try(tmpl.vlan_policy, null) != null ? format("%s/%s", org.name, tmpl.vlan_policy) : null
        vsan_policy_key                 = try(tmpl.vsan_policy, null) != null ? format("%s/%s", org.name, tmpl.vsan_policy) : null
        ntp_policy_key                  = try(tmpl.ntp_policy, null) != null ? format("%s/%s", org.name, tmpl.ntp_policy) : null
        snmp_policy_key                 = try(tmpl.snmp_policy, null) != null ? format("%s/%s", org.name, tmpl.snmp_policy) : null
        syslog_policy_key               = try(tmpl.syslog_policy, null) != null ? format("%s/%s", org.name, tmpl.syslog_policy) : null
        network_connectivity_policy_key = try(tmpl.network_connectivity_policy, null) != null ? format("%s/%s", org.name, tmpl.network_connectivity_policy) : null
      }] : []
    ]
  ])

  domain_switch_profile_templates = flatten([
    for tmpl in local.domain_templates : [
      {
        key                             = format("%s/A", tmpl.key)
        cluster_key                     = tmpl.key
        name                            = format("%s-A", tmpl.name)
        switch_id                       = "A"
        port_policy_key                 = tmpl.switch_a_port_policy_key
        switch_control_policy_key       = tmpl.switch_control_policy_key
        system_qos_policy_key           = tmpl.system_qos_policy_key
        vlan_policy_key                 = tmpl.vlan_policy_key
        vsan_policy_key                 = tmpl.vsan_policy_key
        ntp_policy_key                  = tmpl.ntp_policy_key
        snmp_policy_key                 = tmpl.snmp_policy_key
        syslog_policy_key               = tmpl.syslog_policy_key
        network_connectivity_policy_key = tmpl.network_connectivity_policy_key
      },
      {
        key                             = format("%s/B", tmpl.key)
        cluster_key                     = tmpl.key
        name                            = format("%s-B", tmpl.name)
        switch_id                       = "B"
        port_policy_key                 = tmpl.switch_b_port_policy_key
        switch_control_policy_key       = tmpl.switch_control_policy_key
        system_qos_policy_key           = tmpl.system_qos_policy_key
        vlan_policy_key                 = tmpl.vlan_policy_key
        vsan_policy_key                 = tmpl.vsan_policy_key
        ntp_policy_key                  = tmpl.ntp_policy_key
        snmp_policy_key                 = tmpl.snmp_policy_key
        syslog_policy_key               = tmpl.syslog_policy_key
        network_connectivity_policy_key = tmpl.network_connectivity_policy_key
      },
    ]
  ])
}

resource "intersight_fabric_switch_cluster_profile_template" "domain_template" {
  for_each = { for t in local.domain_templates : t.key => t if var.manage_intersight_templates }

  name            = each.value.name
  description     = each.value.description
  target_platform = each.value.target_platform

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

resource "intersight_fabric_switch_profile_template" "domain_switch_profile_template" {
  for_each = { for t in local.domain_switch_profile_templates : t.key => t if var.manage_intersight_templates }

  name      = each.value.name
  switch_id = each.value.switch_id

  switch_cluster_profile_template {
    object_type = "fabric.SwitchClusterProfileTemplate"
    moid        = intersight_fabric_switch_cluster_profile_template.domain_template[each.value.cluster_key].moid
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
