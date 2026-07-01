locals {
  fibre_channel_adapter_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.fibre_channel_adapter, []) :
      try(policy.managed, true) ? [{
        key                         = format("%s/%s", org.name, policy.name)
        org_name                    = org.name
        name                        = policy.name
        description                 = try(policy.description, local.defaults.compute.intersight.organizations.policies.fibre_channel_adapter.description, "")
        error_detection_timeout     = try(policy.error_detection_timeout, local.defaults.compute.intersight.organizations.policies.fibre_channel_adapter.error_detection_timeout)
        io_throttle_count           = try(policy.io_throttle_count, local.defaults.compute.intersight.organizations.policies.fibre_channel_adapter.io_throttle_count)
        lun_count                   = try(policy.lun_count, local.defaults.compute.intersight.organizations.policies.fibre_channel_adapter.lun_count)
        lun_queue_depth             = try(policy.lun_queue_depth, local.defaults.compute.intersight.organizations.policies.fibre_channel_adapter.lun_queue_depth)
        resource_allocation_timeout = try(policy.resource_allocation_timeout, local.defaults.compute.intersight.organizations.policies.fibre_channel_adapter.resource_allocation_timeout)
        interrupt_mode              = try(policy.interrupt_mode, null)
        flogi_retries               = try(policy.flogi_retries, null)
        flogi_timeout               = try(policy.flogi_timeout, null)
        plogi_retries               = try(policy.plogi_retries, null)
        plogi_timeout               = try(policy.plogi_timeout, null)
        rx_queue_ring_size          = try(policy.rx_queue_ring_size, null)
        scsi_queue_ring_size        = try(policy.scsi_queue_ring_size, null)
        tx_queue_ring_size          = try(policy.tx_queue_ring_size, null)
        error_recovery_settings     = try(policy.error_recovery_settings, null)
      }] : []
    ]
  ])
}

resource "intersight_vnic_fc_adapter_policy" "fibre_channel_adapter_policy" {
  for_each = { for p in local.fibre_channel_adapter_policies : p.key => p }

  name                        = each.value.name
  description                 = each.value.description
  error_detection_timeout     = each.value.error_detection_timeout
  io_throttle_count           = each.value.io_throttle_count
  lun_count                   = each.value.lun_count
  lun_queue_depth             = each.value.lun_queue_depth
  resource_allocation_timeout = each.value.resource_allocation_timeout

  dynamic "error_recovery_settings" {
    for_each = each.value.error_recovery_settings != null ? [each.value.error_recovery_settings] : []
    content {
      object_type       = "vnic.FcErrorRecoverySettings"
      enabled           = try(error_recovery_settings.value.enabled, null)
      io_retry_count    = try(error_recovery_settings.value.io_retry_count, null)
      io_retry_timeout  = try(error_recovery_settings.value.io_retry_timeout, null)
      link_down_timeout = try(error_recovery_settings.value.link_down_timeout, null)
      port_down_timeout = try(error_recovery_settings.value.port_down_timeout, null)
    }
  }

  dynamic "flogi_settings" {
    for_each = (each.value.flogi_retries != null || each.value.flogi_timeout != null) ? [1] : []
    content {
      object_type = "vnic.FlogiSettings"
      retries     = each.value.flogi_retries
      timeout     = each.value.flogi_timeout
    }
  }

  dynamic "interrupt_settings" {
    for_each = each.value.interrupt_mode != null ? [1] : []
    content {
      object_type = "vnic.FcInterruptSettings"
      mode        = each.value.interrupt_mode
    }
  }

  dynamic "plogi_settings" {
    for_each = (each.value.plogi_retries != null || each.value.plogi_timeout != null) ? [1] : []
    content {
      object_type = "vnic.PlogiSettings"
      retries     = each.value.plogi_retries
      timeout     = each.value.plogi_timeout
    }
  }

  dynamic "rx_queue_settings" {
    for_each = each.value.rx_queue_ring_size != null ? [1] : []
    content {
      object_type = "vnic.FcQueueSettings"
      ring_size   = each.value.rx_queue_ring_size
    }
  }

  dynamic "scsi_queue_settings" {
    for_each = each.value.scsi_queue_ring_size != null ? [1] : []
    content {
      object_type = "vnic.ScsiQueueSettings"
      ring_size   = each.value.scsi_queue_ring_size
    }
  }

  dynamic "tx_queue_settings" {
    for_each = each.value.tx_queue_ring_size != null ? [1] : []
    content {
      object_type = "vnic.FcQueueSettings"
      ring_size   = each.value.tx_queue_ring_size
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
