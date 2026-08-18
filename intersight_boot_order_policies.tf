locals {
  boot_object_types = {
    flex_mmc      = "boot.FlexMmc"
    http_boot     = "boot.Http"
    iscsi_boot    = "boot.Iscsi"
    local_cdd     = "boot.LocalCdd"
    local_disk    = "boot.LocalDisk"
    nvme          = "boot.Nvme"
    pch_storage   = "boot.PchStorage"
    pxe_boot      = "boot.Pxe"
    san_boot      = "boot.San"
    sd_card       = "boot.SdCard"
    uefi_shell    = "boot.UefiShell"
    usb           = "boot.Usb"
    virtual_media = "boot.VirtualMedia"
  }

  boot_device_defaults = {
    flex_mmc = { Subtype = "flexmmc-mapped-dvd" }
    http_boot = {
      InterfaceName = "", InterfaceSource = "name", IpConfigType = "DHCP",
      IpType        = "IPv4", MacAddress = "", Port = -1, Protocol = "HTTPS", Slot = "MLOM", Uri = ""
    }
    iscsi_boot    = { InterfaceName = "", Port = 0, Slot = "MLOM" }
    local_cdd     = {}
    local_disk    = { Slot = "MSTOR-RAID" }
    nvme          = {}
    pch_storage   = { Lun = 0 }
    pxe_boot      = { InterfaceName = "", InterfaceSource = "name", IpType = "IPv4", MacAddress = "", Port = -1, Slot = "MLOM" }
    san_boot      = { InterfaceName = "", Lun = 0, Slot = "MLOM", Wwpn = "20:00:00:25:B5:00:00:00" }
    sd_card       = { Lun = 0, Subtype = "SDCARD" }
    uefi_shell    = {}
    usb           = { Subtype = "usb-cd" }
    virtual_media = { Subtype = "kvm-mapped-dvd" }
  }

  boot_order_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.boot_order, []) :
      try(policy.managed, true) ? [{
        key         = format("%s/%s", org.name, policy.name)
        org_name    = org.name
        name        = policy.name
        description = try(policy.description, local.defaults.compute.intersight.organizations.policies.boot_order.description, "")
        boot_mode   = try(policy.boot_mode, local.defaults.compute.intersight.organizations.policies.boot_order.boot_mode)
        secure_boot = try(policy.secure_boot, local.defaults.compute.intersight.organizations.policies.boot_order.secure_boot)
        boot_devices = [
          for device in try(policy.boot_devices, []) : {
            enabled     = try(device.enabled, local.defaults.compute.intersight.organizations.policies.boot_order.boot_devices.enabled)
            name        = device.name
            object_type = local.boot_object_types[device.device_type]
            additional_properties = jsonencode(merge(
              local.boot_device_defaults[device.device_type],
              try(device.slot, null) != null ? { Slot = device.slot } : {},
              try(device.lun, null) != null ? { Lun = device.lun } : {},
              try(device.subtype, null) != null ? { Subtype = device.subtype } : {},
              try(device.interface_name, null) != null ? { InterfaceName = device.interface_name } : {},
              try(device.interface_source, null) != null ? { InterfaceSource = device.interface_source } : {},
              try(device.ip_type, null) != null ? { IpType = device.ip_type } : {},
              try(device.ip_config_type, null) != null ? { IpConfigType = device.ip_config_type } : {},
              try(device.mac_address, null) != null ? { MacAddress = device.mac_address } : {},
              try(device.port, null) != null ? { Port = device.port } : {},
              try(device.protocol, null) != null ? { Protocol = device.protocol } : {},
              try(device.target_wwpn, null) != null ? { Wwpn = device.target_wwpn } : {},
              try(device.uri, null) != null ? { Uri = device.uri } : {},
              try(device.ipv4_config, null) != null ? {
                StaticIpV4Settings = {
                  ClassId     = "boot.StaticIpV4Settings"
                  ObjectType  = "boot.StaticIpV4Settings"
                  Ip          = device.ipv4_config.ip
                  NetworkMask = device.ipv4_config.network_mask
                  GatewayIp   = device.ipv4_config.gateway_ip
                  DnsIp       = try(device.ipv4_config.dns_ip, "")
                }
              } : {},
              try(device.ipv6_config, null) != null ? {
                StaticIpV6Settings = {
                  ClassId      = "boot.StaticIpV6Settings"
                  ObjectType   = "boot.StaticIpV6Settings"
                  Ip           = device.ipv6_config.ip
                  PrefixLength = device.ipv6_config.prefix_length
                  GatewayIp    = device.ipv6_config.gateway_ip
                  DnsIp        = try(device.ipv6_config.dns_ip, "")
                }
              } : {},
              try(device.bootloader, null) != null ? {
                Bootloader = {
                  ClassId     = "boot.Bootloader"
                  ObjectType  = "boot.Bootloader"
                  Name        = device.bootloader.name
                  Path        = device.bootloader.path
                  Description = try(device.bootloader.description, "")
                }
              } : {}
            ))
          }
        ]
      }] : []
    ]
  ])
}

resource "intersight_boot_precision_policy" "boot_precision_policy" {
  for_each = var.manage_intersight_policies ? { for p in local.boot_order_policies : p.key => p } : {}

  configured_boot_mode     = each.value.boot_mode
  description              = each.value.description
  enforce_uefi_secure_boot = each.value.secure_boot
  name                     = each.value.name

  dynamic "boot_devices" {
    for_each = { for k, v in each.value.boot_devices : k => v }
    content {
      additional_properties = boot_devices.value.additional_properties
      enabled               = boot_devices.value.enabled
      name                  = boot_devices.value.name
      object_type           = boot_devices.value.object_type
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
