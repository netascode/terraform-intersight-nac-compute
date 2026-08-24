locals {
  persistent_memory_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.persistent_memory, []) :
      try(policy.managed, true) ? [{
        key                = format("%s/%s", org.name, policy.name)
        org_name           = org.name
        name               = policy.name
        description        = try(policy.description, local.defaults.compute.intersight.organizations.policies.persistent_memory.description, "")
        management_mode    = try(policy.management_mode, local.defaults.compute.intersight.organizations.policies.persistent_memory.management_mode)
        retain_namespaces  = try(policy.retain_namespaces, local.defaults.compute.intersight.organizations.policies.persistent_memory.retain_namespaces)
        goals              = try(policy.goals, null)
        local_security     = try(policy.local_security, null)
        logical_namespaces = try(policy.logical_namespaces, [])
        tags               = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_memory_persistent_memory_policy" "persistent_memory_policy" {
  for_each = { for p in local.persistent_memory_policies : p.key => p if var.manage_intersight_policies }

  name              = each.value.name
  description       = each.value.description
  management_mode   = each.value.management_mode
  retain_namespaces = each.value.retain_namespaces

  dynamic "goals" {
    for_each = each.value.goals != null ? [each.value.goals] : []
    content {
      object_type            = "memory.PersistentMemoryGoal"
      memory_mode_percentage = try(goals.value.memory_mode_percentage, 0)
      persistent_memory_type = try(goals.value.persistent_memory_type, "app-direct")
      socket_id              = try(goals.value.socket_id, "All Sockets")
    }
  }

  dynamic "local_security" {
    for_each = each.value.local_security != null ? [each.value.local_security] : []
    content {
      object_type       = "memory.PersistentMemoryLocalSecurity"
      enabled           = try(local_security.value.enabled, false)
      secure_passphrase = try(local_security.value.secure_passphrase, null)
    }
  }

  dynamic "logical_namespaces" {
    for_each = each.value.logical_namespaces
    content {
      object_type      = "memory.PersistentMemoryLogicalNamespace"
      name             = logical_namespaces.value.name
      capacity         = try(logical_namespaces.value.capacity, null)
      mode             = try(logical_namespaces.value.mode, "raw")
      socket_id        = try(logical_namespaces.value.socket_id, "1")
      socket_memory_id = try(logical_namespaces.value.socket_memory_id, "Not Applicable")
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
