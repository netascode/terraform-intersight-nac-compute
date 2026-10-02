locals {
  domain_profiles = flatten([
    for org in local.filtered_intersight_organizations : [
      for profile in try(org.profiles.domain, []) :
      (try(profile.managed, true)
        && (
          (length(var.managed_intersight_domains) == 0 && length(var.managed_intersight_domain_tags) == 0)
          || contains(var.managed_intersight_domains, profile.name)
          || (length(local._tag_filter_intersight_domains) > 0 && alltrue([
            for tf in local._tag_filter_intersight_domains :
            anytrue([for pt in try(profile.tags, []) : pt.key == tf.key && pt.value == tf.value])
          ]))
        )
        ) ? [{
          key                             = format("%s/%s", org.name, profile.name)
          org_name                        = org.name
          name                            = profile.name
          description                     = try(profile.description, local.defaults.compute.intersight.organizations.profiles.domain.description, "")
          target_platform                 = try(profile.target_platform, local.defaults.compute.intersight.organizations.profiles.domain.target_platform)
          action                          = try(profile.action, local.defaults.compute.intersight.organizations.profiles.domain.action)
          tags                            = try(profile.tags, [])
          serial_numbers                  = try(profile.serial_numbers, [])
          ucs_domain_template_key         = try(profile.ucs_domain_template, null) != null ? format("%s/%s", org.name, profile.ucs_domain_template) : null
          switch_a_port_policy_key        = try(profile.switch_a_port_policy, null) != null ? format("%s/%s", org.name, profile.switch_a_port_policy) : null
          switch_b_port_policy_key        = try(profile.switch_b_port_policy, null) != null ? format("%s/%s", org.name, profile.switch_b_port_policy) : null
          switch_control_policy_key       = try(profile.switch_control_policy, null) != null ? format("%s/%s", org.name, profile.switch_control_policy) : null
          system_qos_policy_key           = try(profile.system_qos_policy, null) != null ? format("%s/%s", org.name, profile.system_qos_policy) : null
          vlan_policy_key                 = try(profile.vlan_policy, null) != null ? format("%s/%s", org.name, profile.vlan_policy) : null
          vsan_policy_key                 = try(profile.vsan_policy, null) != null ? format("%s/%s", org.name, profile.vsan_policy) : null
          ntp_policy_key                  = try(profile.ntp_policy, null) != null ? format("%s/%s", org.name, profile.ntp_policy) : null
          snmp_policy_key                 = try(profile.snmp_policy, null) != null ? format("%s/%s", org.name, profile.snmp_policy) : null
          syslog_policy_key               = try(profile.syslog_policy, null) != null ? format("%s/%s", org.name, profile.syslog_policy) : null
          network_connectivity_policy_key = try(profile.network_connectivity_policy, null) != null ? format("%s/%s", org.name, profile.network_connectivity_policy) : null
          ldap_policy_key                 = try(profile.ldap_policy, null) != null ? format("%s/%s", org.name, profile.ldap_policy) : null
      }] : []
    ]
  ])

  domain_switch_profiles = flatten([
    for profile in local.domain_profiles : [
      {
        key                             = format("%s/A", profile.key)
        cluster_key                     = profile.key
        name                            = format("%s-A", profile.name)
        switch_id                       = "A"
        action                          = profile.action
        serial_number                   = try(profile.serial_numbers[0], null)
        port_policy_key                 = profile.switch_a_port_policy_key
        switch_control_policy_key       = profile.switch_control_policy_key
        system_qos_policy_key           = profile.system_qos_policy_key
        vlan_policy_key                 = profile.vlan_policy_key
        vsan_policy_key                 = profile.vsan_policy_key
        ntp_policy_key                  = profile.ntp_policy_key
        snmp_policy_key                 = profile.snmp_policy_key
        syslog_policy_key               = profile.syslog_policy_key
        network_connectivity_policy_key = profile.network_connectivity_policy_key
        ldap_policy_key                 = profile.ldap_policy_key
      },
      {
        key                             = format("%s/B", profile.key)
        cluster_key                     = profile.key
        name                            = format("%s-B", profile.name)
        switch_id                       = "B"
        action                          = profile.action
        serial_number                   = try(profile.serial_numbers[1], null)
        port_policy_key                 = profile.switch_b_port_policy_key
        switch_control_policy_key       = profile.switch_control_policy_key
        system_qos_policy_key           = profile.system_qos_policy_key
        vlan_policy_key                 = profile.vlan_policy_key
        vsan_policy_key                 = profile.vsan_policy_key
        ntp_policy_key                  = profile.ntp_policy_key
        snmp_policy_key                 = profile.snmp_policy_key
        syslog_policy_key               = profile.syslog_policy_key
        network_connectivity_policy_key = profile.network_connectivity_policy_key
        ldap_policy_key                 = profile.ldap_policy_key
      },
    ]
  ])

  # Collect unique FI serial numbers needing lookup
  domain_fi_serials = toset([
    for sp in local.domain_switch_profiles : sp.serial_number
    if sp.serial_number != null
  ])

  # Resolve discovered FI Moid per serial, when Intersight has inventoried it
  domain_fi_moids = {
    for s in local.domain_fi_serials : s => (
      length(data.intersight_network_element_summary.fi[s].results) > 0
      ? data.intersight_network_element_summary.fi[s].results[0].moid
      : null
    )
  }
}

data "intersight_network_element_summary" "fi" {
  for_each = var.manage_intersight_profiles ? local.domain_fi_serials : toset([])
  serial   = each.key
}

resource "intersight_fabric_switch_cluster_profile" "domain_profile" {
  for_each = { for p in local.domain_profiles : p.key => p if var.manage_intersight_profiles }

  name            = each.value.name
  description     = each.value.description
  target_platform = each.value.target_platform
  # Deploy is sent after the switch profiles are created and synced (see domain_profile_deploy)
  action = "No-op"

  dynamic "src_template" {
    for_each = each.value.ucs_domain_template_key != null ? [1] : []
    content {
      object_type = "fabric.SwitchClusterProfileTemplate"
      moid        = local.domain_template_moids[each.value.ucs_domain_template_key]
    }
  }

  dynamic "tags" {
    for_each = each.value.tags
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}

resource "intersight_fabric_switch_profile" "domain_switch_profile" {
  for_each = { for sp in local.domain_switch_profiles : sp.key => sp if var.manage_intersight_profiles }

  name = each.value.name
  # Makes destroy wait for the Unassign workflow to finish before deleting the profile
  wait_for_completion = true
  switch_id           = each.value.switch_id
  # Unassign is a native action on this resource (assignment lives here, not on the cluster profile), so it
  # is set directly here, every apply while action is "unassign" - same convention as the chassis profile.
  action = each.value.action == "unassign" ? "Unassign" : "No-op"

  switch_cluster_profile {
    object_type = "fabric.SwitchClusterProfile"
    moid        = intersight_fabric_switch_cluster_profile.domain_profile[each.value.cluster_key].moid
  }

  dynamic "assigned_switch" {
    for_each = each.value.serial_number != null && local.domain_fi_moids[each.value.serial_number] != null ? [1] : []
    content {
      object_type = "network.Element"
      moid        = local.domain_fi_moids[each.value.serial_number]
    }
  }

  fabric_pre_assign_by_serial = each.value.serial_number != null && local.domain_fi_moids[each.value.serial_number] == null ? each.value.serial_number : null

  dynamic "policy_bucket" {
    for_each = each.value.port_policy_key != null ? [1] : []
    content {
      object_type = "fabric.PortPolicy"
      moid        = local.port_policy_moids[each.value.port_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.switch_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.SwitchControlPolicy"
      moid        = local.switch_control_policy_moids[each.value.switch_control_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.system_qos_policy_key != null ? [1] : []
    content {
      object_type = "fabric.SystemQosPolicy"
      moid        = local.system_qos_policy_moids[each.value.system_qos_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.vlan_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkPolicy"
      moid        = local.vlan_policy_moids[each.value.vlan_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.vsan_policy_key != null ? [1] : []
    content {
      object_type = "fabric.FcNetworkPolicy"
      moid        = local.vsan_policy_moids[each.value.vsan_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.ntp_policy_key != null ? [1] : []
    content {
      object_type = "ntp.Policy"
      moid        = local.ntp_policy_moids[each.value.ntp_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.snmp_policy_key != null ? [1] : []
    content {
      object_type = "snmp.Policy"
      moid        = local.snmp_policy_moids[each.value.snmp_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.syslog_policy_key != null ? [1] : []
    content {
      object_type = "syslog.Policy"
      moid        = local.syslog_policy_moids[each.value.syslog_policy_key]
    }
  }

  dynamic "policy_bucket" {
    for_each = each.value.network_connectivity_policy_key != null ? [1] : []
    content {
      object_type = "networkconfig.Policy"
      moid        = local.network_connectivity_policy_moids[each.value.network_connectivity_policy_key]
    }
  }


  dynamic "policy_bucket" {
    for_each = each.value.ldap_policy_key != null ? [1] : []
    content {
      object_type = "iam.LdapPolicy"
      moid        = local.ldap_policy_moids[each.value.ldap_policy_key]
    }
  }
}

# Intersight deletes the sync mergers and the deploy request once they have run, so they would be recreated,
# re-syncing and re-deploying the profile, on every apply. Instead they are only part of the configuration on
# the applies that should sync or deploy. The markers below hold the timestamp of the apply that created the
# profile or changed its template (or, for the deploy marker, that set a deploy action), and
# input == plantimestamp() identifies it.
resource "terraform_data" "domain_profile_sync_marker" {
  for_each = { for p in local.domain_profiles : p.key => p if var.manage_intersight_profiles && p.ucs_domain_template_key != null }

  input            = plantimestamp()
  triggers_replace = [intersight_fabric_switch_cluster_profile.domain_profile[each.key].moid, each.value.ucs_domain_template_key]

  lifecycle {
    ignore_changes = [input]
  }
}

resource "terraform_data" "domain_profile_deploy_marker" {
  for_each = { for p in local.domain_profiles : p.key => p if var.manage_intersight_profiles && contains(["deploy", "sync_and_deploy"], p.action) }

  input            = plantimestamp()
  triggers_replace = [intersight_fabric_switch_cluster_profile.domain_profile[each.key].moid, each.value.ucs_domain_template_key]

  lifecycle {
    ignore_changes = [input]
  }
}

locals {
  # Sync when the profile is created or its template changed, and on every apply while action is sync or sync_and_deploy
  domain_profiles_to_sync = {
    for p in local.domain_profiles : p.key => p
    if var.manage_intersight_profiles && p.ucs_domain_template_key != null && (
      contains(["sync", "sync_and_deploy"], p.action)
      || terraform_data.domain_profile_sync_marker[p.key].input == plantimestamp()
    )
  }

  domain_switch_profiles_to_sync = {
    for sp in local.domain_switch_profiles : sp.key => merge(sp, {
      template_key = format("%s/%s", local.domain_profiles_to_sync[sp.cluster_key].ucs_domain_template_key, sp.switch_id)
    }) if contains(keys(local.domain_profiles_to_sync), sp.cluster_key)
  }

  # Deploy when the profile is created, its template changed or its action set to deploy, and on every apply while action is sync_and_deploy
  domain_profiles_to_deploy = {
    for p in local.domain_profiles : p.key => p
    if var.manage_intersight_profiles && (
      p.action == "sync_and_deploy"
      || (p.action == "deploy" && terraform_data.domain_profile_deploy_marker[p.key].input == plantimestamp())
    )
  }
}

# Change on every apply that syncs, so the mergers below are replaced even if Intersight has not yet deleted
# them. Kept for every templated profile, holding the marker timestamp between syncs, so they are not removed
# after each sync. The switch copy exists because replace_triggered_by only accepts each.key.
resource "terraform_data" "domain_profile_sync_trigger" {
  for_each = { for p in local.domain_profiles : p.key => p if var.manage_intersight_profiles && p.ucs_domain_template_key != null }

  input = contains(["sync", "sync_and_deploy"], each.value.action) ? plantimestamp() : terraform_data.domain_profile_sync_marker[each.key].input
}

resource "terraform_data" "domain_switch_profile_sync_trigger" {
  for_each = {
    for sp in local.domain_switch_profiles : sp.key => sp
    if contains(keys(terraform_data.domain_profile_sync_trigger), sp.cluster_key)
  }

  input = terraform_data.domain_profile_sync_trigger[each.value.cluster_key].input
}

# Syncs the domain profile with its template. template_actions sent with the profile are not executed by
# Intersight, so the sync is a separate merge of the template into the profile.
resource "intersight_bulk_mo_merger" "domain_profile_sync" {
  for_each = local.domain_profiles_to_sync

  merge_action = "Merge"

  sources {
    class_id    = "fabric.SwitchClusterProfileTemplate"
    object_type = "fabric.SwitchClusterProfileTemplate"
    moid        = local.domain_template_moids[each.value.ucs_domain_template_key]
  }

  targets {
    class_id    = "fabric.SwitchClusterProfile"
    object_type = "fabric.SwitchClusterProfile"
    moid        = intersight_fabric_switch_cluster_profile.domain_profile[each.key].moid
  }

  lifecycle {
    ignore_changes       = all
    replace_triggered_by = [terraform_data.domain_profile_sync_trigger[each.key]]
  }
}

# Syncs each switch profile with the matching switch template of the domain template, which carries the policies
resource "intersight_bulk_mo_merger" "domain_switch_profile_sync" {
  for_each = local.domain_switch_profiles_to_sync

  merge_action = "Merge"

  sources {
    class_id    = "fabric.SwitchProfileTemplate"
    object_type = "fabric.SwitchProfileTemplate"
    moid        = local.domain_switch_template_moids[each.value.template_key]
  }

  targets {
    class_id    = "fabric.SwitchProfile"
    object_type = "fabric.SwitchProfile"
    moid        = intersight_fabric_switch_profile.domain_switch_profile[each.key].moid
  }

  lifecycle {
    ignore_changes       = all
    replace_triggered_by = [terraform_data.domain_switch_profile_sync_trigger[each.key]]
  }

  depends_on = [intersight_bulk_mo_merger.domain_profile_sync]
}

# Lets the sync workflows finish before the domain profile is deployed
resource "time_sleep" "domain_profile_sync_wait" {
  for_each = local.domain_profiles_to_deploy

  create_duration = var.profile_sync_wait

  triggers = {
    apply = plantimestamp()
  }

  depends_on = [
    intersight_fabric_switch_profile.domain_switch_profile,
    intersight_bulk_mo_merger.domain_switch_profile_sync,
  ]
}

# Deploys the domain profile, which cascades to both switch profiles, once they have been synced. Destroying
# this resource does not affect the profile.
resource "intersight_bulk_request" "domain_profile_deploy" {
  for_each = local.domain_profiles_to_deploy

  verb = "PATCH"
  uri  = "/v1/fabric/SwitchClusterProfiles"

  requests {
    object_type = "bulk.RestSubRequest"
    additional_properties = jsonencode({
      ClassId    = "bulk.RestSubRequest"
      TargetMoid = intersight_fabric_switch_cluster_profile.domain_profile[each.key].moid
      Body       = { Action = "Deploy" }
    })
  }

  lifecycle {
    ignore_changes       = all
    replace_triggered_by = [time_sleep.domain_profile_sync_wait[each.key]]
  }

  depends_on = [time_sleep.domain_profile_sync_wait]
}

# Unassign is sent directly on intersight_fabric_switch_profile.domain_switch_profile's own `action`
# attribute above (a native field on fabric.SwitchProfile), not through a bulk_request side channel.
