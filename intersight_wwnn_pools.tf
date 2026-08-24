locals {
  wwnn_pools = flatten([
    for org in local.filtered_intersight_organizations : [
      for pool in try(org.pools.wwnn, []) :
      try(pool.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.pools.wwnn,
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

resource "intersight_fcpool_pool" "wwnn_pool" {
  for_each = { for p in local.wwnn_pools : p.key => p if var.manage_intersight_pools }

  name         = each.value.name
  description  = try(each.value.description, "")
  pool_purpose = "WWNN"

  dynamic "id_blocks" {
    for_each = try(each.value.wwnn_blocks, [])
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
      value = try(tags.value.value, "")
      type  = try(tags.value.type, "KeyValue")
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
