locals {
  snmp_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.snmp, []) :
      try(policy.managed, local.defaults.compute.intersight.organizations.policies.snmp.managed, true) ? [{
        key                     = format("%s/%s", org.name, policy.name)
        org_name                = org.name
        name                    = policy.name
        description             = try(policy.description, local.defaults.compute.intersight.organizations.policies.snmp.description, "")
        enabled                 = try(policy.enabled, local.defaults.compute.intersight.organizations.policies.snmp.enabled)
        port                    = try(policy.port, local.defaults.compute.intersight.organizations.policies.snmp.port)
        access_community_string = try(policy.access_community_string, null)
        community_access        = try(policy.community_access, local.defaults.compute.intersight.organizations.policies.snmp.community_access)
        trap_community          = try(policy.trap_community, null)
        sys_contact             = try(policy.sys_contact, null)
        sys_location            = try(policy.sys_location, null)
        engine_id               = try(policy.engine_id, null)
        v2_enabled              = try(policy.v2, local.defaults.compute.intersight.organizations.policies.snmp.v2)
        v3_enabled              = try(policy.v3, local.defaults.compute.intersight.organizations.policies.snmp.v3)
        users = [
          for user in try(policy.users, []) : {
            name             = user.name
            security_level   = try(user.security_level, local.defaults.compute.intersight.organizations.policies.snmp.users.security_level)
            auth_type        = try(user.auth_type, local.defaults.compute.intersight.organizations.policies.snmp.users.auth_type)
            auth_password    = try(user.auth_password, null)
            privacy_type     = try(user.privacy_type, local.defaults.compute.intersight.organizations.policies.snmp.users.privacy_type)
            privacy_password = try(user.privacy_password, null)
          }
        ]
        traps = [
          for trap in try(policy.traps, []) : {
            destination = trap.destination
            port        = try(trap.port, local.defaults.compute.intersight.organizations.policies.snmp.traps.port)
            nr_version  = try(trap.version, local.defaults.compute.intersight.organizations.policies.snmp.traps.version)
            type        = try(trap.type, local.defaults.compute.intersight.organizations.policies.snmp.traps.type)
            enabled     = try(trap.enabled, local.defaults.compute.intersight.organizations.policies.snmp.traps.enabled)
            user        = try(trap.user, null)
            community   = try(trap.community, null)
          }
        ]
      }] : []
    ]
  ])
}

resource "intersight_snmp_policy" "snmp_policy" {
  for_each = { for p in local.snmp_policies : p.key => p }

  name                    = each.value.name
  description             = each.value.description
  enabled                 = each.value.enabled
  snmp_port               = each.value.port
  access_community_string = each.value.access_community_string
  community_access        = each.value.community_access
  trap_community          = each.value.trap_community
  sys_contact             = each.value.sys_contact
  sys_location            = each.value.sys_location
  engine_id               = each.value.engine_id
  v2_enabled              = each.value.v2_enabled
  v3_enabled              = each.value.v3_enabled

  dynamic "snmp_users" {
    for_each = { for k, v in each.value.users : k => v }
    content {
      object_type      = "snmp.User"
      name             = snmp_users.value.name
      security_level   = snmp_users.value.security_level
      auth_type        = snmp_users.value.auth_type
      auth_password    = snmp_users.value.auth_password
      privacy_type     = snmp_users.value.privacy_type
      privacy_password = snmp_users.value.privacy_password
    }
  }

  dynamic "snmp_traps" {
    for_each = { for k, v in each.value.traps : k => v }
    content {
      object_type = "snmp.Trap"
      destination = snmp_traps.value.destination
      port        = snmp_traps.value.port
      nr_version  = snmp_traps.value.nr_version
      type        = snmp_traps.value.type
      enabled     = snmp_traps.value.enabled
      user        = snmp_traps.value.user
      community   = snmp_traps.value.community
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
