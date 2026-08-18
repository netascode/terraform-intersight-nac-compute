locals {
  smtp_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.smtp, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.smtp,
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

resource "intersight_smtp_policy" "smtp_policy" {
  for_each = { for p in local.smtp_policies : p.key => p if var.manage_intersight_policies }

  name            = each.value.name
  description     = try(each.value.description, "")
  enabled         = each.value.enabled
  smtp_server     = try(each.value.smtp_server, null)
  smtp_port       = each.value.smtp_port
  sender_email    = try(each.value.sender_email, null)
  smtp_recipients = try(each.value.recipients, [])
  min_severity    = each.value.min_severity
  enable_tls      = each.value.tls

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
