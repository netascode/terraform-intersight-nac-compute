locals {
  ethernet_network_group_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.ethernet_network_group, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.ethernet_network_group,
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

resource "intersight_fabric_eth_network_group_policy" "ethernet_network_group_policy" {
  for_each = { for p in local.ethernet_network_group_policies : p.key => p }

  name        = each.value.name
  description = try(each.value.description, "")

  vlan_settings {
    allowed_vlans = try(each.value.allowed_vlans, null)
    native_vlan   = try(each.value.native_vlan, null)
    qinq_enabled  = try(each.value.qinq, null)
    qinq_vlan     = try(each.value.qinq_vlan, null)
    object_type   = "fabric.VlanSettings"
  }

  dynamic "tags" {
    for_each = try(each.value.tags, [])
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
