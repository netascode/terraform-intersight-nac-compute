locals {
  resource_pools = flatten([
    for org in local.filtered_intersight_organizations : [
      for pool in try(org.pools.resource, []) :
      try(pool.managed, true) ? [{
        key                      = format("%s/%s", org.name, pool.name)
        org_name                 = org.name
        name                     = pool.name
        description              = try(pool.description, local.defaults.compute.intersight.organizations.pools.resource.description, "")
        pool_type                = try(pool.pool_type, local.defaults.compute.intersight.organizations.pools.resource.pool_type)
        resource_type            = try(pool.resource_type, local.defaults.compute.intersight.organizations.pools.resource.resource_type)
        target_platform          = try(pool.target_platform, null)
        selectors                = try(pool.selectors, [])
        tags                     = try(pool.tags, [])
        qualification_policy_key = try(pool.qualification_policy, null) != null ? format("%s/%s", org.name, pool.qualification_policy) : null
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

  dynamic "resource_pool_parameters" {
    for_each = each.value.target_platform != null ? [each.value.target_platform] : []
    content {
      object_type = "resourcepool.ServerPoolParameters"
      additional_properties = jsonencode({
        TargetPlatform = resource_pool_parameters.value
      })
    }
  }

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

  dynamic "qualification_policies" {
    for_each = each.value.qualification_policy_key != null ? [1] : []
    content {
      object_type = "resourcepool.QualificationPolicy"
      moid        = local.qualification_policy_moids[each.value.qualification_policy_key]
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }

  # NOTE: pool_type = "Dynamic"/"Hybrid" requires a linked resourcepool.QualificationPolicy
  # (set via qualification_policy) to persist: Intersight only evaluates a pool dynamically once
  # a Qualification Policy is associated via the QualificationPolicies relationship. Without one,
  # the API silently reverts pool_type to "Static" and clears selectors on every read, causing
  # perpetual drift. selectors alone, with no qualification_policy, still will not persist.
}
