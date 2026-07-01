locals {
  fibre_channel_network_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.fibre_channel_network, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.fibre_channel_network,
        policy,
        {
          key      = format("%s/%s", org.name, policy.name)
          org_name = org.name
          name     = policy.name
        }
      )] : []
    ]
  ])
}

resource "intersight_vnic_fc_network_policy" "fibre_channel_network_policy" {
  for_each = { for p in local.fibre_channel_network_policies : p.key => p }

  name        = each.value.name
  description = try(each.value.description, "")

  vsan_settings {
    object_type     = "vnic.VsanSettings"
    id              = each.value.vsan_id
    default_vlan_id = each.value.default_vlan_id
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
