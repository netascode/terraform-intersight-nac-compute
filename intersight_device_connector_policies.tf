locals {
  device_connector_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.device_connector, []) :
      try(policy.managed, true) ? [{
        key                                = format("%s/%s", org.name, policy.name)
        org_name                           = org.name
        name                               = policy.name
        description                        = try(policy.description, local.defaults.compute.intersight.organizations.policies.device_connector.description, "")
        configuration_from_intersight_only = try(policy.configuration_from_intersight_only, local.defaults.compute.intersight.organizations.policies.device_connector.configuration_from_intersight_only)
        tags                               = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_deviceconnector_policy" "device_connector_policy" {
  for_each = { for p in local.device_connector_policies : p.key => p if var.manage_intersight_policies }

  name            = each.value.name
  description     = each.value.description
  lockout_enabled = each.value.configuration_from_intersight_only

  dynamic "tags" {
    for_each = try(each.value.tags, [])
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
      type  = try(tags.value.type, "KeyValue")
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
