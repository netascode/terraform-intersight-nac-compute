locals {
  ethernet_network_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.ethernet_network, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.ethernet_network,
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

resource "intersight_vnic_eth_network_policy" "ethernet_network_policy" {
  for_each = { for p in local.ethernet_network_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = try(each.value.description, "")

  vlan_settings {
    default_vlan  = try(each.value.default_vlan, null)
    mode          = try(each.value.vlan_mode, null)
    allowed_vlans = try(each.value.allowed_vlans, null)
    qinq_enabled  = try(each.value.qinq, null)
    qinq_vlan     = try(each.value.qinq_vlan, null)
    object_type   = "vnic.VlanSettings"
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
      key = tags.value.key
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
