locals {
  adapter_configuration_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.adapter_configuration, []) :
      try(policy.managed, true) ? [{
        key         = format("%s/%s", org.name, policy.name)
        org_name    = org.name
        name        = policy.name
        description = try(policy.description, local.defaults.compute.intersight.organizations.policies.adapter_configuration.description, "")
        settings    = try(policy.settings, [])
        tags        = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_adapter_config_policy" "adapter_configuration_policy" {
  for_each = { for p in local.adapter_configuration_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = each.value.description

  dynamic "settings" {
    for_each = each.value.settings
    content {
      object_type = "adapter.AdapterConfig"
      slot_id     = settings.value.slot_id

      dynamic "eth_settings" {
        for_each = try(settings.value.eth_settings, null) != null ? [settings.value.eth_settings] : []
        content {
          lldp_enabled = try(eth_settings.value.lldp_enabled, false)
        }
      }

      dynamic "fc_settings" {
        for_each = try(settings.value.fc_settings, null) != null ? [settings.value.fc_settings] : []
        content {
          fip_enabled = try(fc_settings.value.fip_enabled, false)
        }
      }

      dynamic "port_channel_settings" {
        for_each = try(settings.value.port_channel_settings, null) != null ? [settings.value.port_channel_settings] : []
        content {
          enabled = try(port_channel_settings.value.enabled, true)
        }
      }

      dynamic "physical_nic_mode_settings" {
        for_each = try(settings.value.physical_nic_mode_settings, null) != null ? [settings.value.physical_nic_mode_settings] : []
        content {
          phy_nic_enabled = try(physical_nic_mode_settings.value.phy_nic_enabled, false)
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
      key                   = tags.value.key
      additional_properties = jsonencode({ Type = "PathTag" })
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
