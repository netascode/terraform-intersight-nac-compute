locals {
  flow_control_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.flow_control, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.flow_control,
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

resource "intersight_fabric_flow_control_policy" "flow_control_policy" {
  for_each = { for p in local.flow_control_policies : p.key => p if var.manage_intersight_policies }

  name                       = each.value.name
  description                = try(each.value.description, "")
  priority_flow_control_mode = each.value.priority
  receive_direction          = each.value.receive_enabled ? "Enabled" : "Disabled"
  send_direction             = each.value.send_enabled ? "Enabled" : "Disabled"

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
