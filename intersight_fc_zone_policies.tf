locals {
  fc_zone_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.fc_zone, []) :
      try(policy.managed, true) ? [{
        key                   = format("%s/%s", org.name, policy.name)
        org_name              = org.name
        name                  = policy.name
        description           = try(policy.description, local.defaults.compute.intersight.organizations.policies.fc_zone.description, "")
        fc_target_zoning_type = try(policy.fc_target_zoning_type, local.defaults.compute.intersight.organizations.policies.fc_zone.fc_target_zoning_type)
        fc_target_members     = try(policy.fc_target_members, [])
        tags                  = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_fabric_fc_zone_policy" "fc_zone_policy" {
  for_each = { for p in local.fc_zone_policies : p.key => p if var.manage_intersight_policies }

  description           = each.value.description
  fc_target_zoning_type = each.value.fc_target_zoning_type
  name                  = each.value.name

  dynamic "fc_target_members" {
    for_each = each.value.fc_target_members
    content {
      object_type = "fabric.FcZoneMember"
      name        = fc_target_members.value.name
      switch_id   = fc_target_members.value.switch_id
      vsan_id     = fc_target_members.value.vsan_id
      wwpn        = fc_target_members.value.wwpn
    }
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
