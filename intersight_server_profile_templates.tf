locals {
  server_templates = flatten([
    for org in local.filtered_intersight_organizations : [
      for tmpl in try(org.templates.server, []) :
      try(tmpl.managed, true) ? [{
        key                               = format("%s/%s", org.name, tmpl.name)
        org_name                          = org.name
        name                              = tmpl.name
        description                       = try(tmpl.description, local.defaults.compute.intersight.organizations.templates.server.description, "")
        target_platform                   = try(tmpl.target_platform, local.defaults.compute.intersight.organizations.templates.server.target_platform)
        bios_policy_key                   = try(tmpl.bios_policy, null) != null ? format("%s/%s", org.name, tmpl.bios_policy) : null
        certificate_management_policy_key = try(tmpl.certificate_management_policy, null) != null ? format("%s/%s", org.name, tmpl.certificate_management_policy) : null
        boot_order_policy_key             = try(tmpl.boot_order_policy, null) != null ? format("%s/%s", org.name, tmpl.boot_order_policy) : null
        imc_access_policy_key             = try(tmpl.imc_access_policy, null) != null ? format("%s/%s", org.name, tmpl.imc_access_policy) : null
        ipmi_over_lan_policy_key          = try(tmpl.ipmi_over_lan_policy, null) != null ? format("%s/%s", org.name, tmpl.ipmi_over_lan_policy) : null
        lan_connectivity_policy_key       = try(tmpl.lan_connectivity_policy, null) != null ? format("%s/%s", org.name, tmpl.lan_connectivity_policy) : null
        local_user_policy_key             = try(tmpl.local_user_policy, null) != null ? format("%s/%s", org.name, tmpl.local_user_policy) : null
        network_connectivity_policy_key   = try(tmpl.network_connectivity_policy, null) != null ? format("%s/%s", org.name, tmpl.network_connectivity_policy) : null
        ntp_policy_key                    = try(tmpl.ntp_policy, null) != null ? format("%s/%s", org.name, tmpl.ntp_policy) : null
        power_policy_key                  = try(tmpl.power_policy, null) != null ? format("%s/%s", org.name, tmpl.power_policy) : null
        san_connectivity_policy_key       = try(tmpl.san_connectivity_policy, null) != null ? format("%s/%s", org.name, tmpl.san_connectivity_policy) : null
        serial_over_lan_policy_key        = try(tmpl.serial_over_lan_policy, null) != null ? format("%s/%s", org.name, tmpl.serial_over_lan_policy) : null
        scrub_policy_key                  = try(tmpl.scrub_policy, null) != null ? format("%s/%s", org.name, tmpl.scrub_policy) : null
        drive_security_policy_key         = try(tmpl.drive_security_policy, null) != null ? format("%s/%s", org.name, tmpl.drive_security_policy) : null
        adapter_configuration_policy_key  = try(tmpl.adapter_configuration_policy, null) != null ? format("%s/%s", org.name, tmpl.adapter_configuration_policy) : null
        device_connector_policy_key       = try(tmpl.device_connector_policy, null) != null ? format("%s/%s", org.name, tmpl.device_connector_policy) : null
        sd_card_policy_key                = try(tmpl.sd_card_policy, null) != null ? format("%s/%s", org.name, tmpl.sd_card_policy) : null
        memory_policy_key                 = try(tmpl.memory_policy, null) != null ? format("%s/%s", org.name, tmpl.memory_policy) : null
        persistent_memory_policy_key      = try(tmpl.persistent_memory_policy, null) != null ? format("%s/%s", org.name, tmpl.persistent_memory_policy) : null
        smtp_policy_key                   = try(tmpl.smtp_policy, null) != null ? format("%s/%s", org.name, tmpl.smtp_policy) : null
        snmp_policy_key                   = try(tmpl.snmp_policy, null) != null ? format("%s/%s", org.name, tmpl.snmp_policy) : null
        ssh_policy_key                    = try(tmpl.ssh_policy, null) != null ? format("%s/%s", org.name, tmpl.ssh_policy) : null
        storage_policy_key                = try(tmpl.storage_policy, null) != null ? format("%s/%s", org.name, tmpl.storage_policy) : null
        syslog_policy_key                 = try(tmpl.syslog_policy, null) != null ? format("%s/%s", org.name, tmpl.syslog_policy) : null
        thermal_policy_key                = try(tmpl.thermal_policy, null) != null ? format("%s/%s", org.name, tmpl.thermal_policy) : null
        # Known provider bug: firmware.Policy in policy_bucket is applied correctly but the provider
        # cannot detect it on subsequent reads, causing a perpetual diff. Tracked for fix in a future
        # provider version. The implementation is correct per the Intersight OpenAPI spec.
        firmware_policy_key      = try(tmpl.firmware_policy, null) != null ? format("%s/%s", org.name, tmpl.firmware_policy) : null
        virtual_kvm_policy_key   = try(tmpl.virtual_kvm_policy, null) != null ? format("%s/%s", org.name, tmpl.virtual_kvm_policy) : null
        virtual_media_policy_key = try(tmpl.virtual_media_policy, null) != null ? format("%s/%s", org.name, tmpl.virtual_media_policy) : null
        ldap_policy_key          = try(tmpl.ldap_policy, null) != null ? format("%s/%s", org.name, tmpl.ldap_policy) : null
        uuid_pool_key            = try(tmpl.uuid_pool, null) != null ? format("%s/%s", org.name, tmpl.uuid_pool) : null
      }] : []
    ]
  ])
}

resource "intersight_server_profile_template" "server_profile_template" {
  for_each = { for t in local.server_templates : t.key => t if var.manage_intersight_templates }

  description     = each.value.description
  name            = each.value.name
  target_platform = each.value.target_platform

  uuid_address_type = each.value.uuid_pool_key != null ? "POOL" : "NONE"

  dynamic "policy_bucket" {
    for_each = each.value.bios_policy_key != null ? [1] : []
    content {
      object_type = "bios.Policy"
      moid        = local.bios_policy_moids[each.value.bios_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.certificate_management_policy_key != null ? [1] : []
    content {
      object_type = "certificatemanagement.Policy"
      moid        = local.certificate_management_policy_moids[each.value.certificate_management_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.boot_order_policy_key != null ? [1] : []
    content {
      object_type = "boot.PrecisionPolicy"
      moid        = local.boot_precision_policy_moids[each.value.boot_order_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.imc_access_policy_key != null ? [1] : []
    content {
      object_type = "access.Policy"
      moid        = local.imc_access_policy_moids[each.value.imc_access_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ipmi_over_lan_policy_key != null ? [1] : []
    content {
      object_type = "ipmioverlan.Policy"
      moid        = local.ipmi_over_lan_policy_moids[each.value.ipmi_over_lan_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.lan_connectivity_policy_key != null ? [1] : []
    content {
      object_type = "vnic.LanConnectivityPolicy"
      moid        = local.lan_connectivity_policy_moids[each.value.lan_connectivity_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.local_user_policy_key != null ? [1] : []
    content {
      object_type = "iam.EndPointUserPolicy"
      moid        = local.local_user_policy_moids[each.value.local_user_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.network_connectivity_policy_key != null ? [1] : []
    content {
      object_type = "networkconfig.Policy"
      moid        = local.network_connectivity_policy_moids[each.value.network_connectivity_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ntp_policy_key != null ? [1] : []
    content {
      object_type = "ntp.Policy"
      moid        = local.ntp_policy_moids[each.value.ntp_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.power_policy_key != null ? [1] : []
    content {
      object_type = "power.Policy"
      moid        = local.power_policy_moids[each.value.power_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.san_connectivity_policy_key != null ? [1] : []
    content {
      object_type = "vnic.SanConnectivityPolicy"
      moid        = local.san_connectivity_policy_moids[each.value.san_connectivity_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.serial_over_lan_policy_key != null ? [1] : []
    content {
      object_type = "sol.Policy"
      moid        = local.serial_over_lan_policy_moids[each.value.serial_over_lan_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.scrub_policy_key != null ? [1] : []
    content {
      object_type = "compute.ScrubPolicy"
      moid        = local.scrub_policy_moids[each.value.scrub_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.drive_security_policy_key != null ? [1] : []
    content {
      object_type = "storage.DriveSecurityPolicy"
      moid        = local.drive_security_policy_moids[each.value.drive_security_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.adapter_configuration_policy_key != null ? [1] : []
    content {
      object_type = "adapter.ConfigPolicy"
      moid        = local.adapter_configuration_policy_moids[each.value.adapter_configuration_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.device_connector_policy_key != null ? [1] : []
    content {
      object_type = "deviceconnector.Policy"
      moid        = local.device_connector_policy_moids[each.value.device_connector_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.sd_card_policy_key != null ? [1] : []
    content {
      object_type = "sdcard.Policy"
      moid        = local.sd_card_policy_moids[each.value.sd_card_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.memory_policy_key != null ? [1] : []
    content {
      object_type = "memory.Policy"
      moid        = local.memory_policy_moids[each.value.memory_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.persistent_memory_policy_key != null ? [1] : []
    content {
      object_type = "memory.PersistentMemoryPolicy"
      moid        = local.persistent_memory_policy_moids[each.value.persistent_memory_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.smtp_policy_key != null ? [1] : []
    content {
      object_type = "smtp.Policy"
      moid        = local.smtp_policy_moids[each.value.smtp_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.snmp_policy_key != null ? [1] : []
    content {
      object_type = "snmp.Policy"
      moid        = local.snmp_policy_moids[each.value.snmp_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ssh_policy_key != null ? [1] : []
    content {
      object_type = "ssh.Policy"
      moid        = local.ssh_policy_moids[each.value.ssh_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.storage_policy_key != null ? [1] : []
    content {
      object_type = "storage.StoragePolicy"
      moid        = local.storage_policy_moids[each.value.storage_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.syslog_policy_key != null ? [1] : []
    content {
      object_type = "syslog.Policy"
      moid        = local.syslog_policy_moids[each.value.syslog_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.thermal_policy_key != null ? [1] : []
    content {
      object_type = "thermal.Policy"
      moid        = local.thermal_policy_moids[each.value.thermal_policy_key]
    }
  }

  # Known provider bug: applied correctly on first run but causes a perpetual diff on subsequent
  # plans. See comment in locals block. Remove this block once the provider bug is resolved.
  dynamic "policy_bucket" {
    for_each = each.value.firmware_policy_key != null ? [1] : []
    content {
      object_type = "firmware.Policy"
      moid        = local.firmware_policy_moids[each.value.firmware_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.virtual_kvm_policy_key != null ? [1] : []
    content {
      object_type = "kvm.Policy"
      moid        = local.virtual_kvm_policy_moids[each.value.virtual_kvm_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.virtual_media_policy_key != null ? [1] : []
    content {
      object_type = "vmedia.Policy"
      moid        = local.virtual_media_policy_moids[each.value.virtual_media_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ldap_policy_key != null ? [1] : []
    content {
      object_type = "iam.LdapPolicy"
      moid        = local.ldap_policy_moids[each.value.ldap_policy_key]
    }
  }

  dynamic "uuid_pool" {
    for_each = each.value.uuid_pool_key != null ? [1] : []
    content {
      object_type = "uuidpool.Pool"
      moid        = local.uuid_pool_moids[each.value.uuid_pool_key]
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
