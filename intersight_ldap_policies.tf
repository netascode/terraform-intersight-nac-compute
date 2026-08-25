locals {
  ldap_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.ldap, []) :
      try(policy.managed, local.defaults.compute.intersight.organizations.policies.ldap.managed, true) ? [{
        key                    = format("%s/%s", org.name, policy.name)
        org_name               = org.name
        name                   = policy.name
        description            = try(policy.description, local.defaults.compute.intersight.organizations.policies.ldap.description, "")
        enabled                = try(policy.enabled, local.defaults.compute.intersight.organizations.policies.ldap.enabled)
        enable_dns             = try(policy.enable_dns, local.defaults.compute.intersight.organizations.policies.ldap.enable_dns)
        user_search_precedence = try(policy.user_search_precedence, local.defaults.compute.intersight.organizations.policies.ldap.user_search_precedence)
        base_properties        = try(policy.base_properties, null)
        dns_parameters         = try(policy.dns_parameters, null)
        tags                   = try(policy.tags, [])
      }] : []
    ]
  ])

  ldap_providers = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.ldap, []) :
      try(policy.managed, true) ? [
        for provider in try(policy.providers, []) : {
          key        = format("%s/%s/%s", org.name, policy.name, provider.server)
          policy_key = format("%s/%s", org.name, policy.name)
          server     = provider.server
          port       = try(provider.port, null)
        }
      ] : []
    ]
  ])

  ldap_groups = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.ldap, []) :
      try(policy.managed, true) ? [
        for group in try(policy.groups, []) : {
          key        = format("%s/%s/%s", org.name, policy.name, group.name)
          policy_key = format("%s/%s", org.name, policy.name)
          name       = group.name
          role       = try(group.role, null)
        }
      ] : []
    ]
  ])
}

resource "intersight_iam_ldap_policy" "ldap_policy" {
  for_each = { for p in local.ldap_policies : p.key => p if var.manage_intersight_policies }

  name                   = each.value.name
  description            = each.value.description
  enabled                = each.value.enabled
  enable_dns             = each.value.enable_dns
  user_search_precedence = each.value.user_search_precedence

  dynamic "base_properties" {
    for_each = each.value.base_properties != null ? [each.value.base_properties] : []
    content {
      object_type                = "iam.LdapBaseProperties"
      attribute                  = try(base_properties.value.attribute, null)
      base_dn                    = try(base_properties.value.base_dn, null)
      bind_dn                    = try(base_properties.value.bind_dn, null)
      bind_method                = try(base_properties.value.bind_method, null)
      domain                     = try(base_properties.value.domain, null)
      enable_encryption          = try(base_properties.value.encryption, null)
      enable_group_authorization = try(base_properties.value.group_authorization, null)
      enable_nested_group_search = try(base_properties.value.nested_group_search, null)
      filter                     = try(base_properties.value.filter, null)
      group_attribute            = try(base_properties.value.group_attribute, null)
      nested_group_search_depth  = try(base_properties.value.nested_group_search_depth, null)
      password                   = try(base_properties.value.password, null)
      timeout                    = try(base_properties.value.timeout, null)
    }
  }

  dynamic "dns_parameters" {
    for_each = each.value.dns_parameters != null ? [each.value.dns_parameters] : []
    content {
      object_type   = "iam.LdapDnsParameters"
      nr_source     = try(dns_parameters.value.source, null)
      search_domain = try(dns_parameters.value.search_domain, null)
      search_forest = try(dns_parameters.value.search_forest, null)
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
      key                   = tags.value.key
      additional_properties = jsonencode({ Type = "PathTag" })
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}

resource "intersight_iam_ldap_provider" "ldap_provider" {
  for_each = { for p in local.ldap_providers : p.key => p if var.manage_intersight_policies }

  server = each.value.server
  port   = each.value.port

  ldap_policy {
    object_type = "iam.LdapPolicy"
    moid        = intersight_iam_ldap_policy.ldap_policy[each.value.policy_key].moid
  }

  depends_on = [intersight_iam_ldap_policy.ldap_policy]
}

resource "intersight_iam_ldap_group" "ldap_group" {
  for_each = {
    for g in local.ldap_groups : g.key => g
    if var.manage_intersight_policies && g.role != null
  }

  name = each.value.name

  end_point_role {
    object_type = "iam.EndPointRole"
    selector    = "Name eq '${each.value.role}' and Type eq 'IMC'"
  }

  ldap_policy {
    object_type = "iam.LdapPolicy"
    moid        = intersight_iam_ldap_policy.ldap_policy[each.value.policy_key].moid
  }

  depends_on = [intersight_iam_ldap_policy.ldap_policy]
}
