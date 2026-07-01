locals {
  thermal_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.thermal, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.thermal,
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

resource "intersight_thermal_policy" "thermal_policy" {
  for_each = { for p in local.thermal_policies : p.key => p }

  name             = each.value.name
  description      = try(each.value.description, "")
  fan_control_mode = each.value.fan_control_mode

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
