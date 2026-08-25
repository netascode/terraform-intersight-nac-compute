locals {
  mac_sec_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.mac_sec, []) :
      try(policy.managed, true) ? [{
        key                    = format("%s/%s", org.name, policy.name)
        org_name               = org.name
        name                   = policy.name
        description            = try(policy.description, local.defaults.compute.intersight.organizations.policies.mac_sec.description, "")
        cipher_suite           = try(policy.cipher_suite, local.defaults.compute.intersight.organizations.policies.mac_sec.cipher_suite)
        confidentiality_offset = try(policy.confidentiality_offset, local.defaults.compute.intersight.organizations.policies.mac_sec.confidentiality_offset)
        include_icv_indicator  = try(policy.include_icv_indicator, local.defaults.compute.intersight.organizations.policies.mac_sec.include_icv_indicator)
        key_server_priority    = try(policy.key_server_priority, local.defaults.compute.intersight.organizations.policies.mac_sec.key_server_priority)
        replay_window_size     = try(policy.replay_window_size, local.defaults.compute.intersight.organizations.policies.mac_sec.replay_window_size)
        sak_expiry_time        = try(policy.sak_expiry_time, local.defaults.compute.intersight.organizations.policies.mac_sec.sak_expiry_time)
        security_policy        = try(policy.security_policy, local.defaults.compute.intersight.organizations.policies.mac_sec.security_policy)
        mac_sec_ea_pol         = try(policy.mac_sec_ea_pol, null)
        primary_key_chain      = try(policy.primary_key_chain, null)
        fallback_key_chain     = try(policy.fallback_key_chain, null)
        tags                   = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_fabric_mac_sec_policy" "mac_sec_policy" {
  for_each = { for p in local.mac_sec_policies : p.key => p if var.manage_intersight_policies }

  name                   = each.value.name
  description            = each.value.description
  cipher_suite           = each.value.cipher_suite
  confidentiality_offset = each.value.confidentiality_offset
  include_icv_indicator  = each.value.include_icv_indicator
  key_server_priority    = each.value.key_server_priority
  replay_window_size     = each.value.replay_window_size
  sak_expiry_time        = each.value.sak_expiry_time
  security_policy        = each.value.security_policy

  dynamic "mac_sec_ea_pol" {
    for_each = each.value.mac_sec_ea_pol != null ? [each.value.mac_sec_ea_pol] : []
    content {
      ea_pol_ethertype   = try(mac_sec_ea_pol.value.ea_pol_ethertype, null)
      ea_pol_mac_address = try(mac_sec_ea_pol.value.ea_pol_mac_address, null)
    }
  }

  dynamic "primary_key_chain" {
    for_each = each.value.primary_key_chain != null ? [each.value.primary_key_chain] : []
    content {
      name = primary_key_chain.value.name
      dynamic "sec_keys" {
        for_each = try(primary_key_chain.value.keys, [])
        content {
          cryptographic_algorithm = try(sec_keys.value.cryptographic_algorithm, local.defaults.compute.intersight.organizations.policies.mac_sec.keys.cryptographic_algorithm)
          id                      = try(sec_keys.value.id, local.defaults.compute.intersight.organizations.policies.mac_sec.keys.id)
          key_type                = try(sec_keys.value.key_type, local.defaults.compute.intersight.organizations.policies.mac_sec.keys.key_type)
          object_type             = "fabric.SecKey"
          octet_string            = try(sec_keys.value.octet_string, "")
          send_lifetime_unlimited = try(sec_keys.value.send_lifetime_unlimited, local.defaults.compute.intersight.organizations.policies.mac_sec.keys.send_lifetime_unlimited)
          send_lifetime_infinite  = false
          send_lifetime_duration  = 0
          send_lifetime_time_zone = "UTC"
        }
      }
    }
  }

  dynamic "fallback_key_chain" {
    for_each = each.value.fallback_key_chain != null ? [each.value.fallback_key_chain] : []
    content {
      name = fallback_key_chain.value.name
      dynamic "sec_keys" {
        for_each = try(fallback_key_chain.value.keys, [])
        content {
          cryptographic_algorithm = try(sec_keys.value.cryptographic_algorithm, local.defaults.compute.intersight.organizations.policies.mac_sec.keys.cryptographic_algorithm)
          id                      = try(sec_keys.value.id, local.defaults.compute.intersight.organizations.policies.mac_sec.keys.id)
          key_type                = try(sec_keys.value.key_type, local.defaults.compute.intersight.organizations.policies.mac_sec.keys.key_type)
          object_type             = "fabric.SecKey"
          octet_string            = try(sec_keys.value.octet_string, "")
          send_lifetime_unlimited = try(sec_keys.value.send_lifetime_unlimited, local.defaults.compute.intersight.organizations.policies.mac_sec.keys.send_lifetime_unlimited)
          send_lifetime_infinite  = false
          send_lifetime_duration  = 0
          send_lifetime_time_zone = "UTC"
        }
      }
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

  lifecycle {
    ignore_changes = [primary_key_chain, fallback_key_chain]
  }
}
