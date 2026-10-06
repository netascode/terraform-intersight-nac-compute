locals {
  intersight_servers = flatten([
    for server in local.filtered_servers :
    try(server.provisioning.managed, true) ? [{
      key                  = server.name
      name                 = server.name
      org_name             = server.provisioning.intersight.organization
      profile_template_key = try(server.provisioning.profile_template, null) != null ? format("%s/%s", server.provisioning.intersight.organization, server.provisioning.profile_template) : null
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
  target_platform = each.value.profile_template_key != null ? local.server_profile_template_target_platforms[each.value.profile_template_key] : "Standalone"

  # SrcTemplate is set here via additional_properties, not the native src_template block, because Intersight
  # rejects a PATCH that changes src_template directly from one template to another on a profile already
  # attached to a template (403 gershwin_derived_sp_invalid_src) - confirmed as a genuine two-apply-required
  # API constraint by the module maintainer in CiscoDevNet/terraform-provider-intersight#261/#263, not a
  # transport artifact. Reassigning a template therefore requires removing profile_template (sends
  # SrcTemplate: null) on one apply, then setting the new one on the next. additional_properties is a plain
  # string attribute under our full control, so normal Terraform diffing sends the right PATCH on every apply
  # with no extra gating needed, unlike the provider's own optional+computed fields (e.g. assigned_server).
  additional_properties = jsonencode({
    SrcTemplate = each.value.profile_template_key != null ? {
      Moid       = local.server_profile_template_moids[each.value.profile_template_key]
      ObjectType = "server.ProfileTemplate"
    } : null
  })

  # Suppressed while action is "unassign": assigned_server/server_pre_assign_by_serial are computed purely
  # from serial_number/discovery, with no awareness of action. Without this guard, the first apply after a
  # successful Unassign would see the still-configured serial_number resolve again and re-attach the server -
  # Unassign is the one-shot command that actually detaches it; these optional+computed fields must stay out
  # of the request entirely until the server is reassigned by removing the unassign action.
  dynamic "assigned_server" {
    for_each = each.value.action != "unassign" && each.value.serial_number != null && local.server_moids[each.key] != null ? [1] : []
    content {
      object_type = local.server_object_types[each.key]
      moid        = local.server_moids[each.key]
    }
  }

  server_pre_assign_by_serial = each.value.action != "unassign" && each.value.serial_number != null && local.server_moids[each.key] == null ? each.value.serial_number : null

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
    # description is set on the profile by the template sync (see server_profile_sync), not by this resource.
    # target_platform is a property of the physical hardware, not the template - it is only correct to send
    # on create (inherited from profile_template_key, see above). Detaching the template later would otherwise
    # recompute it as "Standalone" and Intersight rejects that PATCH once FI-attached policies are in place
    # (400 invalid_server_family_for_platform_type), so changes to it after creation are ignored.
    ignore_changes = [description, uuid_address_type, static_uuid_address, target_platform]
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
  # Sync when the profile is created or its template changed, and on every apply while action is sync or sync_and_deploy.
  # Excludes an untemplated (detached) profile: there is no template to merge in, and
  # server_profile_template_moids has no entry for a null key.
  server_profiles_to_sync = {
    for s in local.intersight_servers : s.key => s
    if var.manage_servers && s.profile_template_key != null && (
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

# Lets the sync workflow finish before the profile is deployed. Kept for every server with a deploy action and
# re-created only when the profile is deployed (the marker timestamp changes, or on every apply for
# sync_and_deploy), so it is not removed and re-added by the plans in between.
resource "time_sleep" "server_profile_sync_wait" {
  for_each = { for s in local.intersight_servers : s.key => s if var.manage_servers && contains(["deploy", "sync_and_deploy"], s.action) }

  create_duration = var.profile_sync_wait

  triggers = {
    apply = each.value.action == "sync_and_deploy" ? plantimestamp() : terraform_data.server_profile_deploy_marker[each.key].input
  }

  depends_on = [intersight_bulk_mo_merger.server_profile_sync]
}

# Deploys the profile once it has been synced. A second intersight_server_profile for the same name and
# organization, as easy-imm does: Intersight does not keep a bulk request for a synchronous PATCH, so
# intersight_bulk_request cannot track it and fails after creating it. Intersight treats the create as an update
# of the existing profile, so everything but the deploy action is ignored. It is kept for every server, and
# only sends Deploy on the applies that deploy: removing it from the configuration would delete the profile.
resource "intersight_server_profile" "server_profile_deploy" {
  for_each = { for s in local.intersight_servers : s.key => s if var.manage_servers }

  name   = each.value.name
  action = contains(keys(local.server_profiles_to_deploy), each.key) ? "Deploy" : "No-op"
  # Always waits, as easy-imm does: the deploy returns once the profile workflows have finished, and destroying
  # this resource, which deletes the profile, waits for the Unassign workflow first. A value that changes between
  # applies would show up as a pending change in the plans in between.
  wait_for_completion = true
  target_platform     = each.value.profile_template_key != null ? local.server_profile_template_target_platforms[each.value.profile_template_key] : "Standalone"
  # The create is applied as an update of the existing profile, and Intersight rejects one that changes properties
  # a template-derived profile takes from its template (403 gershwin_cannot_edit_derived_sp). The provider would
  # send NONE, while the sync sets the template's UUID address type.
  server_assignment_mode = each.value.serial_number != null ? "Static" : (each.value.resource_pool_key != null ? "Pool" : "None")
  uuid_address_type      = each.value.profile_template_key != null ? local.server_profile_template_uuid_address_types[each.value.profile_template_key] : "NONE"

  # Applies changes that need a host reboot during the deploy, as easy-imm does, instead of waiting for a
  # manual activation that would leave the profile short of Associated
  dynamic "scheduled_actions" {
    for_each = contains(keys(local.server_profiles_to_deploy), each.key) ? [1] : []
    content {
      action            = "Activate"
      object_type       = "policy.ScheduledAction"
      proceed_on_reboot = true
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
    ignore_changes = [
      action_params, ancestors, assigned_server, associated_server, associated_server_pool, create_time, description, domain_group_moid,
      mod_time, owners, parent, permission_resources, policy_bucket, reservation_references, running_workflows,
      server_pool, shared_scope, src_template, target_platform, uuid, uuid_lease, uuid_pool, version_context,
      additional_properties,
    ]
  }

  depends_on = [intersight_server_profile.server_profile, time_sleep.server_profile_sync_wait]
}

# Unassign is sent directly on intersight_server_profile.server_profile's own `action` attribute above
# (a native field on server.Profile).
