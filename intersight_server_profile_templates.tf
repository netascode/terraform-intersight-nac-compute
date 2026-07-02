locals {
  server_templates = flatten([
    for org in try(local.intersight.organizations, []) : [
      for tmpl in try(org.templates.server, []) :
      try(tmpl.managed, true) ? [{
        key                         = format("%s/%s", org.name, tmpl.name)
        org_name                    = org.name
        name                        = tmpl.name
        description                 = try(tmpl.description, local.defaults.compute.intersight.organizations.templates.server.description, "")
        target_platform             = try(tmpl.target_platform, local.defaults.compute.intersight.organizations.templates.server.target_platform)
        bios_policy_key             = try(tmpl.bios_policy, null) != null ? format("%s/%s", org.name, tmpl.bios_policy) : null
        boot_order_policy_key       = try(tmpl.boot_order_policy, null) != null ? format("%s/%s", org.name, tmpl.boot_order_policy) : null
        imc_access_policy_key       = try(tmpl.imc_access_policy, null) != null ? format("%s/%s", org.name, tmpl.imc_access_policy) : null
        lan_connectivity_policy_key = try(tmpl.lan_connectivity_policy, null) != null ? format("%s/%s", org.name, tmpl.lan_connectivity_policy) : null
        local_user_policy_key       = try(tmpl.local_user_policy, null) != null ? format("%s/%s", org.name, tmpl.local_user_policy) : null
        ntp_policy_key              = try(tmpl.ntp_policy, null) != null ? format("%s/%s", org.name, tmpl.ntp_policy) : null
        power_policy_key            = try(tmpl.power_policy, null) != null ? format("%s/%s", org.name, tmpl.power_policy) : null
        san_connectivity_policy_key = try(tmpl.san_connectivity_policy, null) != null ? format("%s/%s", org.name, tmpl.san_connectivity_policy) : null
        serial_over_lan_policy_key  = try(tmpl.serial_over_lan_policy, null) != null ? format("%s/%s", org.name, tmpl.serial_over_lan_policy) : null
        snmp_policy_key             = try(tmpl.snmp_policy, null) != null ? format("%s/%s", org.name, tmpl.snmp_policy) : null
        ssh_policy_key              = try(tmpl.ssh_policy, null) != null ? format("%s/%s", org.name, tmpl.ssh_policy) : null
        storage_policy_key          = try(tmpl.storage_policy, null) != null ? format("%s/%s", org.name, tmpl.storage_policy) : null
        syslog_policy_key           = try(tmpl.syslog_policy, null) != null ? format("%s/%s", org.name, tmpl.syslog_policy) : null
        thermal_policy_key          = try(tmpl.thermal_policy, null) != null ? format("%s/%s", org.name, tmpl.thermal_policy) : null
        # Known provider bug: firmware.Policy in policy_bucket is applied correctly but the provider
        # cannot detect it on subsequent reads, causing a perpetual diff. Tracked for fix in a future
        # provider version. The implementation is correct per the Intersight OpenAPI spec.
        firmware_policy_key      = try(tmpl.firmware_policy, null) != null ? format("%s/%s", org.name, tmpl.firmware_policy) : null
        virtual_kvm_policy_key   = try(tmpl.virtual_kvm_policy, null) != null ? format("%s/%s", org.name, tmpl.virtual_kvm_policy) : null
        virtual_media_policy_key = try(tmpl.virtual_media_policy, null) != null ? format("%s/%s", org.name, tmpl.virtual_media_policy) : null
        uuid_pool_key            = try(tmpl.uuid_pool, null) != null ? format("%s/%s", org.name, tmpl.uuid_pool) : null
      }] : []
    ]
  ])
}

resource "intersight_server_profile_template" "server_profile_template" {
  for_each = { for t in local.server_templates : t.key => t }

  description     = each.value.description
  name            = each.value.name
  target_platform = each.value.target_platform

  uuid_address_type = each.value.uuid_pool_key != null ? "POOL" : "NONE"

  dynamic "policy_bucket" {
    for_each = each.value.bios_policy_key != null ? [1] : []
    content {
      object_type = "bios.Policy"
      moid        = intersight_bios_policy.bios_policy[each.value.bios_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.boot_order_policy_key != null ? [1] : []
    content {
      object_type = "boot.PrecisionPolicy"
      moid        = intersight_boot_precision_policy.boot_precision_policy[each.value.boot_order_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.imc_access_policy_key != null ? [1] : []
    content {
      object_type = "access.Policy"
      moid        = intersight_access_policy.imc_access_policy[each.value.imc_access_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.lan_connectivity_policy_key != null ? [1] : []
    content {
      object_type = "vnic.LanConnectivityPolicy"
      moid        = intersight_vnic_lan_connectivity_policy.lan_connectivity_policy[each.value.lan_connectivity_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.local_user_policy_key != null ? [1] : []
    content {
      object_type = "iam.EndPointUserPolicy"
      moid        = intersight_iam_end_point_user_policy.local_user_policy[each.value.local_user_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ntp_policy_key != null ? [1] : []
    content {
      object_type = "ntp.Policy"
      moid        = intersight_ntp_policy.ntp_policy[each.value.ntp_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.power_policy_key != null ? [1] : []
    content {
      object_type = "power.Policy"
      moid        = intersight_power_policy.power_policy[each.value.power_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.san_connectivity_policy_key != null ? [1] : []
    content {
      object_type = "vnic.SanConnectivityPolicy"
      moid        = intersight_vnic_san_connectivity_policy.san_connectivity_policy[each.value.san_connectivity_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.serial_over_lan_policy_key != null ? [1] : []
    content {
      object_type = "sol.Policy"
      moid        = intersight_sol_policy.serial_over_lan_policy[each.value.serial_over_lan_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.snmp_policy_key != null ? [1] : []
    content {
      object_type = "snmp.Policy"
      moid        = intersight_snmp_policy.snmp_policy[each.value.snmp_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ssh_policy_key != null ? [1] : []
    content {
      object_type = "ssh.Policy"
      moid        = intersight_ssh_policy.ssh_policy[each.value.ssh_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.storage_policy_key != null ? [1] : []
    content {
      object_type = "storage.StoragePolicy"
      moid        = intersight_storage_storage_policy.storage_policy[each.value.storage_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.syslog_policy_key != null ? [1] : []
    content {
      object_type = "syslog.Policy"
      moid        = intersight_syslog_policy.syslog_policy[each.value.syslog_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.thermal_policy_key != null ? [1] : []
    content {
      object_type = "thermal.Policy"
      moid        = intersight_thermal_policy.thermal_policy[each.value.thermal_policy_key].moid
    }
  }

  # Known provider bug: applied correctly on first run but causes a perpetual diff on subsequent
  # plans. See comment in locals block. Remove this block once the provider bug is resolved.
  dynamic "policy_bucket" {
    for_each = each.value.firmware_policy_key != null ? [1] : []
    content {
      object_type = "firmware.Policy"
      moid        = intersight_firmware_policy.firmware_policy[each.value.firmware_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.virtual_kvm_policy_key != null ? [1] : []
    content {
      object_type = "kvm.Policy"
      moid        = intersight_kvm_policy.virtual_kvm_policy[each.value.virtual_kvm_policy_key].moid
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.virtual_media_policy_key != null ? [1] : []
    content {
      object_type = "vmedia.Policy"
      moid        = intersight_vmedia_policy.virtual_media_policy[each.value.virtual_media_policy_key].moid
    }
  }

  dynamic "uuid_pool" {
    for_each = each.value.uuid_pool_key != null ? [1] : []
    content {
      object_type = "uuidpool.Pool"
      moid        = intersight_uuidpool_pool.uuid_pool[each.value.uuid_pool_key].moid
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
