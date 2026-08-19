locals {
  intersight_servers = flatten([
    for server in local.filtered_servers :
    try(server.provisioning.managed, true) ? [{
      key                  = server.name
      name                 = server.name
      org_name             = server.provisioning.intersight.organization
      profile_template_key = format("%s/%s", server.provisioning.intersight.organization, server.provisioning.profile_template)
      serial_number        = try(server.provisioning.intersight.serial_number, null)
      resource_pool_key    = try(server.provisioning.intersight.resource_pool, null) != null ? format("%s/%s", server.provisioning.intersight.organization, server.provisioning.intersight.resource_pool) : null
      action               = try(server.provisioning.action, local.defaults.compute.servers.provisioning.action)
      wait_for_completion  = try(server.provisioning.wait_for_completion, local.defaults.compute.servers.provisioning.wait_for_completion)
      tags                 = try(server.tags, [])
    }] : []
  ])

  # Map data model action values to Intersight provider action strings
  _intersight_action_map = {
    none            = "No-op"
    sync            = "Sync"
    deploy          = "Deploy"
    sync_and_deploy = "Deploy" # Sync runs first via template_actions, then Deploy
  }
}

data "intersight_compute_physical_summary" "server" {
  for_each = {
    for s in local.intersight_servers : s.key => s
    if s.serial_number != null && var.manage_servers
  }

  serial = each.value.serial_number
}

resource "intersight_server_profile" "server_profile" {
  for_each = { for s in local.intersight_servers : s.key => s if var.manage_servers }

  name                   = each.value.name
  action                 = local._intersight_action_map[each.value.action]
  wait_for_completion    = each.value.action != "none" ? each.value.wait_for_completion : false
  server_assignment_mode = each.value.serial_number != null ? "Static" : (each.value.resource_pool_key != null ? "Pool" : "None")

  src_template {
    object_type = "server.ProfileTemplate"
    moid        = local.server_profile_template_moids[each.value.profile_template_key]
  }

  # Sync with template before deploying when action is sync_and_deploy
  dynamic "template_actions" {
    for_each = each.value.action == "sync_and_deploy" ? [1] : []
    content {
      object_type = "server.Profile"
      type        = "Sync"
    }
  }

  dynamic "assigned_server" {
    for_each = each.value.serial_number != null ? [1] : []
    content {
      object_type = data.intersight_compute_physical_summary.server[each.key].results[0].source_object_type
      moid        = data.intersight_compute_physical_summary.server[each.key].results[0].moid
    }
  }

  dynamic "server_pool" {
    for_each = each.value.resource_pool_key != null ? [1] : []
    content {
      object_type = "resourcepool.Pool"
      moid        = local.resource_pool_moids[each.value.resource_pool_key]
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
