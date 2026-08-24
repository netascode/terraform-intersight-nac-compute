locals {
  drive_security_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.drive_security, []) :
      try(policy.managed, true) ? [{
        key         = format("%s/%s", org.name, policy.name)
        org_name    = org.name
        name        = policy.name
        description = try(policy.description, local.defaults.compute.intersight.organizations.policies.drive_security.description, "")
        key_setting = try(policy.key_setting, null)
        tags        = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_storage_drive_security_policy" "drive_security_policy" {
  for_each = { for p in local.drive_security_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = each.value.description

  dynamic "key_setting" {
    for_each = each.value.key_setting != null ? [each.value.key_setting] : []
    content {
      object_type = "storage.KeySetting"
      key_type    = try(key_setting.value.key_type, "Manual")

      dynamic "manual_key" {
        for_each = try(key_setting.value.manual_key, null) != null ? [key_setting.value.manual_key] : []
        content {
          existing_key = try(manual_key.value.existing_key, null)
          new_key      = try(manual_key.value.new_key, null)
        }
      }

      dynamic "remote_key" {
        for_each = try(key_setting.value.remote_key, null) != null ? [key_setting.value.remote_key] : []
        content {
          existing_key       = try(remote_key.value.existing_key, null)
          server_certificate = try(remote_key.value.server_certificate, null)

          dynamic "auth_credentials" {
            for_each = try(remote_key.value.auth_credentials, null) != null ? [remote_key.value.auth_credentials] : []
            content {
              use_authentication = try(auth_credentials.value.use_authentication, false)
              username           = try(auth_credentials.value.username, null)
              password           = try(auth_credentials.value.password, null)
            }
          }

          dynamic "primary_server" {
            for_each = try(remote_key.value.primary_server, null) != null ? [remote_key.value.primary_server] : []
            content {
              ip_address            = try(primary_server.value.ip_address, null)
              port                  = try(primary_server.value.port, 5696)
              timeout               = try(primary_server.value.timeout, 60)
              enable_drive_security = try(primary_server.value.enable_drive_security, true)
            }
          }

          dynamic "secondary_server" {
            for_each = try(remote_key.value.secondary_server, null) != null ? [remote_key.value.secondary_server] : []
            content {
              ip_address            = try(secondary_server.value.ip_address, null)
              port                  = try(secondary_server.value.port, 5696)
              timeout               = try(secondary_server.value.timeout, 60)
              enable_drive_security = try(secondary_server.value.enable_drive_security, true)
            }
          }
        }
      }
    }
  }

  dynamic "tags" {
    for_each = try(each.value.tags, [])
    content {
      key   = tags.value.key
      value = try(tags.value.value, "")
      type  = try(tags.value.type, "KeyValue")
    }
  }

  organization {
    object_type = "organization.Organization"
    moid        = local.org_moids[each.value.org_name]
  }
}
