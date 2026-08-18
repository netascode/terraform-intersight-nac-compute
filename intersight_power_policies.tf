locals {
  power_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.power, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.power,
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

resource "intersight_power_policy" "power_policy" {
  for_each = var.manage_intersight_policies ? { for p in local.power_policies : p.key => p } : {}

  name                          = each.value.name
  description                   = try(each.value.description, "")
  allocated_budget              = each.value.allocated_budget
  dynamic_rebalancing           = each.value.dynamic_rebalancing
  extended_power_capacity       = each.value.extended_power_capacity
  power_priority                = each.value.power_priority
  power_profiling               = each.value.power_profiling
  power_restore_state           = each.value.power_restore_state
  power_save_mode               = each.value.power_save_mode
  processor_package_power_limit = each.value.processor_package_power_limit
  redundancy_mode               = each.value.redundancy_mode

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
