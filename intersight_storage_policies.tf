locals {
  storage_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.storage, []) :
      try(policy.managed, true) ? [{
        key                      = format("%s/%s", org.name, policy.name)
        org_name                 = org.name
        name                     = policy.name
        description              = try(policy.description, local.defaults.compute.intersight.organizations.policies.storage.description, "")
        unused_disks_state       = try(policy.unused_disks_state, local.defaults.compute.intersight.organizations.policies.storage.unused_disks_state)
        use_jbod_for_vd_creation = try(policy.use_jbod_for_vd_creation, local.defaults.compute.intersight.organizations.policies.storage.use_jbod_for_vd_creation)
        global_hot_spares        = try(policy.global_hot_spares, null)
        m2_virtual_drive         = try(policy.m2_virtual_drive, null)
      }] : []
    ]
  ])

  storage_drive_groups = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.storage, []) :
      try(policy.managed, true) ? [
        for dg in try(policy.drive_groups, []) : {
          key            = format("%s/%s/%s", org.name, policy.name, dg.name)
          policy_key     = format("%s/%s", org.name, policy.name)
          name           = dg.name
          raid_level     = try(dg.raid_level, local.defaults.compute.intersight.organizations.policies.storage.drive_groups.raid_level)
          secure         = try(dg.secure, null)
          manual_dg      = try(dg.manual_drive_group, null)
          virtual_drives = try(dg.virtual_drives, [])
        }
      ] : []
    ]
  ])
}

resource "intersight_storage_storage_policy" "storage_policy" {
  for_each = var.manage_intersight_policies ? { for p in local.storage_policies : p.key => p } : {}

  name                     = each.value.name
  description              = each.value.description
  unused_disks_state       = each.value.unused_disks_state
  use_jbod_for_vd_creation = each.value.use_jbod_for_vd_creation
  global_hot_spares        = each.value.global_hot_spares

  dynamic "m2_virtual_drive" {
    for_each = each.value.m2_virtual_drive != null ? [each.value.m2_virtual_drive] : []
    content {
      object_type     = "storage.M2VirtualDriveConfig"
      enable          = try(m2_virtual_drive.value.enabled, null)
      controller_slot = try(m2_virtual_drive.value.controller_slot, null)
      name            = try(m2_virtual_drive.value.name, null)
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

resource "intersight_storage_drive_group" "storage_drive_group" {
  for_each = var.manage_intersight_policies ? { for dg in local.storage_drive_groups : dg.key => dg } : {}

  name               = each.value.name
  raid_level         = each.value.raid_level
  secure_drive_group = each.value.secure

  dynamic "manual_drive_group" {
    for_each = each.value.manual_dg != null ? [each.value.manual_dg] : []
    content {
      object_type          = "storage.ManualDriveGroup"
      dedicated_hot_spares = try(manual_drive_group.value.dedicated_hot_spares, null)

      dynamic "span_groups" {
        for_each = try(manual_drive_group.value.drive_array_spans, [])
        content {
          object_type = "storage.SpanDrives"
          slots       = span_groups.value
        }
      }
    }
  }

  dynamic "virtual_drives" {
    for_each = each.value.virtual_drives
    content {
      object_type         = "storage.VirtualDriveConfiguration"
      name                = virtual_drives.value.name
      size                = try(virtual_drives.value.size, null)
      boot_drive          = try(virtual_drives.value.boot_drive, local.defaults.compute.intersight.organizations.policies.storage.drive_groups.virtual_drives.boot_drive)
      expand_to_available = try(virtual_drives.value.expand_to_available, local.defaults.compute.intersight.organizations.policies.storage.drive_groups.virtual_drives.expand_to_available)

      virtual_drive_policy {
        object_type   = "storage.VirtualDrivePolicy"
        access_policy = try(virtual_drives.value.access_policy, local.defaults.compute.intersight.organizations.policies.storage.drive_groups.virtual_drives.access_policy)
        drive_cache   = try(virtual_drives.value.drive_cache, local.defaults.compute.intersight.organizations.policies.storage.drive_groups.virtual_drives.drive_cache)
        read_policy   = try(virtual_drives.value.read_policy, local.defaults.compute.intersight.organizations.policies.storage.drive_groups.virtual_drives.read_policy)
        strip_size    = try(virtual_drives.value.strip_size, local.defaults.compute.intersight.organizations.policies.storage.drive_groups.virtual_drives.strip_size)
        write_policy  = try(virtual_drives.value.write_policy, local.defaults.compute.intersight.organizations.policies.storage.drive_groups.virtual_drives.write_policy)
      }
    }
  }

  storage_policy {
    object_type = "storage.StoragePolicy"
    moid        = intersight_storage_storage_policy.storage_policy[each.value.policy_key].moid
  }

  depends_on = [intersight_storage_storage_policy.storage_policy]
}
