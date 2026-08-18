locals {
  vsan_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.vsan, []) :
      try(policy.managed, true) ? [{
        key             = format("%s/%s", org.name, policy.name)
        org_name        = org.name
        name            = policy.name
        description     = try(policy.description, local.defaults.compute.intersight.organizations.policies.vsan.description, "")
        tags            = try(policy.tags, [])
        uplink_trunking = try(policy.uplink_trunking, local.defaults.compute.intersight.organizations.policies.vsan.uplink_trunking)
        vsans           = try(policy.vsans, [])
      }] : []
    ]
  ])

  vsan_policies_map = { for p in local.vsan_policies : p.key => p }

  vsans = flatten([
    for policy in local.vsan_policies : [
      for vsan in policy.vsans : {
        key        = format("%s/%s", policy.key, vsan.name)
        policy_key = policy.key
        name       = vsan.name
        vsan_id    = vsan.vsan_id
        fcoe_vlan  = try(vsan.fcoe_vlan_id, vsan.vsan_id)
        vsan_scope = try(vsan.vsan_scope, local.defaults.compute.intersight.organizations.policies.vsan.vsans.vsan_scope)
      }
    ]
  ])
}

resource "intersight_fabric_fc_network_policy" "vsan_policy" {
  for_each = local.vsan_policies_map

  name            = each.value.name
  description     = each.value.description
  enable_trunking = each.value.uplink_trunking

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

resource "intersight_fabric_vsan" "vsan" {
  for_each = var.manage_intersight_policies ? { for v in local.vsans : v.key => v } : {}

  name       = each.value.name
  vsan_id    = each.value.vsan_id
  fcoe_vlan  = each.value.fcoe_vlan
  vsan_scope = each.value.vsan_scope

  fc_network_policy {
    object_type = "fabric.FcNetworkPolicy"
    moid        = intersight_fabric_fc_network_policy.vsan_policy[each.value.policy_key].moid
  }

  lifecycle {
    # default_zoning is deprecated in the Intersight API (sunset 2027-03-01) and
    # exhibits provider-level drift between applies — ignore it.
    ignore_changes = [default_zoning]
  }
}
