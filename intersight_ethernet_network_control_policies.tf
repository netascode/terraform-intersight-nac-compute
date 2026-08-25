locals {
  ethernet_network_control_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.ethernet_network_control, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.ethernet_network_control,
        policy,
        {
          key      = format("%s/%s", org.name, policy.name)
          org_name = org.name
          name     = policy.name
        }
      )] : []
    ]
  ])
}

resource "intersight_fabric_eth_network_control_policy" "ethernet_network_control_policy" {
  for_each = { for p in local.ethernet_network_control_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = try(each.value.description, "")
  cdp_enabled = each.value.cdp
  forge_mac   = each.value.forge_mac

  mac_registration_mode = each.value.mac_registration_mode
  uplink_fail_action    = each.value.uplink_fail_action

  lldp_settings {
    object_type      = "fabric.LldpSettings"
    receive_enabled  = each.value.lldp_receive
    transmit_enabled = each.value.lldp_transmit
  }

  dynamic "tags" {
    for_each = [for t in try(each.value.tags, []) : t if try(t.type, "KeyValue") != "PathTag"]
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
    }
  }

  dynamic "tags" {
    for_each = [for t in try(each.value.tags, []) : t if try(t.type, "KeyValue") == "PathTag"]
    content {
      key                   = tags.value.key
      additional_properties = jsonencode({ Type = "PathTag" })
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
