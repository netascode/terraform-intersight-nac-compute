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

      # For IMC: embed private key via additional_properties (not a direct provider attribute)
      # For RootCA: embed certificate name via additional_properties
      additional_properties = certificates.value.certificate_type == "Imc" ? jsonencode({
        CertType   = try(certificates.value.cert_type, "None")
        Privatekey = base64encode(try(certificates.value.private_key, ""))
        }) : jsonencode({
        CertificateName = certificates.value.name
      })

      certificate {
        object_type = "x509.Certificate"
        # PEM certificate is set via additional_properties as base64 — not a direct attribute
        additional_properties = jsonencode({
          PemCertificate = base64encode(try(certificates.value.pem_certificate, ""))
        })
      }
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
}
