locals {
  vhba_templates = flatten([
    for org in local.filtered_intersight_organizations : [
      for tmpl in try(org.templates.vhba, []) :
      try(tmpl.managed, true) ? [{
        key                     = format("%s/%s", org.name, tmpl.name)
        org_name                = org.name
        name                    = tmpl.name
        description             = try(tmpl.description, local.defaults.compute.intersight.organizations.templates.vhba.description, "")
        fabric                  = try(tmpl.fabric, null)
        vhba_type               = try(tmpl.vhba_type, local.defaults.compute.intersight.organizations.templates.vhba.vhba_type)
        persistent_lun_bindings = try(tmpl.persistent_lun_bindings, local.defaults.compute.intersight.organizations.templates.vhba.persistent_lun_bindings)
        enable_override         = try(tmpl.enable_override, local.defaults.compute.intersight.organizations.templates.vhba.enable_override)
        pin_group_name          = try(tmpl.pin_group_name, null)
        peer_vhba_name          = try(tmpl.peer_vhba_name, null)
        wwpn_pool_key           = try(tmpl.wwpn_pool, null) != null ? format("%s/%s", org.name, tmpl.wwpn_pool) : null
        fc_adapter_policy_key   = try(tmpl.fibre_channel_adapter_policy, null) != null ? format("%s/%s", org.name, tmpl.fibre_channel_adapter_policy) : null
        fc_network_policy_key   = try(tmpl.fibre_channel_network_policy, null) != null ? format("%s/%s", org.name, tmpl.fibre_channel_network_policy) : null
        fc_qos_policy_key       = try(tmpl.fibre_channel_qos_policy, null) != null ? format("%s/%s", org.name, tmpl.fibre_channel_qos_policy) : null
        tags                    = try(tmpl.tags, [])
      }] : []
    ]
  ])
}

resource "intersight_vnic_vhba_template" "vhba_template" {
  for_each = { for t in local.vhba_templates : t.key => t if var.manage_intersight_templates }

  description         = each.value.description
  enable_override     = each.value.enable_override
  name                = each.value.name
  persistent_bindings = each.value.persistent_lun_bindings
  switch_id           = each.value.fabric != null ? each.value.fabric : "None"
  type                = each.value.vhba_type

  dynamic "fc_adapter_policy" {
    for_each = each.value.fc_adapter_policy_key != null ? [1] : []
    content {
      object_type = "vnic.FcAdapterPolicy"
      moid        = local.fc_adapter_policy_moids[each.value.fc_adapter_policy_key]
    }
  }

  dynamic "fc_network_policy" {
    for_each = each.value.fc_network_policy_key != null ? [1] : []
    content {
      object_type = "vnic.FcNetworkPolicy"
      moid        = local.fc_network_policy_moids[each.value.fc_network_policy_key]
    }
  }

  dynamic "fc_qos_policy" {
    for_each = each.value.fc_qos_policy_key != null ? [1] : []
    content {
      object_type = "vnic.FcQosPolicy"
      moid        = local.fc_qos_policy_moids[each.value.fc_qos_policy_key]
    }
  }

  dynamic "wwpn_pool" {
    for_each = each.value.wwpn_pool_key != null ? [1] : []
    content {
      object_type = "fcpool.Pool"
      moid        = local.wwpn_pool_moids[each.value.wwpn_pool_key]
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
