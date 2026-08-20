locals {
  iqn_pools = flatten([
    for org in local.filtered_intersight_organizations : [
      for pool in try(org.pools.iqn, []) :
      try(pool.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.pools.iqn,
        pool,
        {
          key      = format("%s/%s", org.name, pool.name)
          org_name = org.name
          name     = pool.name
        }
      )] : []
    ]
  ])
}

resource "intersight_iqnpool_pool" "iqn_pool" {
  for_each = { for p in local.iqn_pools : p.key => p if var.manage_intersight_pools }

  name        = each.value.name
  description = try(each.value.description, "")
  prefix      = try(each.value.prefix, null)

  dynamic "iq_n_suffix_blocks" {
    for_each = try(each.value.iqn_suffix_blocks, [])
    content {
      object_type = "iqnpool.Block"
      suffix      = try(iq_n_suffix_blocks.value.suffix, null)
      from        = try(iq_n_suffix_blocks.value.from, null)
      size        = try(iq_n_suffix_blocks.value.size, null)
      to          = try(iq_n_suffix_blocks.value.to, null)
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
