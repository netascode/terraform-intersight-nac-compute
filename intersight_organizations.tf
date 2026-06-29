locals {
  organizations = [
    for org in try(local.intersight.organizations, []) : {
      name = org.name
    }
  ]
}

data "intersight_organization_organization" "organizations" {
  for_each = { for org in local.organizations : org.name => org }

  name = each.value.name
}

locals {
  org_moids = {
    for org in local.organizations :
    org.name => data.intersight_organization_organization.organizations[org.name].results[0].moid
  }
}

