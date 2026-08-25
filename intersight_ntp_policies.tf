locals {
  ntp_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.ntp, []) :
      try(policy.managed, true) ? [{
        key                       = format("%s/%s", org.name, policy.name)
        org_name                  = org.name
        name                      = policy.name
        description               = try(policy.description, local.defaults.compute.intersight.organizations.policies.ntp.description, "")
        enabled                   = try(policy.enabled, local.defaults.compute.intersight.organizations.policies.ntp.enabled)
        timezone                  = try(policy.timezone, local.defaults.compute.intersight.organizations.policies.ntp.timezone)
        ntp_servers               = try(policy.ntp_servers, [])
        authenticated_ntp_servers = try(policy.authenticated_ntp_servers, [])
      }] : []
    ]
  ])
}

resource "intersight_ntp_policy" "ntp_policy" {
  for_each = { for p in local.ntp_policies : p.key => p if var.manage_intersight_policies }

  description = each.value.description
  enabled     = each.value.enabled
  name        = each.value.name
  ntp_servers = each.value.ntp_servers
  timezone    = each.value.timezone

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
      key                   = tags.value.key
      additional_properties = jsonencode({ Type = "PathTag" })
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }

  dynamic "authenticated_ntp_servers" {
    for_each = each.value.authenticated_ntp_servers
    content {
      object_type   = "ntp.AuthNtpServer"
      server_name   = authenticated_ntp_servers.value.server_name
      key_type      = try(authenticated_ntp_servers.value.key_type, "SHA1")
      sym_key_id    = try(authenticated_ntp_servers.value.sym_key_id, null)
      sym_key_value = try(authenticated_ntp_servers.value.sym_key_value, null)
    }
  }
}
