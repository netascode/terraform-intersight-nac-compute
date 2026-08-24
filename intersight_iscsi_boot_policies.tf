locals {
  iscsi_boot_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.iscsi_boot, []) :
      try(policy.managed, true) ? [{
        key                            = format("%s/%s", org.name, policy.name)
        org_name                       = org.name
        name                           = policy.name
        description                    = try(policy.description, local.defaults.compute.intersight.organizations.policies.iscsi_boot.description, "")
        target_source_type             = try(policy.target_source_type, local.defaults.compute.intersight.organizations.policies.iscsi_boot.target_source_type)
        initiator_ip_source            = try(policy.initiator_ip_source, local.defaults.compute.intersight.organizations.policies.iscsi_boot.initiator_ip_source)
        initiator_static_ip_v4_address = try(policy.initiator_static_ip_v4_address, null)
        auto_targetvendor_name         = try(policy.auto_targetvendor_name, null)
        ip_pool_key                    = try(policy.ip_pool, null) != null ? format("%s/%s", org.name, policy.ip_pool) : null
        iscsi_adapter_policy_key       = try(policy.iscsi_adapter_policy, null) != null ? format("%s/%s", org.name, policy.iscsi_adapter_policy) : null
        primary_target_policy_key      = try(policy.primary_target_policy, null) != null ? format("%s/%s", org.name, policy.primary_target_policy) : null
        secondary_target_policy_key    = try(policy.secondary_target_policy, null) != null ? format("%s/%s", org.name, policy.secondary_target_policy) : null
        chap                           = try(policy.chap, null)
        mutual_chap                    = try(policy.mutual_chap, null)
        initiator_static_ip_v4_config  = try(policy.initiator_static_ip_v4_config, null)
        tags                           = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_vnic_iscsi_boot_policy" "iscsi_boot_policy" {
  for_each = { for p in local.iscsi_boot_policies : p.key => p if var.manage_intersight_policies }

  description                    = each.value.description
  name                           = each.value.name
  target_source_type             = each.value.target_source_type
  initiator_ip_source            = each.value.initiator_ip_source
  initiator_static_ip_v4_address = each.value.initiator_static_ip_v4_address
  auto_targetvendor_name         = each.value.auto_targetvendor_name != null ? each.value.auto_targetvendor_name : null

  dynamic "initiator_ip_pool" {
    for_each = each.value.ip_pool_key != null ? [1] : []
    content {
      object_type = "ippool.Pool"
      moid        = local.ip_pool_moids[each.value.ip_pool_key]
    }
  }

  dynamic "iscsi_adapter_policy" {
    for_each = each.value.iscsi_adapter_policy_key != null ? [1] : []
    content {
      object_type = "vnic.IscsiAdapterPolicy"
      moid        = local.iscsi_adapter_policy_moids[each.value.iscsi_adapter_policy_key]
    }
  }

  dynamic "chap" {
    for_each = each.value.chap != null ? [each.value.chap] : []
    content {
      object_type = "vnic.IscsiAuthProfile"
      user_id     = try(chap.value.user_id, null)
      password    = try(chap.value.password, null)
    }
  }

  dynamic "mutual_chap" {
    for_each = each.value.mutual_chap != null ? [each.value.mutual_chap] : []
    content {
      object_type = "vnic.IscsiAuthProfile"
      user_id     = try(mutual_chap.value.user_id, null)
      password    = try(mutual_chap.value.password, null)
    }
  }

  dynamic "initiator_static_ip_v4_config" {
    for_each = each.value.initiator_static_ip_v4_config != null ? [each.value.initiator_static_ip_v4_config] : []
    content {
      object_type   = "comm.IpV4Interface"
      gateway       = try(initiator_static_ip_v4_config.value.default_gateway, null)
      netmask       = try(initiator_static_ip_v4_config.value.subnet_mask, null)
      primary_dns   = try(initiator_static_ip_v4_config.value.primary_dns, null)
      secondary_dns = try(initiator_static_ip_v4_config.value.secondary_dns, null)
    }
  }

  dynamic "primary_target_policy" {
    for_each = each.value.primary_target_policy_key != null ? [1] : []
    content {
      object_type = "vnic.IscsiStaticTargetPolicy"
      moid        = local.iscsi_static_target_policy_moids[each.value.primary_target_policy_key]
    }
  }

  dynamic "secondary_target_policy" {
    for_each = each.value.secondary_target_policy_key != null ? [1] : []
    content {
      object_type = "vnic.IscsiStaticTargetPolicy"
      moid        = local.iscsi_static_target_policy_moids[each.value.secondary_target_policy_key]
    }
  }

  dynamic "tags" {
    for_each = try(each.value.tags, [])
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
      type  = try(tags.value.type, "KeyValue")
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
