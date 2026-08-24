locals {
  firmware_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.firmware, []) :
      try(policy.managed, true) ? [{
        key                    = format("%s/%s", org.name, policy.name)
        org_name               = org.name
        name                   = policy.name
        description            = try(policy.description, local.defaults.compute.intersight.organizations.policies.firmware.description, "")
        target_platform        = try(policy.target_platform, local.defaults.compute.intersight.organizations.policies.firmware.target_platform)
        exclude_component_list = try(policy.exclude_component_list, [])
        model_bundle_combo     = try(policy.model_bundle_combo, [])
      }] : []
    ]
  ])
}

resource "intersight_firmware_policy" "firmware_policy" {
  for_each = { for p in local.firmware_policies : p.key => p if var.manage_intersight_policies }

  name                   = each.value.name
  description            = each.value.description
  target_platform        = each.value.target_platform
  exclude_component_list = each.value.exclude_component_list

  dynamic "model_bundle_combo" {
    for_each = each.value.model_bundle_combo
    content {
      object_type    = "firmware.ModelBundleVersion"
      model_family   = model_bundle_combo.value.model_family
      bundle_version = model_bundle_combo.value.bundle_version
    }
  }

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
