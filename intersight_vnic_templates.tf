locals {
  vnic_templates = flatten([
    for org in local.filtered_intersight_organizations : [
      for tmpl in try(org.templates.vnic, []) :
      try(tmpl.managed, true) ? [{
        key                                 = format("%s/%s", org.name, tmpl.name)
        org_name                            = org.name
        name                                = tmpl.name
        description                         = try(tmpl.description, local.defaults.compute.intersight.organizations.templates.vnic.description, "")
        placement_switch_id                 = try(tmpl.placement_switch_id, local.defaults.compute.intersight.organizations.templates.vnic.placement_switch_id)
        failover                            = try(tmpl.failover, local.defaults.compute.intersight.organizations.templates.vnic.failover)
        allow_override                      = try(tmpl.allow_override, local.defaults.compute.intersight.organizations.templates.vnic.allow_override)
        pin_group_name                      = try(tmpl.pin_group_name, null)
        peer_vnic_name                      = try(tmpl.peer_vnic_name, null)
        cdn_source                          = try(tmpl.cdn_source, local.defaults.compute.intersight.organizations.templates.vnic.cdn_source)
        cdn_value                           = try(tmpl.cdn_value, null)
        tags                                = try(tmpl.tags, [])
        mac_pool_key                        = try(tmpl.mac_pool, null) != null ? format("%s/%s", org.name, tmpl.mac_pool) : null
        ethernet_adapter_policy_key         = try(tmpl.ethernet_adapter_policy, null) != null ? format("%s/%s", org.name, tmpl.ethernet_adapter_policy) : null
        ethernet_network_control_policy_key = try(tmpl.ethernet_network_control_policy, null) != null ? format("%s/%s", org.name, tmpl.ethernet_network_control_policy) : null
        ethernet_network_group_policy_key   = try(tmpl.ethernet_network_group_policy, null) != null ? format("%s/%s", org.name, tmpl.ethernet_network_group_policy) : null
        ethernet_network_policy_key         = try(tmpl.ethernet_network_policy, null) != null ? format("%s/%s", org.name, tmpl.ethernet_network_policy) : null
        ethernet_qos_policy_key             = try(tmpl.ethernet_qos_policy, null) != null ? format("%s/%s", org.name, tmpl.ethernet_qos_policy) : null
        sriov = try(tmpl.sriov, null) != null ? {
          enabled           = try(tmpl.sriov.enabled, false)
          vf_count          = try(tmpl.sriov.number_of_vfs, 64)
          rx_count_per_vf   = try(tmpl.sriov.receive_queue_count_per_vf, 4)
          tx_count_per_vf   = try(tmpl.sriov.transmit_queue_count_per_vf, 1)
          comp_count_per_vf = try(tmpl.sriov.completion_queue_count_per_vf, 5)
          int_count_per_vf  = try(tmpl.sriov.interrupt_count_per_vf, 8)
        } : null
        usnic = try(tmpl.usnic, null) != null ? {
          nr_count             = try(tmpl.usnic.number_of_usnics, 0)
          usnic_adapter_policy = try(tmpl.usnic.usnic_adapter_policy, "")
        } : null
        vmq = try(tmpl.vmq, null) != null ? {
          enabled             = try(tmpl.vmq.enabled, false)
          multi_queue_support = try(tmpl.vmq.virtual_machine_multi_queue, false)
          num_interrupts      = try(tmpl.vmq.number_of_interrupts, 16)
          num_vmqs            = try(tmpl.vmq.number_of_virtual_machine_queues, 4)
          num_sub_vnics       = try(tmpl.vmq.number_of_sub_vnics, 64)
          vmmq_adapter_policy = try(tmpl.vmq.vmmq_adapter_policy, "")
        } : null
      }] : []
    ]
  ])
}

resource "intersight_vnic_vnic_template" "vnic_template" {
  for_each = { for t in local.vnic_templates : t.key => t if var.manage_intersight_templates }

  description      = each.value.description
  enable_override  = each.value.allow_override
  failover_enabled = each.value.failover
  name             = each.value.name
  switch_id        = each.value.placement_switch_id

  cdn {
    object_type = "vnic.Cdn"
    nr_source   = each.value.cdn_source
    value       = each.value.cdn_source == "user" ? coalesce(each.value.cdn_value, "") : ""
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

  dynamic "fabric_eth_network_group_policy" {
    for_each = each.value.ethernet_network_group_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkGroupPolicy"
      moid        = local.ethernet_network_group_policy_moids[each.value.ethernet_network_group_policy_key]
    }
  }

  dynamic "eth_network_policy" {
    for_each = each.value.ethernet_network_policy_key != null ? [1] : []
    content {
      object_type = "vnic.EthNetworkPolicy"
      moid        = local.ethernet_network_policy_moids[each.value.ethernet_network_policy_key]
    }
  }

  dynamic "eth_qos_policy" {
    for_each = each.value.ethernet_qos_policy_key != null ? [1] : []
    content {
      object_type = "vnic.EthQosPolicy"
      moid        = local.ethernet_qos_policy_moids[each.value.ethernet_qos_policy_key]
    }
  }

  dynamic "sriov_settings" {
    for_each = each.value.sriov != null ? [each.value.sriov] : []
    content {
      object_type       = "vnic.SriovSettings"
      comp_count_per_vf = sriov_settings.value.comp_count_per_vf
      enabled           = sriov_settings.value.enabled
      int_count_per_vf  = sriov_settings.value.int_count_per_vf
      rx_count_per_vf   = sriov_settings.value.rx_count_per_vf
      tx_count_per_vf   = sriov_settings.value.tx_count_per_vf
      vf_count          = sriov_settings.value.vf_count
    }
  }

  dynamic "usnic_settings" {
    for_each = each.value.usnic != null ? [each.value.usnic] : []
    content {
      object_type          = "vnic.UsnicSettings"
      nr_count             = usnic_settings.value.nr_count
      usnic_adapter_policy = usnic_settings.value.usnic_adapter_policy
    }
  }

  dynamic "vmq_settings" {
    for_each = each.value.vmq != null ? [each.value.vmq] : []
    content {
      object_type         = "vnic.VmqSettings"
      enabled             = vmq_settings.value.enabled
      multi_queue_support = vmq_settings.value.multi_queue_support
      num_interrupts      = vmq_settings.value.num_interrupts
      num_sub_vnics       = vmq_settings.value.num_sub_vnics
      num_vmqs            = vmq_settings.value.num_vmqs
      vmmq_adapter_policy = vmq_settings.value.vmmq_adapter_policy
    }
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

