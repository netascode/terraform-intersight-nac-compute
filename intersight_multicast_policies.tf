locals {
  multicast_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.multicast, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.multicast,
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

resource "intersight_fabric_multicast_policy" "multicast_policy" {
  for_each = var.manage_intersight_policies ? { for p in local.multicast_policies : p.key => p } : {}

  name                    = each.value.name
  description             = try(each.value.description, "")
  querier_state           = each.value.querier_state
  querier_ip_address      = try(each.value.querier_ip_address, "")
  querier_ip_address_peer = try(each.value.querier_ip_address_peer, "")
  snooping_state          = each.value.snooping_state
  src_ip_proxy            = each.value.src_ip_proxy

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
