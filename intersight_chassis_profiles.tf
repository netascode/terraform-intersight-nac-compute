locals {
  chassis_profiles = flatten([
    for org in local.filtered_intersight_organizations : [
      for profile in try(org.profiles.chassis, []) :
      (try(profile.managed, true)
        && (
          (length(var.managed_intersight_chassis) == 0 && length(var.managed_intersight_chassis_tags) == 0)
          || contains(var.managed_intersight_chassis, profile.name)
          || (length(local._tag_filter_intersight_chassis) > 0 && alltrue([
            for tf in local._tag_filter_intersight_chassis :
            anytrue([for pt in try(profile.tags, []) : pt.key == tf.key && pt.value == tf.value])
          ]))
        )
        ) ? [{
          key                               = format("%s/%s", org.name, profile.name)
          org_name                          = org.name
          name                              = profile.name
          description                       = try(profile.description, local.defaults.compute.intersight.organizations.profiles.chassis.description, "")
          tags                              = try(profile.tags, [])
          serial_number                     = try(profile.serial_number, null)
          chassis_template_key              = try(profile.chassis_template, null) != null ? format("%s/%s", org.name, profile.chassis_template) : null
          certificate_management_policy_key = try(profile.certificate_management_policy, null) != null ? format("%s/%s", org.name, profile.certificate_management_policy) : null
          imc_access_policy_key             = try(profile.imc_access_policy, null) != null ? format("%s/%s", org.name, profile.imc_access_policy) : null
          power_policy_key                  = try(profile.power_policy, null) != null ? format("%s/%s", org.name, profile.power_policy) : null
          snmp_policy_key                   = try(profile.snmp_policy, null) != null ? format("%s/%s", org.name, profile.snmp_policy) : null
          thermal_policy_key                = try(profile.thermal_policy, null) != null ? format("%s/%s", org.name, profile.thermal_policy) : null
      }] : []
    ]
  ])
}

resource "intersight_chassis_profile" "chassis_profile" {
  for_each = { for p in local.chassis_profiles : p.key => p if var.manage_intersight_profiles }

  name                         = each.value.name
  description                  = each.value.description
  chassis_pre_assign_by_serial = each.value.serial_number != null ? each.value.serial_number : null

  dynamic "src_template" {
    for_each = each.value.chassis_template_key != null ? [1] : []
    content {
      object_type = "chassis.ProfileTemplate"
      moid        = local.chassis_template_moids[each.value.chassis_template_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.certificate_management_policy_key != null ? [1] : []
    content {
      object_type = "certificatemanagement.Policy"
      moid        = local.certificate_management_policy_moids[each.value.certificate_management_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.imc_access_policy_key != null ? [1] : []
    content {
      object_type = "access.Policy"
      moid        = local.imc_access_policy_moids[each.value.imc_access_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.power_policy_key != null ? [1] : []
    content {
      object_type = "power.Policy"
      moid        = local.power_policy_moids[each.value.power_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.snmp_policy_key != null ? [1] : []
    content {
      object_type = "snmp.Policy"
      moid        = local.snmp_policy_moids[each.value.snmp_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.thermal_policy_key != null ? [1] : []
    content {
      object_type = "thermal.Policy"
      moid        = local.thermal_policy_moids[each.value.thermal_policy_key]
    }
  }

  dynamic "tags" {
    for_each = each.value.tags
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
