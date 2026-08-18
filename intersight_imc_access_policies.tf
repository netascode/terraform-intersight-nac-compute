locals {
  imc_access_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.imc_access, []) :
      try(policy.managed, local.defaults.compute.intersight.organizations.policies.imc_access.managed, true) ? [{
        key                     = format("%s/%s", org.name, policy.name)
        org_name                = org.name
        name                    = policy.name
        description             = try(policy.description, local.defaults.compute.intersight.organizations.policies.imc_access.description, "")
        configure_inband        = try(policy.configure_inband, local.defaults.compute.intersight.organizations.policies.imc_access.configure_inband, true)
        configure_out_of_band   = try(policy.configure_out_of_band, local.defaults.compute.intersight.organizations.policies.imc_access.configure_out_of_band, false)
        inband_vlan             = try(policy.inband_vlan, null)
        ipv4                    = try(policy.ipv4, local.defaults.compute.intersight.organizations.policies.imc_access.ipv4, true)
        ipv6                    = try(policy.ipv6, local.defaults.compute.intersight.organizations.policies.imc_access.ipv6, false)
        inband_ip_pool_key      = try(policy.inband_ip_pool, null) != null ? format("%s/%s", org.name, policy.inband_ip_pool) : null
        out_of_band_ip_pool_key = try(policy.out_of_band_ip_pool, null) != null ? format("%s/%s", org.name, policy.out_of_band_ip_pool) : null
      }] : []
    ]
  ])
}

resource "intersight_access_policy" "imc_access_policy" {
  for_each = { for p in local.imc_access_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = each.value.description
  inband_vlan = each.value.inband_vlan

  address_type {
    object_type  = "access.AddressType"
    enable_ip_v4 = each.value.ipv4
    enable_ip_v6 = each.value.ipv6
  }

  configuration_type {
    object_type           = "access.ConfigurationType"
    configure_inband      = each.value.configure_inband
    configure_out_of_band = each.value.configure_out_of_band
  }

  dynamic "inband_ip_pool" {
    for_each = each.value.inband_ip_pool_key != null ? [1] : []
    content {
      object_type = "ippool.Pool"
      moid        = intersight_ippool_pool.ip_pool[each.value.inband_ip_pool_key].moid
    }
  }

  dynamic "out_of_band_ip_pool" {
    for_each = each.value.out_of_band_ip_pool_key != null ? [1] : []
    content {
      object_type = "ippool.Pool"
      moid        = intersight_ippool_pool.ip_pool[each.value.out_of_band_ip_pool_key].moid
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
