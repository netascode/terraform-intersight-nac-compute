locals {
  certificate_management_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.certificate_management, []) :
      try(policy.managed, true) ? [{
        key          = format("%s/%s", org.name, policy.name)
        org_name     = org.name
        name         = policy.name
        description  = try(policy.description, local.defaults.compute.intersight.organizations.policies.certificate_management.description, "")
        certificates = try(policy.certificates, [])
        tags         = try(policy.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_certificatemanagement_policy" "certificate_management_policy" {
  for_each = { for p in local.certificate_management_policies : p.key => p if var.manage_intersight_policies }

  name        = each.value.name
  description = each.value.description

  dynamic "certificates" {
    for_each = each.value.certificates
    content {
      object_type = certificates.value.certificate_type == "Imc" ? "certificatemanagement.Imc" : "certificatemanagement.RootCaCertificate"
      enabled     = try(certificates.value.enabled, true)
      privatekey  = try(certificates.value.private_key, null)

      certificate {
        pem_certificate = certificates.value.pem_certificate
        object_type     = "x509.Certificate"
      }
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
