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
      power_state          = try(server.provisioning.power_state, null)
      tags                 = try(server.tags, [])
      # Per-server settings, which override the template's (servers[].provisioning.intersight)
      override_policy_keys = {
        for field, name in try(server.provisioning.intersight.policies, {}) :
        field => format("%s/%s", server.provisioning.intersight.organization, name) if name != null
      }
      override_uuid_pool_key   = try(server.provisioning.intersight.uuid_pool, null) != null ? format("%s/%s", server.provisioning.intersight.organization, server.provisioning.intersight.uuid_pool) : null
      override_target_platform = try(server.provisioning.intersight.target_platform, null)
    }] : []
  ])

  # A server is standalone when it has no template, or overrides any of its template's settings: Intersight
  # rejects edits to a profile derived from a template (403 gershwin_cannot_edit_derived_sp), so such a
  # profile is not attached to its template, and its policies are set by this module instead
  intersight_server_standalone = {
    for s in local.intersight_servers : s.key => (
      s.profile_template_key == null
      || length(s.override_policy_keys) > 0
      || s.override_uuid_pool_key != null
      || s.override_target_platform != null
    )
  }

  # The settings of a standalone server's profile: the template's, as of the last snapshot (see
  # server_profile_template_snapshot), with the server's own settings replacing them
  intersight_server_settings = {
    for s in local.intersight_servers : s.key => {
      policy_keys = merge(
        try(terraform_data.server_profile_template_snapshot[s.key].output.policy_keys, {}),
        s.override_policy_keys,
      )
      description = try(terraform_data.server_profile_template_snapshot[s.key].output.description, "")
      uuid_pool_key = s.override_uuid_pool_key != null ? s.override_uuid_pool_key : try(
        terraform_data.server_profile_template_snapshot[s.key].output.uuid_pool_key, null
      )
      # server.Profile defaults to Standalone and does not inherit TargetPlatform from src_template
      target_platform = coalesce(
        s.override_target_platform,
        try(local.server_profile_template_target_platforms[s.profile_template_key], null),
        "Standalone",
      )
    }
  }

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
  target_platform        = local.intersight_server_settings[each.key].target_platform
  # The UUID settings are set by server_profile_deploy (see there), so uuid_address_type is ignored here

  # SrcTemplate is set here via additional_properties, not the native src_template block, because Intersight
  # rejects a PATCH that changes src_template directly from one template to another on a profile already
  # attached to a template (403 gershwin_derived_sp_invalid_src) - confirmed as a genuine two-apply-required
  # API constraint by the module maintainer in CiscoDevNet/terraform-provider-intersight#261/#263, not a
  # transport artifact. Reassigning a template therefore requires removing profile_template (sends
  # SrcTemplate: null) on one apply, then setting the new one on the next. additional_properties is a plain
  # string attribute under our full control, so normal Terraform diffing sends the right PATCH on every apply
  # with no extra gating needed, unlike the provider's own optional+computed fields (e.g. assigned_server).
  #
  # A standalone profile (see intersight_server_standalone) has no SrcTemplate, and its policies and description
  # are set here too, rather than with the native policy_bucket and description: Intersight returns both in
  # the profile's additional properties, which the provider compares with these, ignoring the order of the
  # policies. The native policy_bucket is misread for firmware.Policy and boot.PrecisionPolicy entries (known
  # provider bug, see intersight_server_profile_templates.tf), which would cause a perpetual diff. A derived
  # profile sets neither, as its policies and description are set by the template sync.
  additional_properties = jsonencode(merge(
    {
      SrcTemplate = !local.intersight_server_standalone[each.key] ? {
        Moid       = local.server_profile_template_moids[each.value.profile_template_key]
        ObjectType = "server.ProfileTemplate"
      } : null
    },
    local.intersight_server_standalone[each.key] ? {
      PolicyBucket = [
        for field, key in local.intersight_server_settings[each.key].policy_keys : {
          ClassId    = "mo.MoRef"
          Moid       = local.server_policy_moids[field][key]
          ObjectType = local.server_policy_object_types[field]
        }
      ]
    } : {},
    # Intersight omits an empty description, which would never match an empty string here
    local.intersight_server_standalone[each.key] && local.intersight_server_settings[each.key].description != "" ? {
      Description = local.intersight_server_settings[each.key].description
    } : {},
  ))

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
    # description is set on the profile by the template sync (see server_profile_sync), or in
    # additional_properties for a standalone profile, not by the native attribute.
    # target_platform is managed (server, then template, then "Standalone"; see intersight_server_settings), so a
    # server with overrides keeps its template's platform when its profile is detached from the template. It is
    # not ignored because a profile created by an earlier module version for a server without a template was
    # always "Standalone"; Intersight then rejects the server's FI-attached settings (400
    # gershwin_uuid_not_supported) until the platform is corrected. server_profile_deploy ignores it.
    ignore_changes = [description, uuid_address_type, static_uuid_address]
  }
}

# The template settings a server that overrides some of them takes from its template. Taken at the same points
# in time as a derived profile is synced with its template, so that action works the same for both: when the
# server is added, its template changes or it starts overriding its template's settings, and on every apply
# while action is sync or sync_and_deploy. Changes to the server's own settings apply on the next apply.
resource "terraform_data" "server_profile_template_snapshot" {
  for_each = {
    for s in local.intersight_servers : s.key => s
    if var.manage_servers && local.intersight_server_standalone[s.key] && s.profile_template_key != null
  }

  input = {
    policy_keys   = try(local.server_profile_template_policy_keys[each.value.profile_template_key], {})
    description   = try(local.server_profile_template_settings[each.value.profile_template_key].description, "")
    uuid_pool_key = try(local.server_profile_template_settings[each.value.profile_template_key].uuid_pool_key, null)
  }
  triggers_replace = [
    each.value.profile_template_key,
    contains(["sync", "sync_and_deploy"], each.value.action) ? plantimestamp() : "",
  ]

  lifecycle {
    ignore_changes = [input]
  }
}

# Intersight deletes the sync merger and the deploy request once they have run, so they would be recreated,
# re-syncing and re-deploying the profile, on every apply. Instead they are only part of the configuration on
# the applies that should sync or deploy. The markers below hold the timestamp of the apply that created the
# profile or changed its template (or, for the deploy marker, that set a deploy action), and
# input == plantimestamp() identifies it.
#
# Both are also replaced when a server with a template starts or stops overriding its template's settings, as that
# changes where the profile's policies come from, like a template change does
# (see server_profile_template_identity).
resource "terraform_data" "server_profile_sync_marker" {
  for_each = { for s in local.intersight_servers : s.key => s if var.manage_servers }

  input            = plantimestamp()
  triggers_replace = [intersight_server_profile.server_profile[each.key].moid, local.server_profile_template_identity[each.key]]

  lifecycle {
    ignore_changes = [input]
  }
}

resource "terraform_data" "server_profile_deploy_marker" {
  for_each = { for s in local.intersight_servers : s.key => s if var.manage_servers && contains(["deploy", "sync_and_deploy"], s.action) }

  input            = plantimestamp()
  triggers_replace = [intersight_server_profile.server_profile[each.key].moid, local.server_profile_template_identity[each.key]]

  lifecycle {
    ignore_changes = [input]
  }
}

locals {
  # The template a server's profile takes its settings from, and whether it overrides some of them. Unchanged for a
  # server without a template, or one that does not override any template settings, so their markers are kept.
  server_profile_template_identity = {
    for s in local.intersight_servers : s.key => (
      s.profile_template_key != null && local.intersight_server_standalone[s.key]
      ? format("standalone:%s", s.profile_template_key)
      : s.profile_template_key
    )
  }

  # Sync when the profile is created or its template changed, and on every apply while action is sync or sync_and_deploy.
  # Excludes a standalone profile (see intersight_server_standalone): it has no template to merge in, or overrides
  # some of its template's settings and takes the others from server_profile_template_snapshot instead.
  server_profiles_to_sync = {
    for s in local.intersight_servers : s.key => s
    if var.manage_servers && !local.intersight_server_standalone[s.key] && (
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
  target_platform     = local.intersight_server_settings[each.key].target_platform
  # The create is applied as an update of the existing profile, and Intersight rejects one that changes properties
  # a template-derived profile takes from its template (403 gershwin_cannot_edit_derived_sp). The provider would
  # send NONE, while the sync sets the template's UUID address type.
  #
  # A standalone profile's UUID settings follow its settings (see intersight_server_settings) and are set here, not
  # on server_profile: Intersight does not return them in the profile's additional properties, and server_profile
  # must ignore uuid_address_type for a derived profile, which ignore_changes cannot do for some profiles only.
  # uuid_pool is optional and computed, so a derived profile's, set by the template sync, is left alone.
  server_assignment_mode = each.value.serial_number != null ? "Static" : (each.value.resource_pool_key != null ? "Pool" : "None")
  uuid_address_type = local.intersight_server_standalone[each.key] ? (
    local.intersight_server_settings[each.key].uuid_pool_key != null ? "POOL" : "NONE"
  ) : local.server_profile_template_uuid_address_types[each.value.profile_template_key]

  dynamic "uuid_pool" {
    for_each = local.intersight_server_standalone[each.key] && local.intersight_server_settings[each.key].uuid_pool_key != null ? [1] : []
    content {
      object_type = "uuidpool.Pool"
      moid        = local.uuid_pool_moids[local.intersight_server_settings[each.key].uuid_pool_key]
    }
  }

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
      server_pool, shared_scope, src_template, target_platform, uuid, uuid_lease, version_context,
      additional_properties,
    ]
  }

  depends_on = [intersight_server_profile.server_profile, time_sleep.server_profile_sync_wait]
}

# Unassign is sent directly on intersight_server_profile.server_profile's own `action` attribute above
# (a native field on server.Profile).

# ---------------------------------------------------------------------------
# Server power state (servers[].provisioning.power_state)
#
# The provider has no resource for compute.ServerSetting (only a data source). intersight_bulk_request can send the
# PATCH (top-level uri = collection, sub request with TargetMoid and a typed Body), but a PATCH bulk request is not
# persisted, so the provider's read-back fails with a 404 / "inconsistent result after apply". The power operation is
# therefore sent by scripts/set_server_power.py (a signed PATCH of AdminPowerState). AdminPowerState is a trigger, not a state: Intersight starts a power workflow and
# reads the property back as "Policy", so the actual state is always taken from OperPowerState. Power is reconciled declaratively: a request is only created when the
# actual power state (compute.PhysicalSummary OperPowerState) differs from the desired one, and it is dropped
# again once the server has converged. A server without power_state is never touched.
# ---------------------------------------------------------------------------
locals {
  server_power_admin_states = {
    on       = "PowerOn"
    shutdown = "Shutdown"
    off      = "PowerOff"
  }

  # Servers that set power_state and have been inventoried by Intersight
  server_power_candidates = {
    for s in local.intersight_servers : s.key => s
    if var.manage_servers && s.power_state != null && try(local.server_moids[s.key], null) != null
  }

  # Actual power state ("on" / "off"), empty when Intersight does not report one
  server_oper_power_states = {
    for k, s in local.server_power_candidates : k => lower(try(data.intersight_compute_physical_summary.server[k].results[0].oper_power_state, ""))
  }

  # Servers whose actual power state differs from the desired one. shutdown and off both mean the server is off.
  server_power_changes = {
    for k, s in local.server_power_candidates : format("%s/%s", k, local.server_power_admin_states[s.power_state]) => {
      key         = k
      admin_state = local.server_power_admin_states[s.power_state]
    }
    if local.server_oper_power_states[k] != "" && local.server_oper_power_states[k] != (s.power_state == "on" ? "on" : "off")
  }
}

data "intersight_compute_server_setting" "server_setting" {
  for_each = local.server_power_candidates

  server {
    object_type = local.server_object_types[each.key]
    moid        = local.server_moids[each.key]
  }
}

# The request exists only while the server differs from the desired power state, and it is re-sent on every apply
# during that time: triggers_replace changes with each plan, so a marker left over from an earlier request (for
# example when the server was powered back on in the GUI before the converged plan was applied) cannot hide drift.
# Once the server has converged the entry is dropped from state, which runs no command. A failed call is retried on
# the next apply because the resource is tainted. Credentials reach the script through the INTERSIGHT_* environment
# variables.
resource "terraform_data" "server_power" {
  for_each = local.server_power_changes

  triggers_replace = plantimestamp()

  provisioner "local-exec" {
    command = "python3 '${path.module}/scripts/set_server_power.py' --moid ${data.intersight_compute_server_setting.server_setting[each.value.key].results[0].moid} --state ${each.value.admin_state}"
  }
}
