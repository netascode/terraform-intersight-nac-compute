locals {
  resource_pools = flatten([
    for org in local.filtered_intersight_organizations : [
      for pool in try(org.pools.resource, []) :
      try(pool.managed, true) ? [{
        key         = format("%s/%s", org.name, pool.name)
        org_name    = org.name
        name        = pool.name
        description = try(pool.description, local.defaults.compute.intersight.organizations.pools.resource.description, "")
        server_type = try(pool.server_type, local.defaults.compute.intersight.organizations.pools.resource.server_type)
        selectors   = try(pool.selectors, [])
        tags        = try(pool.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_resourcepool_pool" "resource_pool" {
  for_each = { for p in local.resource_pools : p.key => p if var.manage_intersight_pools }

  description = each.value.description
  name        = each.value.name
  pool_type   = "Server"

  resource_pool_parameters {
    object_type = "resourcepool.ServerPool"
    server_type = each.value.server_type
  }

  dynamic "selectors" {
    for_each = each.value.selectors
    content {
      object_type = "resourcepool.Selector"
      selector    = selectors.value
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
