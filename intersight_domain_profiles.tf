locals {
  domain_profiles = flatten([
    for org in local.filtered_intersight_organizations : [
      for profile in try(org.profiles.domain, []) :
      (try(profile.managed, true)
        && (
          (length(var.managed_intersight_domains) == 0 && length(var.managed_intersight_domain_tags) == 0)
          || contains(var.managed_intersight_domains, profile.name)
          || (length(local._tag_filter_intersight_domains) > 0 && alltrue([
            for tf in local._tag_filter_intersight_domains :
            anytrue([for pt in try(profile.tags, []) : pt.key == tf.key && pt.value == tf.value])
          ]))
        )
        ) ? [{
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
          ldap_policy_key                 = try(profile.ldap_policy, null) != null ? format("%s/%s", org.name, profile.ldap_policy) : null
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
        ldap_policy_key                 = profile.ldap_policy_key
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
        ldap_policy_key                 = profile.ldap_policy_key
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
  for_each = var.manage_intersight_profiles ? local.domain_fi_serials : toset([])
  serial   = each.key
}

resource "intersight_fabric_switch_cluster_profile" "domain_profile" {
  for_each = { for p in local.domain_profiles : p.key => p if var.manage_intersight_profiles }

  name            = each.value.name
  description     = each.value.description
  target_platform = each.value.target_platform

  dynamic "src_template" {
    for_each = each.value.ucs_domain_template_key != null ? [1] : []
    content {
      object_type = "fabric.SwitchClusterProfileTemplate"
      moid        = local.domain_template_moids[each.value.ucs_domain_template_key]
    }
  }

  dynamic "tags" {
    for_each = each.value.tags
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}

resource "intersight_fabric_switch_profile" "domain_switch_profile" {
  for_each = { for sp in local.domain_switch_profiles : sp.key => sp if var.manage_intersight_profiles }

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
      moid        = local.port_policy_moids[each.value.port_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.switch_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.SwitchControlPolicy"
      moid        = local.switch_control_policy_moids[each.value.switch_control_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.system_qos_policy_key != null ? [1] : []
    content {
      object_type = "fabric.SystemQosPolicy"
      moid        = local.system_qos_policy_moids[each.value.system_qos_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.vlan_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkPolicy"
      moid        = local.vlan_policy_moids[each.value.vlan_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.vsan_policy_key != null ? [1] : []
    content {
      object_type = "fabric.FcNetworkPolicy"
      moid        = local.vsan_policy_moids[each.value.vsan_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ntp_policy_key != null ? [1] : []
    content {
      object_type = "ntp.Policy"
      moid        = local.ntp_policy_moids[each.value.ntp_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.snmp_policy_key != null ? [1] : []
    content {
      object_type = "snmp.Policy"
      moid        = local.snmp_policy_moids[each.value.snmp_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.syslog_policy_key != null ? [1] : []
    content {
      object_type = "syslog.Policy"
      moid        = local.syslog_policy_moids[each.value.syslog_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.network_connectivity_policy_key != null ? [1] : []
    content {
      object_type = "networkconfig.Policy"
      moid        = local.network_connectivity_policy_moids[each.value.network_connectivity_policy_key]
    }
  }


  dynamic "policy_bucket" {
    for_each = each.value.ldap_policy_key != null ? [1] : []
    content {
      object_type = "iam.LdapPolicy"
      moid        = local.ldap_policy_moids[each.value.ldap_policy_key]
    }
  }
}
