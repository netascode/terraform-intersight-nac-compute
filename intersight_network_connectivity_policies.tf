locals {
  network_connectivity_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.network_connectivity, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.network_connectivity,
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

resource "intersight_networkconfig_policy" "network_connectivity_policy" {
  for_each = { for p in local.network_connectivity_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = try(each.value.description, "")

  preferred_ipv4dns_server = try(each.value.preferred_ipv4_dns, null)
  alternate_ipv4dns_server = try(each.value.alternate_ipv4_dns, null)
  enable_ipv4dns_from_dhcp = each.value.ipv4_dns_from_dhcp
  enable_ipv6              = each.value.ipv6
  preferred_ipv6dns_server = try(each.value.preferred_ipv6_dns, null)
  alternate_ipv6dns_server = try(each.value.alternate_ipv6_dns, null)
  enable_ipv6dns_from_dhcp = each.value.ipv6_dns_from_dhcp
  enable_dynamic_dns       = each.value.dynamic_dns
  dynamic_dns_domain       = try(each.value.dynamic_dns_domain, "")

  dynamic "tags" {
    for_each = try(each.value.tags, [])
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
      type  = try(tags.value.type, "KeyValue")
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
