locals {
  lan_connectivity_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.lan_connectivity, []) :
      try(policy.managed, true) ? [{
        key                 = format("%s/%s", org.name, policy.name)
        org_name            = org.name
        name                = policy.name
        description         = try(policy.description, local.defaults.compute.intersight.organizations.policies.lan_connectivity.description, "")
        target_platform     = try(policy.target_platform, local.defaults.compute.intersight.organizations.policies.lan_connectivity.target_platform)
        vnic_placement_mode = try(policy.vnic_placement_mode, local.defaults.compute.intersight.organizations.policies.lan_connectivity.vnic_placement_mode)
        iqn_allocation_type = try(policy.iqn_allocation_type, local.defaults.compute.intersight.organizations.policies.lan_connectivity.iqn_allocation_type)
        vnics = [
          for vnic in try(policy.vnics, []) : {
            key                                 = format("%s/%s/%s", org.name, policy.name, vnic.name)
            policy_key                          = format("%s/%s", org.name, policy.name)
            org_name                            = org.name
            name                                = vnic.name
            order                               = try(vnic.order, local.defaults.compute.intersight.organizations.policies.lan_connectivity.vnics.order)
            fabric                              = try(vnic.fabric, local.defaults.compute.intersight.organizations.policies.lan_connectivity.vnics.fabric)
            failover                            = try(vnic.failover, local.defaults.compute.intersight.organizations.policies.lan_connectivity.vnics.failover)
            slot                                = try(vnic.slot, null)
            pci_link                            = try(vnic.pci_link, null)
            mac_pool_key                        = try(vnic.mac_pool, null) != null ? format("%s/%s", org.name, vnic.mac_pool) : null
            ethernet_adapter_policy_key         = try(vnic.ethernet_adapter_policy, null) != null ? format("%s/%s", org.name, vnic.ethernet_adapter_policy) : null
            ethernet_network_control_policy_key = try(vnic.ethernet_network_control_policy, null) != null ? format("%s/%s", org.name, vnic.ethernet_network_control_policy) : null
            ethernet_network_policy_key         = try(vnic.ethernet_network_policy, null) != null ? format("%s/%s", org.name, vnic.ethernet_network_policy) : null
            ethernet_network_group_policy_key   = try(vnic.ethernet_network_group_policy, null) != null ? format("%s/%s", org.name, vnic.ethernet_network_group_policy) : null
            ethernet_qos_policy_key             = try(vnic.ethernet_qos_policy, null) != null ? format("%s/%s", org.name, vnic.ethernet_qos_policy) : null
            vnic_template_key                   = try(vnic.vnic_template, null) != null ? format("%s/%s", org.name, vnic.vnic_template) : null
            iscsi_boot_policy_key               = try(vnic.iscsi_boot_policy, null) != null ? format("%s/%s", org.name, vnic.iscsi_boot_policy) : null
          }
        ]
      }] : []
    ]
  ])

  lan_connectivity_vnics = flatten([
    for policy in local.lan_connectivity_policies : policy.vnics
  ])
}

resource "intersight_vnic_lan_connectivity_policy" "lan_connectivity_policy" {
  for_each = { for p in local.lan_connectivity_policies : p.key => p if var.manage_intersight_policies }

  description         = each.value.description
  iqn_allocation_type = each.value.iqn_allocation_type
  name                = each.value.name
  placement_mode      = each.value.vnic_placement_mode
  target_platform     = each.value.target_platform

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

resource "intersight_vnic_eth_if" "vnic_eth_if" {
  for_each = { for v in local.lan_connectivity_vnics : v.key => v if var.manage_intersight_policies }

  failover_enabled = each.value.failover
  mac_address_type = each.value.mac_pool_key != null ? "POOL" : "STATIC"
  name             = each.value.name
  order            = each.value.order

  placement {
    object_type   = "vnic.PlacementSettings"
    switch_id     = each.value.fabric
    auto_slot_id  = each.value.slot == null
    id            = each.value.slot != null ? each.value.slot : ""
    auto_pci_link = each.value.pci_link == null
    pci_link      = each.value.pci_link != null ? each.value.pci_link : 0
  }

  dynamic "mac_pool" {
    for_each = each.value.mac_pool_key != null ? [1] : []
    content {
      object_type = "macpool.Pool"
      moid        = local.mac_pool_moids[each.value.mac_pool_key]
    }
  }

  dynamic "eth_adapter_policy" {
    for_each = each.value.ethernet_adapter_policy_key != null ? [1] : []
    content {
      object_type = "vnic.EthAdapterPolicy"
      moid        = local.ethernet_adapter_policy_moids[each.value.ethernet_adapter_policy_key]
    }
  }

  dynamic "fabric_eth_network_control_policy" {
    for_each = each.value.ethernet_network_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkControlPolicy"
      moid        = local.ethernet_network_control_policy_moids[each.value.ethernet_network_control_policy_key]
    }
  }

  dynamic "eth_network_policy" {
    for_each = each.value.ethernet_network_policy_key != null ? [1] : []
    content {
      object_type = "vnic.EthNetworkPolicy"
      moid        = local.ethernet_network_policy_moids[each.value.ethernet_network_policy_key]
    }
  }

  dynamic "fabric_eth_network_group_policy" {
    for_each = each.value.ethernet_network_group_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkGroupPolicy"
      moid        = local.ethernet_network_group_policy_moids[each.value.ethernet_network_group_policy_key]
    }
  }

  dynamic "eth_qos_policy" {
    for_each = each.value.ethernet_qos_policy_key != null ? [1] : []
    content {
      object_type = "vnic.EthQosPolicy"
      moid        = local.ethernet_qos_policy_moids[each.value.ethernet_qos_policy_key]
    }
  }

  dynamic "src_template" {
    for_each = each.value.vnic_template_key != null ? [1] : []
    content {
      object_type = "vnic.VnicTemplate"
      moid        = local.vnic_template_moids[each.value.vnic_template_key]
    }
  }

  dynamic "iscsi_boot_policy" {
    for_each = each.value.iscsi_boot_policy_key != null ? [1] : []
    content {
      object_type = "vnic.IscsiBootPolicy"
      moid        = local.iscsi_boot_policy_moids[each.value.iscsi_boot_policy_key]
    }
  }

  lan_connectivity_policy {
    object_type = "vnic.LanConnectivityPolicy"
    moid        = intersight_vnic_lan_connectivity_policy.lan_connectivity_policy[each.value.policy_key].moid
  }

  depends_on = [intersight_vnic_lan_connectivity_policy.lan_connectivity_policy]
}
