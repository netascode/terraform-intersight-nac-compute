locals {
  system_qos_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.system_qos, []) :
      try(policy.managed, true) ? [{
        key         = format("%s/%s", org.name, policy.name)
        org_name    = org.name
        name        = policy.name
        description = try(policy.description, local.defaults.compute.intersight.organizations.policies.system_qos.description, "")
        tags        = try(policy.tags, [])
        classes = [
          for cls in try(policy.classes, []) : {
            priority           = cls.priority
            admin_state        = try(cls.state, local.defaults.compute.intersight.organizations.policies.system_qos.classes.state)
            cos                = try(cls.cos, null)
            bandwidth_percent  = try(cls.bandwidth_percent, null)
            mtu                = try(cls.mtu, null)
            multicast_optimize = try(cls.multicast_optimize, null)
            packet_drop        = try(cls.packet_drop, local.defaults.compute.intersight.organizations.policies.system_qos.classes.packet_drop)
            weight             = try(cls.weight, local.defaults.compute.intersight.organizations.policies.system_qos.classes.weight)
          }
        ]
        pfc_watchdog_enabled             = try(policy.pfc_watchdog.enabled, local.defaults.compute.intersight.organizations.policies.system_qos.pfc_watchdog.enabled)
        pfc_watchdog_interval            = try(policy.pfc_watchdog.watchdog_interval, local.defaults.compute.intersight.organizations.policies.system_qos.pfc_watchdog.watchdog_interval)
        pfc_watchdog_shutdown_multiplier = try(policy.pfc_watchdog.shutdown_multiplier, local.defaults.compute.intersight.organizations.policies.system_qos.pfc_watchdog.shutdown_multiplier)
      }] : []
    ]
  ])
}

resource "intersight_fabric_system_qos_policy" "system_qos_policy" {
  for_each = { for p in local.system_qos_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = each.value.description

  dynamic "classes" {
    for_each = each.value.classes
    content {
      object_type        = "fabric.QosClass"
      name               = classes.value.priority
      admin_state        = classes.value.admin_state
      cos                = classes.value.cos
      bandwidth_percent  = classes.value.bandwidth_percent
      mtu                = classes.value.mtu
      multicast_optimize = classes.value.multicast_optimize
      packet_drop        = classes.value.packet_drop
      weight             = classes.value.weight
    }
  }

  pfc_watchdog {
    object_type         = "fabric.PfcWatchDog"
    is_watchdog_enabled = each.value.pfc_watchdog_enabled
    watchdog_interval   = each.value.pfc_watchdog_interval
    shutdown_multiplier = each.value.pfc_watchdog_shutdown_multiplier
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
