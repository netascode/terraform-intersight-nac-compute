locals {
  virtual_media_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.virtual_media, []) :
      try(policy.managed, true) ? [{
        key           = format("%s/%s", org.name, policy.name)
        org_name      = org.name
        name          = policy.name
        description   = try(policy.description, local.defaults.compute.intersight.organizations.policies.virtual_media.description, "")
        enabled       = try(policy.enabled, local.defaults.compute.intersight.organizations.policies.virtual_media.enabled)
        encryption    = try(policy.encryption, local.defaults.compute.intersight.organizations.policies.virtual_media.encryption)
        low_power_usb = try(policy.low_power_usb, local.defaults.compute.intersight.organizations.policies.virtual_media.low_power_usb)
        mappings      = try(policy.mappings, [])
      }] : []
    ]
  ])
}

resource "intersight_vmedia_policy" "virtual_media_policy" {
  for_each = var.manage_intersight_policies ? { for p in local.virtual_media_policies : p.key => p } : {}

  name          = each.value.name
  description   = each.value.description
  enabled       = each.value.enabled
  encryption    = each.value.encryption
  low_power_usb = each.value.low_power_usb

  dynamic "mappings" {
    for_each = each.value.mappings
    content {
      volume_name             = mappings.value.volume_name
      device_type             = try(mappings.value.device_type, local.defaults.compute.intersight.organizations.policies.virtual_media.mappings.device_type)
      mount_protocol          = try(mappings.value.mount_protocol, local.defaults.compute.intersight.organizations.policies.virtual_media.mappings.mount_protocol)
      file_location           = try(mappings.value.file_location, null)
      mount_options           = try(mappings.value.mount_options, null)
      username                = try(mappings.value.username, null)
      password                = try(mappings.value.password, null)
      authentication_protocol = try(mappings.value.authentication_protocol, local.defaults.compute.intersight.organizations.policies.virtual_media.mappings.authentication_protocol)
    }
  }

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
