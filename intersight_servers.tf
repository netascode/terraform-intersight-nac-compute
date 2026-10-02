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

  # Resolve discovered server Moid/object_type per key, when Intersight has inventoried it
  server_moids = {
    for s in local.intersight_servers : s.key => (
      s.serial_number != null && length(data.intersight_compute_physical_summary.server[s.key].results) > 0
      ? data.intersight_compute_physical_summary.server[s.key].results[0].moid
      : null
    ) if s.serial_number != null
  }
  server_object_types = {
    for s in local.intersight_servers : s.key => (
      s.serial_number != null && length(data.intersight_compute_physical_summary.server[s.key].results) > 0
      ? data.intersight_compute_physical_summary.server[s.key].results[0].source_object_type
      : null
    ) if s.serial_number != null
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

  name = each.value.name
  # Deploy is sent after the template sync (see server_profile_deploy); the profile has no policies until then.
  # Unassign is a native action on this resource, so it is set directly here (every apply while action is
  # "unassign", same convention as the chassis profile) rather than through a bulk_request side channel.
  action = each.value.action == "unassign" ? "Unassign" : "No-op"
  # Makes destroy wait for the Unassign workflow to finish before deleting the profile
  wait_for_completion    = true
  server_assignment_mode = each.value.serial_number != null ? "Static" : (each.value.resource_pool_key != null ? "Pool" : "None")
  # server.Profile defaults to Standalone and does not inherit TargetPlatform from src_template
  target_platform = local.server_profile_template_target_platforms[each.value.profile_template_key]

  src_template {
    object_type = "server.ProfileTemplate"
    moid        = local.server_profile_template_moids[each.value.profile_template_key]
  }

  dynamic "assigned_server" {
    for_each = each.value.serial_number != null && local.server_moids[each.key] != null ? [1] : []
    content {
      object_type = local.server_object_types[each.key]
      moid        = local.server_moids[each.key]
    }
  }

  server_pre_assign_by_serial = each.value.serial_number != null && local.server_moids[each.key] == null ? each.value.serial_number : null

  dynamic "server_pool" {
    for_each = each.value.resource_pool_key != null ? [1] : []
    content {
      object_type = "resourcepool.Pool"
      moid        = local.resource_pool_moids[each.value.resource_pool_key]
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
      key = tags.value.key
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }

  lifecycle {
    # Set on the profile by the template sync (see server_profile_sync), not by this resource
    ignore_changes = [description, uuid_address_type, static_uuid_address]
  }
}

# Intersight deletes the sync merger and the deploy request once they have run, so they would be recreated,
# re-syncing and re-deploying the profile, on every apply. Instead they are only part of the configuration on
# the applies that should sync or deploy. The markers below hold the timestamp of the apply that created the
# profile or changed its template (or, for the deploy marker, that set a deploy action), and
# input == plantimestamp() identifies it.
resource "terraform_data" "server_profile_sync_marker" {
  for_each = { for s in local.intersight_servers : s.key => s if var.manage_servers }

  input            = plantimestamp()
  triggers_replace = [intersight_server_profile.server_profile[each.key].moid, each.value.profile_template_key]

  lifecycle {
    ignore_changes = [input]
  }
}

resource "terraform_data" "server_profile_deploy_marker" {
  for_each = { for s in local.intersight_servers : s.key => s if var.manage_servers && contains(["deploy", "sync_and_deploy"], s.action) }

  input            = plantimestamp()
  triggers_replace = [intersight_server_profile.server_profile[each.key].moid, each.value.profile_template_key]

  lifecycle {
    ignore_changes = [input]
  }
}

locals {
  # Sync when the profile is created or its template changed, and on every apply while action is sync or sync_and_deploy
  server_profiles_to_sync = {
    for s in local.intersight_servers : s.key => s
    if var.manage_servers && (
      contains(["sync", "sync_and_deploy"], s.action)
      || terraform_data.server_profile_sync_marker[s.key].input == plantimestamp()
    )
  }

  # Deploy when the profile is created, its template changed or its action set to deploy, and on every apply while action is sync_and_deploy
  server_profiles_to_deploy = {
    for s in local.intersight_servers : s.key => s
    if var.manage_servers && (
      s.action == "sync_and_deploy"
      || (s.action == "deploy" && terraform_data.server_profile_deploy_marker[s.key].input == plantimestamp())
    )
  }
}

# Changes on every apply that syncs, so the merger below is replaced even if Intersight has not yet deleted it.
# Kept for every profile, holding the marker timestamp between syncs, so it is not removed after each sync.
resource "terraform_data" "server_profile_sync_trigger" {
  for_each = { for s in local.intersight_servers : s.key => s if var.manage_servers }

  input = contains(["sync", "sync_and_deploy"], each.value.action) ? plantimestamp() : terraform_data.server_profile_sync_marker[each.key].input
}

# Syncs the profile with its template. src_template alone does not copy the template's policies, and
# template_actions sent with the profile are not executed by Intersight, so the sync is a separate
# merge of the template into the profile.
resource "intersight_bulk_mo_merger" "server_profile_sync" {
  for_each = local.server_profiles_to_sync

  merge_action = "Merge"

  sources {
    class_id    = "server.ProfileTemplate"
    object_type = "server.ProfileTemplate"
    moid        = local.server_profile_template_moids[each.value.profile_template_key]
  }

  targets {
    class_id    = "server.Profile"
    object_type = "server.Profile"
    moid        = intersight_server_profile.server_profile[each.key].moid
  }

  lifecycle {
    ignore_changes       = all
    replace_triggered_by = [terraform_data.server_profile_sync_trigger[each.key]]
  }
}

# Lets the sync workflow finish before the profile is deployed
resource "time_sleep" "server_profile_sync_wait" {
  for_each = local.server_profiles_to_deploy

  create_duration = var.profile_sync_wait

  triggers = {
    apply = plantimestamp()
  }

  depends_on = [intersight_bulk_mo_merger.server_profile_sync]
}

# Deploys the profile once it has been synced. Destroying this resource does not affect the profile.
resource "intersight_bulk_request" "server_profile_deploy" {
  for_each = local.server_profiles_to_deploy

  verb                = "PATCH"
  uri                 = "/v1/server/Profiles"
  wait_for_completion = each.value.wait_for_completion

  requests {
    object_type = "bulk.RestSubRequest"
    additional_properties = jsonencode({
      ClassId    = "bulk.RestSubRequest"
      TargetMoid = intersight_server_profile.server_profile[each.key].moid
      Body       = { Action = "Deploy" }
    })
  }

  lifecycle {
    ignore_changes       = all
    replace_triggered_by = [time_sleep.server_profile_sync_wait[each.key]]
  }

  depends_on = [time_sleep.server_profile_sync_wait]
}

# Unassign is sent directly on intersight_server_profile.server_profile's own `action` attribute above
# (a native field on server.Profile), not through a bulk_request side channel.
