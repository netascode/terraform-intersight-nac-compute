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
        error_recovery_settings     = try(policy.error_recovery_settings, null)
        flogi_settings              = try(policy.flogi_settings, null)
        interrupt_settings          = try(policy.interrupt_settings, null)
        plogi_settings              = try(policy.plogi_settings, null)
        rx_queue_settings           = try(policy.rx_queue_settings, null)
        scsi_queue_settings         = try(policy.scsi_queue_settings, null)
        tx_queue_settings           = try(policy.tx_queue_settings, null)
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
    for_each = each.value.flogi_settings != null ? [each.value.flogi_settings] : []
    content {
      object_type = "vnic.FlogiSettings"
      retries     = try(flogi_settings.value.retries, null)
      timeout     = try(flogi_settings.value.timeout, null)
    }
  }

  dynamic "interrupt_settings" {
    for_each = each.value.interrupt_settings != null ? [each.value.interrupt_settings] : []
    content {
      object_type = "vnic.FcInterruptSettings"
      mode        = try(interrupt_settings.value.mode, null)
    }
  }

  dynamic "plogi_settings" {
    for_each = each.value.plogi_settings != null ? [each.value.plogi_settings] : []
    content {
      object_type = "vnic.PlogiSettings"
      retries     = try(plogi_settings.value.retries, null)
      timeout     = try(plogi_settings.value.timeout, null)
    }
  }

  dynamic "rx_queue_settings" {
    for_each = each.value.rx_queue_settings != null ? [each.value.rx_queue_settings] : []
    content {
      object_type = "vnic.FcQueueSettings"
      ring_size   = try(rx_queue_settings.value.ring_size, null)
    }
  }

  dynamic "scsi_queue_settings" {
    for_each = each.value.scsi_queue_settings != null ? [each.value.scsi_queue_settings] : []
    content {
      object_type = "vnic.ScsiQueueSettings"
      ring_size   = try(scsi_queue_settings.value.ring_size, null)
    }
  }

  dynamic "tx_queue_settings" {
    for_each = each.value.tx_queue_settings != null ? [each.value.tx_queue_settings] : []
    content {
      object_type = "vnic.FcQueueSettings"
      ring_size   = try(tx_queue_settings.value.ring_size, null)
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
