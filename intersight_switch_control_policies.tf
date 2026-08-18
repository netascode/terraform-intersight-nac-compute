locals {
  switch_control_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.switch_control, []) :
      try(policy.managed, true) ? [{
        key                            = format("%s/%s", org.name, policy.name)
        org_name                       = org.name
        name                           = policy.name
        description                    = try(policy.description, local.defaults.compute.intersight.organizations.policies.switch_control.description, "")
        tags                           = try(policy.tags, [])
        switching_mode_ethernet        = try(policy.switching_mode_ethernet, local.defaults.compute.intersight.organizations.policies.switch_control.switching_mode_ethernet)
        switching_mode_fc              = try(policy.switching_mode_fc, local.defaults.compute.intersight.organizations.policies.switch_control.switching_mode_fc)
        jumbo_frame                    = try(policy.jumbo_frame, local.defaults.compute.intersight.organizations.policies.switch_control.jumbo_frame)
        vlan_port_count_optimization   = try(policy.vlan_port_count_optimization, local.defaults.compute.intersight.organizations.policies.switch_control.vlan_port_count_optimization)
        fabric_port_channel_vhba_reset = try(policy.fabric_port_channel_vhba_reset, local.defaults.compute.intersight.organizations.policies.switch_control.fabric_port_channel_vhba_reset)
        reserved_vlan_start_id         = try(policy.reserved_vlan_start_id, local.defaults.compute.intersight.organizations.policies.switch_control.reserved_vlan_start_id)
        mac_address_table_aging        = try(policy.mac_address_table_aging, local.defaults.compute.intersight.organizations.policies.switch_control.mac_address_table_aging)
        mac_aging_time                 = try(policy.mac_aging_time, local.defaults.compute.intersight.organizations.policies.switch_control.mac_aging_time)
        udld_message_interval          = try(policy.udld_settings.message_interval, local.defaults.compute.intersight.organizations.policies.switch_control.udld_settings.message_interval)
        udld_recovery_action           = try(policy.udld_settings.recovery_action, local.defaults.compute.intersight.organizations.policies.switch_control.udld_settings.recovery_action)
      }] : []
    ]
  ])
}

resource "intersight_fabric_switch_control_policy" "switch_control_policy" {
  for_each = { for p in local.switch_control_policies : p.key => p if var.manage_intersight_policies }

  name                           = each.value.name
  description                    = each.value.description
  ethernet_switching_mode        = each.value.switching_mode_ethernet
  fc_switching_mode              = each.value.switching_mode_fc
  enable_jumbo_frame             = each.value.jumbo_frame
  vlan_port_optimization_enabled = each.value.vlan_port_count_optimization
  fabric_pc_vhba_reset           = each.value.fabric_port_channel_vhba_reset
  reserved_vlan_start_id         = each.value.reserved_vlan_start_id

  mac_aging_settings {
    mac_aging_option = each.value.mac_address_table_aging
    mac_aging_time   = each.value.mac_aging_time
    object_type      = "fabric.MacAgingSettings"
  }

  udld_settings {
    message_interval = each.value.udld_message_interval
    recovery_action  = each.value.udld_recovery_action
    object_type      = "fabric.UdldGlobalSettings"
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
