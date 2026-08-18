locals {
  serial_over_lan_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.serial_over_lan, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.serial_over_lan,
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

resource "intersight_sol_policy" "serial_over_lan_policy" {
  for_each = var.manage_intersight_policies ? { for p in local.serial_over_lan_policies : p.key => p } : {}

  name        = each.value.name
  description = try(each.value.description, "")
  enabled     = each.value.enabled
  baud_rate   = each.value.baud_rate
  com_port    = each.value.com_port
  ssh_port    = each.value.ssh_port

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
