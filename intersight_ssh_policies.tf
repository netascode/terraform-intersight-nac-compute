locals {
  ssh_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.ssh, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.ssh,
        policy,
        {
          key      = format("%s/%s", org.name, policy.name)
          org_name = org.name
          name     = policy.name
        }
      )] : []
    ]
  ])
}

resource "intersight_ssh_policy" "ssh_policy" {
  for_each = { for p in local.ssh_policies : p.key => p }

  name        = each.value.name
  description = try(each.value.description, "")
  enabled     = each.value.enabled
  port        = each.value.port
  timeout     = each.value.timeout

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
