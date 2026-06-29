locals {
  ethernet_qos_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.ethernet_qos, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.ethernet_qos,
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

resource "intersight_vnic_eth_qos_policy" "ethernet_qos_policy" {
  for_each = { for p in local.ethernet_qos_policies : p.key => p }

  name        = each.value.name
  description = try(each.value.description, "")

  burst          = try(each.value.burst, null)
  cos            = try(each.value.cos, null)
  mtu            = try(each.value.mtu, null)
  priority       = try(each.value.priority, null)
  rate_limit     = try(each.value.rate_limit, null)
  trust_host_cos = try(each.value.trust_host_cos, null)

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
