locals {
  ip_pools = flatten([
    for org in local.filtered_intersight_organizations : [
      for pool in try(org.pools.ip, []) :
      try(pool.managed, true) ? [{
        key         = format("%s/%s", org.name, pool.name)
        org_name    = org.name
        name        = pool.name
        description = try(pool.description, local.defaults.compute.intersight.organizations.pools.ip.description, "")
        ipv4_config = try(pool.ipv4_config, null)
        ipv4_blocks = try(pool.ipv4_blocks, [])
        ipv6_config = try(pool.ipv6_config, null)
        ipv6_blocks = try(pool.ipv6_blocks, [])
      }] : []
    ]
  ])
}

resource "intersight_ippool_pool" "ip_pool" {
  for_each = { for p in local.ip_pools : p.key => p if var.manage_intersight_pools }

  description = each.value.description
  name        = each.value.name

  dynamic "ip_v4_config" {
    for_each = each.value.ipv4_config != null ? [each.value.ipv4_config] : []
    content {
      object_type   = "ippool.IpV4Config"
      gateway       = ip_v4_config.value.gateway
      netmask       = ip_v4_config.value.netmask
      primary_dns   = try(ip_v4_config.value.primary_dns, null)
      secondary_dns = try(ip_v4_config.value.secondary_dns, null)
    }
  }

  dynamic "ip_v4_blocks" {
    for_each = each.value.ipv4_blocks
    content {
      object_type = "ippool.IpV4Block"
      from        = ip_v4_blocks.value.from
      size        = try(ip_v4_blocks.value.size, null)
      to          = try(ip_v4_blocks.value.to, null)
    }
  }

  dynamic "ip_v6_config" {
    for_each = each.value.ipv6_config != null ? [each.value.ipv6_config] : []
    content {
      object_type   = "ippool.IpV6Config"
      gateway       = ip_v6_config.value.gateway
      prefix        = ip_v6_config.value.prefix
      primary_dns   = try(ip_v6_config.value.primary_dns, null)
      secondary_dns = try(ip_v6_config.value.secondary_dns, null)
    }
  }

  dynamic "ip_v6_blocks" {
    for_each = each.value.ipv6_blocks
    content {
      object_type = "ippool.IpV6Block"
      from        = ip_v6_blocks.value.from
      size        = try(ip_v6_blocks.value.size, null)
      to          = try(ip_v6_blocks.value.to, null)
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

  lifecycle {
    ignore_changes = [
      ip_v6_blocks // needed to make the code idempotent as the Intersight API calculates the "to" address
    ]
  }
}
