locals {
  vlan_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.vlan, []) :
      try(policy.managed, true) ? [{
        key         = format("%s/%s", org.name, policy.name)
        org_name    = org.name
        name        = policy.name
        description = try(policy.description, local.defaults.compute.intersight.organizations.policies.vlan.description, "")
        tags        = try(policy.tags, [])
        vlans       = try(policy.vlans, [])
      }] : []
    ]
  ])

  vlan_policies_map = { for p in local.vlan_policies : p.key => p }

  policy_vlan_entries = flatten([
    for p in local.vlan_policies : [
      for v in p.vlans : {
        key              = format("%s/%s", p.key, v.name)
        vlan_list        = v.vlan_list
        multicast_policy = try(v.multicast_policy, null)
      }
    ]
  ])

  # Expand each vlan entry's `vlan_list` range string (e.g. "1-5,10,20-22") into a flat list of VLAN IDs.
  vlan_id_lists = {
    for entry in local.policy_vlan_entries : entry.key => flatten([
      for part in split(",", trimspace(entry.vlan_list)) :
      length(split("-", part)) == 2 ?
      [for i in range(tonumber(split("-", part)[0]), tonumber(split("-", part)[1]) + 1) : i] :
      [tonumber(part)]
    ])
  }

  vlans = flatten([
    for policy in local.vlan_policies : [
      for entry in policy.vlans : [
        for vlan_id in local.vlan_id_lists[format("%s/%s", policy.key, entry.name)] : {
          key                   = format("%s/%s/%d", policy.key, entry.name, vlan_id)
          policy_key            = policy.key
          org_name              = policy.org_name
          vlan_id               = vlan_id
          name                  = length(local.vlan_id_lists[format("%s/%s", policy.key, entry.name)]) > 1 ? format("%s-%d", entry.name, vlan_id) : entry.name
          native_vlan           = try(entry.native_vlan, local.defaults.compute.intersight.organizations.policies.vlan.vlans.native_vlan)
          auto_allow_on_uplinks = try(entry.auto_allow_on_uplinks, local.defaults.compute.intersight.organizations.policies.vlan.vlans.auto_allow_on_uplinks)
          sharing_type          = try(entry.sharing_type, local.defaults.compute.intersight.organizations.policies.vlan.vlans.sharing_type)
          primary_vlan_id       = try(entry.primary_vlan_id, local.defaults.compute.intersight.organizations.policies.vlan.vlans.primary_vlan_id)
          multicast_policy      = try(entry.multicast_policy, null)
        }
      ]
    ]
  ])

  # Only look up multicast policies that are explicitly referenced
  multicast_policy_lookups = {
    for v in local.vlans : format("%s/%s", v.org_name, v.multicast_policy) => {
      org_name = v.org_name
      name     = v.multicast_policy
    }...
    if v.multicast_policy != null
  }
}

data "intersight_fabric_multicast_policy" "multicast_policy" {
  for_each = { for k, v in local.multicast_policy_lookups : k => v[0] }

  name = each.value.name
  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}

resource "intersight_fabric_eth_network_policy" "vlan_policy" {
  for_each = local.vlan_policies_map

  name        = each.value.name
  description = each.value.description

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

resource "intersight_fabric_vlan" "vlan" {
  for_each = { for v in local.vlans : v.key => v }

  name                  = each.value.name
  vlan_id               = each.value.vlan_id
  is_native             = each.value.native_vlan
  auto_allow_on_uplinks = each.value.auto_allow_on_uplinks
  sharing_type          = each.value.sharing_type
  primary_vlan_id       = each.value.primary_vlan_id

  eth_network_policy {
    object_type = "fabric.EthNetworkPolicy"
    moid        = intersight_fabric_eth_network_policy.vlan_policy[each.value.policy_key].moid
  }

  dynamic "multicast_policy" {
    for_each = each.value.multicast_policy != null ? [1] : []
    content {
      object_type = "fabric.MulticastPolicy"
      moid        = data.intersight_fabric_multicast_policy.multicast_policy[format("%s/%s", each.value.org_name, each.value.multicast_policy)].results[0].moid
    }
  }
}
