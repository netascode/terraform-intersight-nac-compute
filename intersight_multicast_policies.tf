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
  for_each = { for p in local.multicast_policies : p.key => p if var.manage_intersight_policies }

  name                    = each.value.name
  description             = try(each.value.description, "")
  querier_state           = each.value.querier_enabled ? "Enabled" : "Disabled"
  querier_ip_address      = try(each.value.querier_ip_address, "")
  querier_ip_address_peer = try(each.value.querier_ip_address_peer, "")
  snooping_state          = each.value.snooping_enabled ? "Enabled" : "Disabled"
  src_ip_proxy            = each.value.src_ip_proxy_enabled ? "Enabled" : "Disabled"

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
