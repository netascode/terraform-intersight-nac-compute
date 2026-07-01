locals {
  mac_pools = flatten([
    for org in try(local.intersight.organizations, []) : [
      for pool in try(org.pools.mac, []) :
      try(pool.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.pools.mac,
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

resource "intersight_macpool_pool" "mac_pool" {
  for_each = { for p in local.mac_pools : p.key => p }

  name        = each.value.name
  description = try(each.value.description, "")

  dynamic "mac_blocks" {
    for_each = try(each.value.mac_blocks, [])
    content {
      from = mac_blocks.value.from
      size = try(mac_blocks.value.size, null)
      to   = try(mac_blocks.value.to, null)
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
