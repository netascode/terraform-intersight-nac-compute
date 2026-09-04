locals {
  resource_pools = flatten([
    for org in local.filtered_intersight_organizations : [
      for pool in try(org.pools.resource, []) :
      try(pool.managed, true) ? [{
        key           = format("%s/%s", org.name, pool.name)
        org_name      = org.name
        name          = pool.name
        description   = try(pool.description, local.defaults.compute.intersight.organizations.pools.resource.description, "")
        pool_type     = try(pool.pool_type, local.defaults.compute.intersight.organizations.pools.resource.pool_type)
        resource_type = try(pool.resource_type, local.defaults.compute.intersight.organizations.pools.resource.resource_type)
        selectors     = try(pool.selectors, [])
        tags          = try(pool.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_resourcepool_pool" "resource_pool" {
  for_each = { for p in local.resource_pools : p.key => p if var.manage_intersight_pools }

  description   = each.value.description
  name          = each.value.name
  pool_type     = each.value.pool_type
  resource_type = each.value.resource_type

  dynamic "selectors" {
    for_each = each.value.selectors
    content {
      object_type = "resource.Selector"
      selector    = selectors.value
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
}
