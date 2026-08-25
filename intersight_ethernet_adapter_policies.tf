locals {
  ethernet_adapter_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.ethernet_adapter, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.ethernet_adapter,
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

resource "intersight_vnic_eth_adapter_policy" "ethernet_adapter_policy" {
  for_each = { for p in local.ethernet_adapter_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = try(each.value.description, "")

  advanced_filter               = try(each.value.advanced_filter, null)
  ether_channel_pinning_enabled = try(each.value.ether_channel_pinning, null)
  geneve_enabled                = try(each.value.geneve, null)
  interrupt_scaling             = try(each.value.interrupt_scaling, null)
  rss_settings                  = try(each.value.rss, null)
  uplink_failback_timeout       = try(each.value.uplink_failback_timeout, null)

  dynamic "arfs_settings" {
    for_each = try(each.value.arfs, null) != null ? [1] : []
    content {
      enabled     = each.value.arfs
      object_type = "vnic.ArfsSettings"
    }
  }

  dynamic "completion_queue_settings" {
    for_each = try(each.value.completion_queue_settings, null) != null ? [each.value.completion_queue_settings] : []
    content {
      nr_count    = try(completion_queue_settings.value.nr_count, null)
      ring_size   = try(completion_queue_settings.value.ring_size, null)
      object_type = "vnic.CompletionQueueSettings"
    }
  }

  dynamic "interrupt_settings" {
    for_each = try(each.value.interrupt_settings, null) != null ? [each.value.interrupt_settings] : []
    content {
      coalescing_time = try(interrupt_settings.value.coalescing_time, null)
      coalescing_type = try(interrupt_settings.value.coalescing_type, null)
      nr_count        = try(interrupt_settings.value.nr_count, null)
      mode            = try(interrupt_settings.value.mode, null)
      object_type     = "vnic.EthInterruptSettings"
    }
  }

  dynamic "nvgre_settings" {
    for_each = try(each.value.nvgre, null) != null ? [1] : []
    content {
      enabled     = each.value.nvgre
      object_type = "vnic.NvgreSettings"
    }
  }

  dynamic "ptp_settings" {
    for_each = try(each.value.ptp, null) != null ? [1] : []
    content {
      enabled     = each.value.ptp
      object_type = "vnic.PtpSettings"
    }
  }

  dynamic "roce_settings" {
    for_each = try(each.value.roce_settings, null) != null ? [each.value.roce_settings] : []
    content {
      enabled          = try(roce_settings.value.enabled, null)
      class_of_service = try(roce_settings.value.class_of_service, null)
      memory_regions   = try(roce_settings.value.memory_regions, null)
      queue_pairs      = try(roce_settings.value.queue_pairs, null)
      resource_groups  = try(roce_settings.value.resource_groups, null)
      nr_version       = try(roce_settings.value.version, null)
      object_type      = "vnic.RoceSettings"
    }
  }

  dynamic "rss_hash_settings" {
    for_each = try(each.value.rss_hash_settings, null) != null ? [each.value.rss_hash_settings] : []
    content {
      ipv4_hash         = try(rss_hash_settings.value.ipv4_hash, null)
      ipv6_ext_hash     = try(rss_hash_settings.value.ipv6_ext_hash, null)
      ipv6_hash         = try(rss_hash_settings.value.ipv6_hash, null)
      tcp_ipv4_hash     = try(rss_hash_settings.value.tcp_ipv4_hash, null)
      tcp_ipv6_ext_hash = try(rss_hash_settings.value.tcp_ipv6_ext_hash, null)
      tcp_ipv6_hash     = try(rss_hash_settings.value.tcp_ipv6_hash, null)
      udp_ipv4_hash     = try(rss_hash_settings.value.udp_ipv4_hash, null)
      udp_ipv6_hash     = try(rss_hash_settings.value.udp_ipv6_hash, null)
      object_type       = "vnic.RssHashSettings"
    }
  }

  dynamic "rx_queue_settings" {
    for_each = try(each.value.rx_queue_settings, null) != null ? [each.value.rx_queue_settings] : []
    content {
      nr_count    = try(rx_queue_settings.value.nr_count, null)
      ring_size   = try(rx_queue_settings.value.ring_size, null)
      object_type = "vnic.EthRxQueueSettings"
    }
  }

  dynamic "tcp_offload_settings" {
    for_each = try(each.value.tcp_offload_settings, null) != null ? [each.value.tcp_offload_settings] : []
    content {
      large_receive = try(tcp_offload_settings.value.large_receive, null)
      large_send    = try(tcp_offload_settings.value.large_send, null)
      rx_checksum   = try(tcp_offload_settings.value.rx_checksum, null)
      tx_checksum   = try(tcp_offload_settings.value.tx_checksum, null)
      object_type   = "vnic.TcpOffloadSettings"
    }
  }

  dynamic "tx_queue_settings" {
    for_each = try(each.value.tx_queue_settings, null) != null ? [each.value.tx_queue_settings] : []
    content {
      nr_count    = try(tx_queue_settings.value.nr_count, null)
      ring_size   = try(tx_queue_settings.value.ring_size, null)
      object_type = "vnic.EthTxQueueSettings"
    }
  }

  dynamic "vxlan_settings" {
    for_each = try(each.value.vxlan, null) != null ? [1] : []
    content {
      enabled     = each.value.vxlan
      object_type = "vnic.VxlanSettings"
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
