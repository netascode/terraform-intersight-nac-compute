locals {
  server_templates = flatten([
    for org in local.filtered_intersight_organizations : [
      for tmpl in try(org.templates.server, []) :
      try(tmpl.managed, true) ? [{
        key                               = format("%s/%s", org.name, tmpl.name)
        org_name                          = org.name
        name                              = tmpl.name
        tags                              = try(tmpl.tags, [])
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
        firmware_policy_key               = try(tmpl.firmware_policy, null) != null ? format("%s/%s", org.name, tmpl.firmware_policy) : null
        virtual_kvm_policy_key            = try(tmpl.virtual_kvm_policy, null) != null ? format("%s/%s", org.name, tmpl.virtual_kvm_policy) : null
        virtual_media_policy_key          = try(tmpl.virtual_media_policy, null) != null ? format("%s/%s", org.name, tmpl.virtual_media_policy) : null
        ldap_policy_key                   = try(tmpl.ldap_policy, null) != null ? format("%s/%s", org.name, tmpl.ldap_policy) : null
        uuid_pool_key                     = try(tmpl.uuid_pool, null) != null ? format("%s/%s", org.name, tmpl.uuid_pool) : null
      }] : []
    ]
  ])

  # The policies a server profile or server profile template can reference, by data model field: the
  # Intersight object type in its policy bucket, and the map that resolves a policy key to its Moid.
  # Shared by server profile templates and by servers that set per-server policies.
  server_policy_object_types = {
    bios_policy                   = "bios.Policy"
    certificate_management_policy = "certificatemanagement.Policy"
    boot_order_policy             = "boot.PrecisionPolicy"
    imc_access_policy             = "access.Policy"
    ipmi_over_lan_policy          = "ipmioverlan.Policy"
    lan_connectivity_policy       = "vnic.LanConnectivityPolicy"
    local_user_policy             = "iam.EndPointUserPolicy"
    network_connectivity_policy   = "networkconfig.Policy"
    ntp_policy                    = "ntp.Policy"
    power_policy                  = "power.Policy"
    san_connectivity_policy       = "vnic.SanConnectivityPolicy"
    serial_over_lan_policy        = "sol.Policy"
    scrub_policy                  = "compute.ScrubPolicy"
    drive_security_policy         = "storage.DriveSecurityPolicy"
    adapter_configuration_policy  = "adapter.ConfigPolicy"
    device_connector_policy       = "deviceconnector.Policy"
    sd_card_policy                = "sdcard.Policy"
    memory_policy                 = "memory.Policy"
    persistent_memory_policy      = "memory.PersistentMemoryPolicy"
    smtp_policy                   = "smtp.Policy"
    snmp_policy                   = "snmp.Policy"
    ssh_policy                    = "ssh.Policy"
    storage_policy                = "storage.StoragePolicy"
    syslog_policy                 = "syslog.Policy"
    thermal_policy                = "thermal.Policy"
    firmware_policy               = "firmware.Policy"
    virtual_kvm_policy            = "kvm.Policy"
    virtual_media_policy          = "vmedia.Policy"
    ldap_policy                   = "iam.LdapPolicy"
  }

  server_policy_moids = {
    bios_policy                   = local.bios_policy_moids
    certificate_management_policy = local.certificate_management_policy_moids
    boot_order_policy             = local.boot_precision_policy_moids
    imc_access_policy             = local.imc_access_policy_moids
    ipmi_over_lan_policy          = local.ipmi_over_lan_policy_moids
    lan_connectivity_policy       = local.lan_connectivity_policy_moids
    local_user_policy             = local.local_user_policy_moids
    network_connectivity_policy   = local.network_connectivity_policy_moids
    ntp_policy                    = local.ntp_policy_moids
    power_policy                  = local.power_policy_moids
    san_connectivity_policy       = local.san_connectivity_policy_moids
    serial_over_lan_policy        = local.serial_over_lan_policy_moids
    scrub_policy                  = local.scrub_policy_moids
    drive_security_policy         = local.drive_security_policy_moids
    adapter_configuration_policy  = local.adapter_configuration_policy_moids
    device_connector_policy       = local.device_connector_policy_moids
    sd_card_policy                = local.sd_card_policy_moids
    memory_policy                 = local.memory_policy_moids
    persistent_memory_policy      = local.persistent_memory_policy_moids
    smtp_policy                   = local.smtp_policy_moids
    snmp_policy                   = local.snmp_policy_moids
    ssh_policy                    = local.ssh_policy_moids
    storage_policy                = local.storage_policy_moids
    syslog_policy                 = local.syslog_policy_moids
    thermal_policy                = local.thermal_policy_moids
    firmware_policy               = local.firmware_policy_moids
    virtual_kvm_policy            = local.virtual_kvm_policy_moids
    virtual_media_policy          = local.virtual_media_policy_moids
    ldap_policy                   = local.ldap_policy_moids
  }

  # Policy keys ("<org>/<policy>") of each server profile template, by data model field, for the policies it
  # sets. Built from the data model, including templates with managed: false or managed in another
  # workspace, as a server that overrides some of a template's policies takes the others from it.
  server_profile_template_policy_keys = merge([
    for org in local.filtered_intersight_organizations : {
      for tmpl in try(org.templates.server, []) : format("%s/%s", org.name, tmpl.name) => {
        for field in keys(local.server_policy_object_types) :
        field => format("%s/%s", org.name, tmpl[field]) if try(tmpl[field], null) != null
      }
    }
  ]...)

  # The other settings a server that overrides some of a template's policies takes from the template
  server_profile_template_settings = merge([
    for org in local.filtered_intersight_organizations : {
      for tmpl in try(org.templates.server, []) : format("%s/%s", org.name, tmpl.name) => {
        description     = try(tmpl.description, local.defaults.compute.intersight.organizations.templates.server.description, "")
        target_platform = try(tmpl.target_platform, local.defaults.compute.intersight.organizations.templates.server.target_platform)
        uuid_pool_key   = try(tmpl.uuid_pool, null) != null ? format("%s/%s", org.name, tmpl.uuid_pool) : null
      }
    }
  ]...)
}

resource "intersight_server_profile_template" "server_profile_template" {
  for_each = { for t in local.server_templates : t.key => t if var.manage_intersight_templates }

  description     = each.value.description
  name            = each.value.name
  target_platform = each.value.target_platform

  uuid_address_type = each.value.uuid_pool_key != null ? "POOL" : "NONE"

  # The policies are set in additional_properties rather than with the native policy_bucket. The provider misreads
  # firmware.Policy and boot.PrecisionPolicy entries in policy_bucket (known provider bug), which caused a perpetual
  # diff, so policy_bucket had to be ignored, and changes to a template's policies were never applied. Intersight
  # returns the policy bucket in the template's additional properties, which the provider compares with these,
  # ignoring the order of the policies, so changes are applied and an unchanged template shows no diff. The
  # native policy_bucket is optional and computed, so leaving it out of the configuration does not clear it.
  additional_properties = jsonencode({
    PolicyBucket = [
      for field, key in local.server_profile_template_policy_keys[each.key] : {
        ClassId    = "mo.MoRef"
        Moid       = local.server_policy_moids[field][key]
        ObjectType = local.server_policy_object_types[field]
      }
    ]
  })

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

  # Policy child objects are not referenced by the template; order them so they are created
  # before, and destroyed after, the templates and profiles that consume their policies
  depends_on = [
    intersight_iam_end_point_user.local_user,
    intersight_iam_end_point_user_role.local_user_role,
    intersight_vnic_eth_if.vnic_eth_if,
    intersight_vnic_fc_if.vnic_fc_if,
    intersight_storage_drive_group.storage_drive_group,
  ]
}
