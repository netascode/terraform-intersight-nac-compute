locals {
  iscsi_static_target_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.iscsi_static_target, []) :
      try(policy.managed, true) ? [{
        key         = format("%s/%s", org.name, policy.name)
        org_name    = org.name
        name        = policy.name
        description = try(policy.description, local.defaults.compute.intersight.organizations.policies.iscsi_static_target.description, "")
        ip_address  = try(policy.ip_address, null)
        port        = try(policy.port, local.defaults.compute.intersight.organizations.policies.iscsi_static_target.port)
        target_name = try(policy.target_name, null)
        lun         = try(policy.lun, null)
        tags        = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_vnic_iscsi_static_target_policy" "iscsi_static_target_policy" {
  for_each = { for p in local.iscsi_static_target_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = each.value.description
  ip_address  = each.value.ip_address
  port        = each.value.port
  target_name = each.value.target_name

  dynamic "lun" {
    for_each = each.value.lun != null ? [each.value.lun] : []
    content {
      object_type = "vnic.Lun"
      bootable    = try(lun.value.bootable, null)
      lun_id      = try(lun.value.lun_id, null)
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
