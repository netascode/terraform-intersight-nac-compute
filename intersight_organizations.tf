locals {
  organizations_managed = [
    for org in try(local.intersight.organizations, []) : {
      name        = org.name
      description = try(org.description, local.defaults.compute.intersight.organizations.description, "")
      tags        = try(org.tags, [])
    } if try(org.managed, local.defaults.compute.intersight.organizations.managed, true)
  ]

  organizations_unmanaged = [
    for org in try(local.intersight.organizations, []) : {
      name = org.name
    } if !try(org.managed, local.defaults.compute.intersight.organizations.managed, true)
  ]
}

resource "intersight_organization_organization" "organizations" {
  for_each = { for o in local.organizations_managed : o.name => o if var.manage_intersight_organizations }

  name        = each.value.name
  description = each.value.description

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
}

data "intersight_organization_organization" "organizations" {
  for_each = merge(
    { for o in local.organizations_unmanaged : o.name => o },
    var.manage_intersight_organizations ? {} : { for o in local.organizations_managed : o.name => o }
  )

  name = each.value.name
}

