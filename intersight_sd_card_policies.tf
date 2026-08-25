locals {
  sd_card_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.sd_card, []) :
      try(policy.managed, true) ? [{
        key                = format("%s/%s", org.name, policy.name)
        org_name           = org.name
        name               = policy.name
        description        = try(policy.description, local.defaults.compute.intersight.organizations.policies.sd_card.description, "")
        enable_os          = try(policy.enable_os, local.defaults.compute.intersight.organizations.policies.sd_card.enable_os)
        enable_diagnostics = try(policy.enable_diagnostics, local.defaults.compute.intersight.organizations.policies.sd_card.enable_diagnostics)
        enable_drivers     = try(policy.enable_drivers, local.defaults.compute.intersight.organizations.policies.sd_card.enable_drivers)
        enable_huu         = try(policy.enable_huu, local.defaults.compute.intersight.organizations.policies.sd_card.enable_huu)
        enable_scu         = try(policy.enable_scu, local.defaults.compute.intersight.organizations.policies.sd_card.enable_scu)
        tags               = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_sdcard_policy" "sd_card_policy" {
  for_each = { for p in local.sd_card_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = each.value.description

  # OS partition — only created when enable_os is true
  dynamic "partitions" {
    for_each = each.value.enable_os ? [1] : []
    content {
      type        = "OS"
      object_type = "sdcard.Partition"
      virtual_drives {
        object_type           = "sdcard.OperatingSystem"
        enable                = true
        additional_properties = jsonencode({ Name = "Hypervisor" })
      }
    }
  }

  # Utility partition — only created when at least one utility drive is enabled
  dynamic "partitions" {
    for_each = (each.value.enable_diagnostics || each.value.enable_drivers || each.value.enable_huu || each.value.enable_scu) ? [1] : []
    content {
      type        = "Utility"
      object_type = "sdcard.Partition"
      dynamic "virtual_drives" {
        for_each = each.value.enable_diagnostics ? [1] : []
        content {
          object_type = "sdcard.Diagnostics"
          enable      = true
        }
      }
      dynamic "virtual_drives" {
        for_each = each.value.enable_drivers ? [1] : []
        content {
          object_type = "sdcard.Drivers"
          enable      = true
        }
      }
      dynamic "virtual_drives" {
        for_each = each.value.enable_huu ? [1] : []
        content {
          object_type = "sdcard.HostUpgradeUtility"
          enable      = true
        }
      }
      dynamic "virtual_drives" {
        for_each = each.value.enable_scu ? [1] : []
        content {
          object_type = "sdcard.ServerConfigurationUtility"
          enable      = true
        }
      }
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
