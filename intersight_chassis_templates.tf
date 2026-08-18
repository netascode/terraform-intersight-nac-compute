locals {
  chassis_templates = flatten([
    for org in local.filtered_intersight_organizations : [
      for tmpl in try(org.templates.chassis, []) :
      try(tmpl.managed, true) ? [{
        key                   = format("%s/%s", org.name, tmpl.name)
        org_name              = org.name
        name                  = tmpl.name
        description           = try(tmpl.description, local.defaults.compute.intersight.organizations.templates.chassis.description, "")
        tags                  = try(tmpl.tags, [])
        imc_access_policy_key = try(tmpl.imc_access_policy, null) != null ? format("%s/%s", org.name, tmpl.imc_access_policy) : null
        power_policy_key      = try(tmpl.power_policy, null) != null ? format("%s/%s", org.name, tmpl.power_policy) : null
        snmp_policy_key       = try(tmpl.snmp_policy, null) != null ? format("%s/%s", org.name, tmpl.snmp_policy) : null
        thermal_policy_key    = try(tmpl.thermal_policy, null) != null ? format("%s/%s", org.name, tmpl.thermal_policy) : null
      }] : []
    ]
  ])
}

resource "intersight_chassis_profile_template" "chassis_template" {
  for_each = { for t in local.chassis_templates : t.key => t if var.manage_intersight_templates }

  name        = each.value.name
  description = each.value.description

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
      value = tags.value.value
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
