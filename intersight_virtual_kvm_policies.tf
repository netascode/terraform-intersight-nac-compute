locals {
  virtual_kvm_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.virtual_kvm, []) :
      try(policy.managed, true) ? [{
        key                = format("%s/%s", org.name, policy.name)
        org_name           = org.name
        name               = policy.name
        description        = try(policy.description, local.defaults.compute.intersight.organizations.policies.virtual_kvm.description, "")
        enabled            = try(policy.enabled, local.defaults.compute.intersight.organizations.policies.virtual_kvm.enabled)
        maximum_sessions   = try(policy.maximum_sessions, local.defaults.compute.intersight.organizations.policies.virtual_kvm.maximum_sessions)
        remote_port        = try(policy.remote_port, local.defaults.compute.intersight.organizations.policies.virtual_kvm.remote_port)
        video_encryption   = try(policy.video_encryption, local.defaults.compute.intersight.organizations.policies.virtual_kvm.video_encryption)
        local_server_video = try(policy.local_server_video, local.defaults.compute.intersight.organizations.policies.virtual_kvm.local_server_video)
        tunneled_kvm       = try(policy.tunneled_kvm, local.defaults.compute.intersight.organizations.policies.virtual_kvm.tunneled_kvm)
      }] : []
    ]
  ])
}

resource "intersight_kvm_policy" "virtual_kvm_policy" {
  for_each = { for p in local.virtual_kvm_policies : p.key => p }

  description               = each.value.description
  enabled                   = each.value.enabled
  enable_local_server_video = each.value.local_server_video
  enable_video_encryption   = each.value.video_encryption
  maximum_sessions          = each.value.maximum_sessions
  name                      = each.value.name
  remote_port               = each.value.remote_port
  tunneled_kvm_enabled      = each.value.tunneled_kvm

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
