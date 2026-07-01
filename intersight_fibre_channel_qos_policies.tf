locals {
  fibre_channel_qos_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.fibre_channel_qos, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.fibre_channel_qos,
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

resource "intersight_vnic_fc_qos_policy" "fibre_channel_qos_policy" {
  for_each = { for p in local.fibre_channel_qos_policies : p.key => p }

  name                = each.value.name
  description         = try(each.value.description, "")
  burst               = each.value.burst
  cos                 = each.value.cos
  max_data_field_size = each.value.max_data_field_size
  rate_limit          = each.value.rate_limit

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
