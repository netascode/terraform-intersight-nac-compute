locals {
  wwpn_pools = flatten([
    for org in local.filtered_intersight_organizations : [
      for pool in try(org.pools.wwpn, []) :
      try(pool.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.pools.wwpn,
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

resource "intersight_fcpool_pool" "wwpn_pool" {
  for_each = var.manage_intersight_pools ? { for p in local.wwpn_pools : p.key => p } : {}

  name         = each.value.name
  description  = try(each.value.description, "")
  pool_purpose = "WWPN"

  dynamic "id_blocks" {
    for_each = try(each.value.wwpn_blocks, [])
    content {
      object_type = "fcpool.Block"
      from        = id_blocks.value.from
      size        = try(id_blocks.value.size, null)
      to          = try(id_blocks.value.to, null)
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
