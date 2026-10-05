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
          action                            = try(profile.action, local.defaults.compute.intersight.organizations.profiles.chassis.action)
          wait_for_completion               = try(profile.wait_for_completion, local.defaults.compute.intersight.organizations.profiles.chassis.wait_for_completion)
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

  # Collect unique chassis serial numbers needing lookup
  chassis_serials = toset([
    for p in local.chassis_profiles : p.serial_number
    if p.serial_number != null
  ])

  # Resolve discovered chassis Moid per serial, when Intersight has inventoried it
  chassis_moids = {
    for s in local.chassis_serials : s => (
      length(data.intersight_equipment_chassis.chassis[s].results) > 0
      ? data.intersight_equipment_chassis.chassis[s].results[0].moid
      : null
    )
  }

  # Map data model action values to Intersight provider action strings
  _intersight_chassis_action_map = {
    none     = "No-op"
    deploy   = "Deploy"
    unassign = "Unassign"
  }
}

data "intersight_equipment_chassis" "chassis" {
  for_each = var.manage_intersight_profiles ? local.chassis_serials : toset([])
  serial   = each.key
}

resource "intersight_chassis_profile" "chassis_profile" {
  for_each = { for p in local.chassis_profiles : p.key => p if var.manage_intersight_profiles }

  name                = each.value.name
  description         = each.value.description
  action              = local._intersight_chassis_action_map[each.value.action]
  wait_for_completion = each.value.action != "none" ? each.value.wait_for_completion : false

  # Suppressed while action is "unassign": assigned_chassis/chassis_pre_assign_by_serial are computed purely
  # from serial_number/discovery, with no awareness of action. Without this guard, the first apply after a
  # successful Unassign would see the still-configured serial_number resolve again and re-attach the chassis -
  # Unassign is the one-shot command that actually detaches it; these optional+computed fields must stay out
  # of the request entirely until the chassis is reassigned by removing the unassign action.
  dynamic "assigned_chassis" {
    for_each = each.value.action != "unassign" && each.value.serial_number != null && local.chassis_moids[each.value.serial_number] != null ? [1] : []
    content {
      object_type = "equipment.Chassis"
      moid        = local.chassis_moids[each.value.serial_number]
    }
  }

  chassis_pre_assign_by_serial = each.value.action != "unassign" && each.value.serial_number != null && local.chassis_moids[each.value.serial_number] == null ? each.value.serial_number : null

  # src_template is set here via additional_properties, not the native src_template block, because Intersight
  # rejects a PATCH that changes src_template directly from one template to another on a profile already
  # attached to a template (403 gershwin_derived_sp_invalid_src) - confirmed as a genuine two-apply-required
  # API constraint by the module maintainer in CiscoDevNet/terraform-provider-intersight#261/#263, not a
  # transport artifact. Reassigning a template therefore requires removing chassis_template (sends
  # SrcTemplate: null) on one apply, then setting the new one on the next. additional_properties is a plain
  # string attribute under our full control, so normal Terraform diffing sends the right PATCH on every apply
  # with no extra gating needed.
  additional_properties = jsonencode({
    SrcTemplate = each.value.chassis_template_key != null ? {
      Moid       = local.chassis_template_moids[each.value.chassis_template_key]
      ObjectType = "chassis.ProfileTemplate"
    } : null
  })

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

