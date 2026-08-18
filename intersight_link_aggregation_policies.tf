locals {
  link_aggregation_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.link_aggregation, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.link_aggregation,
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

resource "intersight_fabric_link_aggregation_policy" "link_aggregation_policy" {
  for_each = var.manage_intersight_policies ? { for p in local.link_aggregation_policies : p.key => p } : {}

  name               = each.value.name
  description        = try(each.value.description, "")
  lacp_rate          = each.value.lacp_rate
  suspend_individual = each.value.suspend_individual

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
