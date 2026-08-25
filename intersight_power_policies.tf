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
  for_each = { for p in local.power_policies : p.key => p if var.manage_intersight_policies }

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
    for_each = [for t in try(each.value.tags, []) : t if try(t.type, "KeyValue") != "PathTag"]
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
    }
  }

  dynamic "tags" {
    for_each = [for t in try(each.value.tags, []) : t if try(t.type, "KeyValue") == "PathTag"]
    content {
      key                   = tags.value.key
      additional_properties = jsonencode({ Type = "PathTag" })
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
