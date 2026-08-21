locals {
  scrub_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.scrub, []) :
      try(policy.managed, true) ? [{
        key           = format("%s/%s", org.name, policy.name)
        org_name      = org.name
        name          = policy.name
        description   = try(policy.description, local.defaults.compute.intersight.organizations.policies.scrub.description, "")
        scrub_targets = try(policy.scrub_targets, [])
        tags          = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_compute_scrub_policy" "scrub_policy" {
  for_each = { for p in local.scrub_policies : p.key => p if var.manage_intersight_policies }

  name          = each.value.name
  description   = each.value.description
  scrub_targets = each.value.scrub_targets

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
