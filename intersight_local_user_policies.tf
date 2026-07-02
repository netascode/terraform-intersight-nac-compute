locals {
  local_user_policies = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.local_user, []) :
      try(policy.managed, true) ? [{
        key                       = format("%s/%s", org.name, policy.name)
        org_name                  = org.name
        name                      = policy.name
        description               = try(policy.description, local.defaults.compute.intersight.organizations.policies.local_user.description, "")
        strong_password           = try(policy.strong_password, local.defaults.compute.intersight.organizations.policies.local_user.strong_password)
        password_expiry           = try(policy.password_expiry, local.defaults.compute.intersight.organizations.policies.local_user.password_expiry)
        password_expiry_duration  = try(policy.password_expiry_duration, local.defaults.compute.intersight.organizations.policies.local_user.password_expiry_duration)
        password_history          = try(policy.password_history, local.defaults.compute.intersight.organizations.policies.local_user.password_history)
        notification_period       = try(policy.notification_period, local.defaults.compute.intersight.organizations.policies.local_user.notification_period)
        grace_period              = try(policy.grace_period, local.defaults.compute.intersight.organizations.policies.local_user.grace_period)
        always_send_user_password = try(policy.always_send_user_password, local.defaults.compute.intersight.organizations.policies.local_user.always_send_user_password)
        tags                      = try(policy.tags, [])
      }] : []
    ]
  ])

  local_user_users = flatten([
    for org in try(local.intersight.organizations, []) : [
      for policy in try(org.policies.local_user, []) :
      try(policy.managed, true) ? [
        for user in try(policy.users, []) : {
          key             = format("%s/%s/%s", org.name, policy.name, user.username)
          policy_key      = format("%s/%s", org.name, policy.name)
          org_name        = org.name
          username        = user.username
          role            = user.role
          password        = try(user.password, null)
          enabled         = try(user.enabled, local.defaults.compute.intersight.organizations.policies.local_user.users.enabled)
          change_password = try(user.change_password, local.defaults.compute.intersight.organizations.policies.local_user.users.change_password)
        }
      ] : []
    ]
  ])
}

resource "intersight_iam_end_point_user_policy" "local_user_policy" {
  for_each = { for p in local.local_user_policies : p.key => p }

  name        = each.value.name
  description = each.value.description

  password_properties {
    object_type              = "iam.EndPointPasswordProperties"
    enforce_strong_password  = each.value.strong_password
    enable_password_expiry   = each.value.password_expiry
    password_expiry_duration = each.value.password_expiry_duration
    password_history         = each.value.password_history
    notification_period      = each.value.notification_period
    grace_period             = each.value.grace_period
    force_send_password      = each.value.always_send_user_password
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

resource "intersight_iam_end_point_user" "local_user" {
  for_each = { for u in local.local_user_users : u.key => u }

  name = each.value.username

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}

resource "intersight_iam_end_point_user_role" "local_user_role" {
  for_each = { for u in local.local_user_users : u.key => u }

  enabled         = each.value.enabled
  change_password = each.value.change_password
  password        = each.value.password

  end_point_role {
    object_type = "iam.EndPointRole"
    selector    = "Name eq '${each.value.role}' and Type eq 'IMC'"
  }

  end_point_user {
    object_type = "iam.EndPointUser"
    moid        = intersight_iam_end_point_user.local_user[each.key].moid
  }

  end_point_user_policy {
    object_type = "iam.EndPointUserPolicy"
    moid        = intersight_iam_end_point_user_policy.local_user_policy[each.value.policy_key].moid
  }

  depends_on = [
    intersight_iam_end_point_user_policy.local_user_policy,
    intersight_iam_end_point_user.local_user,
  ]
}
