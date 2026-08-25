locals {
  iscsi_adapter_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.iscsi_adapter, []) :
      try(policy.managed, true) ? [{
        key                  = format("%s/%s", org.name, policy.name)
        org_name             = org.name
        name                 = policy.name
        description          = try(policy.description, local.defaults.compute.intersight.organizations.policies.iscsi_adapter.description, "")
        connection_timeout   = try(policy.connection_timeout, local.defaults.compute.intersight.organizations.policies.iscsi_adapter.connection_timeout)
        dhcp_timeout         = try(policy.dhcp_timeout, local.defaults.compute.intersight.organizations.policies.iscsi_adapter.dhcp_timeout)
        lun_busy_retry_count = try(policy.lun_busy_retry_count, local.defaults.compute.intersight.organizations.policies.iscsi_adapter.lun_busy_retry_count)
        tags                 = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_vnic_iscsi_adapter_policy" "iscsi_adapter_policy" {
  for_each = { for p in local.iscsi_adapter_policies : p.key => p if var.manage_intersight_policies }

  name                 = each.value.name
  description          = each.value.description
  connection_time_out  = each.value.connection_timeout
  dhcp_timeout         = each.value.dhcp_timeout
  lun_busy_retry_count = each.value.lun_busy_retry_count

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
