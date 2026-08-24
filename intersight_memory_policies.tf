locals {
  memory_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.memory, []) :
      try(policy.managed, true) ? [{
        key               = format("%s/%s", org.name, policy.name)
        org_name          = org.name
        name              = policy.name
        description       = try(policy.description, local.defaults.compute.intersight.organizations.policies.memory.description, "")
        dimm_blocklisting = try(policy.dimm_blocklisting, local.defaults.compute.intersight.organizations.policies.memory.dimm_blocklisting)
        tags              = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_memory_policy" "memory_policy" {
  for_each = { for p in local.memory_policies : p.key => p if var.manage_intersight_policies }

  name                     = each.value.name
  description              = each.value.description
  enable_dimm_blocklisting = each.value.dimm_blocklisting

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
