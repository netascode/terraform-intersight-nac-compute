locals {
  san_connectivity_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.san_connectivity, []) :
      try(policy.managed, true) ? [{
        key                 = format("%s/%s", org.name, policy.name)
        org_name            = org.name
        name                = policy.name
        description         = try(policy.description, local.defaults.compute.intersight.organizations.policies.san_connectivity.description, "")
        target_platform     = try(policy.target_platform, local.defaults.compute.intersight.organizations.policies.san_connectivity.target_platform)
        vhba_placement_mode = try(policy.vhba_placement_mode, local.defaults.compute.intersight.organizations.policies.san_connectivity.vhba_placement_mode)
        wwnn_pool_key       = try(policy.wwnn_pool, null) != null ? format("%s/%s", org.name, policy.wwnn_pool) : null
        vhbas = [
          for vhba in try(policy.vhbas, []) : {
            key                   = format("%s/%s/%s", org.name, policy.name, vhba.name)
            policy_key            = format("%s/%s", org.name, policy.name)
            org_name              = org.name
            name                  = vhba.name
            order                 = try(vhba.order, local.defaults.compute.intersight.organizations.policies.san_connectivity.vhbas.order)
            fabric                = try(vhba.fabric, local.defaults.compute.intersight.organizations.policies.san_connectivity.vhbas.fabric)
            slot                  = try(vhba.slot, null)
            pci_link              = try(vhba.pci_link, null)
            uplink                = try(vhba.uplink, null)
            auto_pci_link         = try(vhba.auto_pci_link, null)
            auto_slot_id          = try(vhba.auto_slot_id, null)
            persistent_bindings   = try(vhba.persistent_lun_bindings, null)
            vhba_type             = try(vhba.vhba_type, local.defaults.compute.intersight.organizations.policies.san_connectivity.vhbas.vhba_type)
            wwpn_pool_key         = try(vhba.wwpn_pool, null) != null ? format("%s/%s", org.name, vhba.wwpn_pool) : null
            fc_adapter_policy_key = try(vhba.fibre_channel_adapter_policy, null) != null ? format("%s/%s", org.name, vhba.fibre_channel_adapter_policy) : null
            fc_network_policy_key = try(vhba.fibre_channel_network_policy, null) != null ? format("%s/%s", org.name, vhba.fibre_channel_network_policy) : null
            fc_qos_policy_key     = try(vhba.fibre_channel_qos_policy, null) != null ? format("%s/%s", org.name, vhba.fibre_channel_qos_policy) : null
          }
        ]
      }] : []
    ]
  ])

  san_connectivity_vhbas = flatten([
    for policy in local.san_connectivity_policies : policy.vhbas
  ])
}

resource "intersight_vnic_san_connectivity_policy" "san_connectivity_policy" {
  for_each = { for p in local.san_connectivity_policies : p.key => p }

  name              = each.value.name
  description       = each.value.description
  placement_mode    = each.value.vhba_placement_mode
  target_platform   = each.value.target_platform
  wwnn_address_type = each.value.wwnn_pool_key != null ? "POOL" : "STATIC"

  dynamic "wwnn_pool" {
    for_each = each.value.wwnn_pool_key != null ? [1] : []
    content {
      object_type = "fcpool.Pool"
      moid        = intersight_fcpool_pool.wwnn_pool[each.value.wwnn_pool_key].moid
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}

resource "intersight_vnic_fc_if" "vnic_fc_if" {
  for_each = { for v in local.san_connectivity_vhbas : v.key => v }

  name                = each.value.name
  order               = each.value.order
  persistent_bindings = each.value.persistent_bindings
  type                = each.value.vhba_type
  wwpn_address_type   = each.value.wwpn_pool_key != null ? "POOL" : "STATIC"

  placement {
    object_type   = "vnic.PlacementSettings"
    switch_id     = each.value.fabric
    auto_slot_id  = each.value.auto_slot_id != null ? each.value.auto_slot_id : each.value.slot == null
    id            = each.value.slot != null ? each.value.slot : ""
    auto_pci_link = each.value.auto_pci_link != null ? each.value.auto_pci_link : each.value.pci_link == null
    pci_link      = each.value.pci_link != null ? each.value.pci_link : 0
    uplink        = each.value.uplink
  }

  dynamic "wwpn_pool" {
    for_each = each.value.wwpn_pool_key != null ? [1] : []
    content {
      object_type = "fcpool.Pool"
      moid        = intersight_fcpool_pool.wwpn_pool[each.value.wwpn_pool_key].moid
    }
  }

  dynamic "fc_adapter_policy" {
    for_each = each.value.fc_adapter_policy_key != null ? [1] : []
    content {
      object_type = "vnic.FcAdapterPolicy"
      moid        = intersight_vnic_fc_adapter_policy.fibre_channel_adapter_policy[each.value.fc_adapter_policy_key].moid
    }
  }

  dynamic "fc_network_policy" {
    for_each = each.value.fc_network_policy_key != null ? [1] : []
    content {
      object_type = "vnic.FcNetworkPolicy"
      moid        = intersight_vnic_fc_network_policy.fibre_channel_network_policy[each.value.fc_network_policy_key].moid
    }
  }

  dynamic "fc_qos_policy" {
    for_each = each.value.fc_qos_policy_key != null ? [1] : []
    content {
      object_type = "vnic.FcQosPolicy"
      moid        = intersight_vnic_fc_qos_policy.fibre_channel_qos_policy[each.value.fc_qos_policy_key].moid
    }
  }

  san_connectivity_policy {
    object_type = "vnic.SanConnectivityPolicy"
    moid        = intersight_vnic_san_connectivity_policy.san_connectivity_policy[each.value.policy_key].moid
  }

  depends_on = [intersight_vnic_san_connectivity_policy.san_connectivity_policy]
}
