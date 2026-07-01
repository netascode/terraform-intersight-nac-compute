locals {
  syslog_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.syslog, []) :
      try(policy.managed, true) ? [{
        key                = format("%s/%s", org.name, policy.name)
        org_name           = org.name
        name               = policy.name
        description        = try(policy.description, local.defaults.compute.intersight.organizations.policies.syslog.description, "")
        local_min_severity = try(policy.local_min_severity, local.defaults.compute.intersight.organizations.policies.syslog.local_min_severity)
        remote_clients     = try(policy.remote_clients, [])
      }] : []
    ]
  ])
}

resource "intersight_syslog_policy" "syslog_policy" {
  for_each = { for p in local.syslog_policies : p.key => p }

  description = each.value.description
  name        = each.value.name

  local_clients {
    min_severity = each.value.local_min_severity
    object_type  = "syslog.LocalFileLoggingClient"
  }

  dynamic "remote_clients" {
    for_each = each.value.remote_clients
    content {
      object_type  = "syslog.RemoteLoggingClient"
      hostname     = remote_clients.value.hostname
      enabled      = try(remote_clients.value.enabled, true)
      port         = try(remote_clients.value.port, 514)
      protocol     = try(remote_clients.value.protocol, "udp")
      min_severity = try(remote_clients.value.min_severity, "warning")
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
