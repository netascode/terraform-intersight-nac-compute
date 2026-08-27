locals {
  link_control_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.link_control, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.link_control,
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

resource "intersight_fabric_link_control_policy" "link_control_policy" {
  for_each = { for p in local.link_control_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = try(each.value.description, "")

  udld_settings {
    object_type = "fabric.UdldSettings"
    admin_state = each.value.udld_enabled ? "Enabled" : "Disabled"
    mode        = each.value.mode
  }

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
