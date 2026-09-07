locals {
  qualifier_object_types = {
    rack_server     = "resource.RackServerQualifier"
    blade_server    = "resource.BladeQualifier"
    chassis_servers = "resource.ChassisServersQualifier"
  }

  qualification_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.qualification, []) :
      try(policy.managed, true) ? [{
        key         = format("%s/%s", org.name, policy.name)
        org_name    = org.name
        name        = policy.name
        description = try(policy.description, local.defaults.compute.intersight.organizations.policies.qualification.description, "")
        tags        = try(policy.tags, [])
        # Intersight rejects creation/update of a Qualification Policy that has no
        # GpuQualifier at all (400 InvalidRequest, messageId
        # malibu_qualification_policy_not_allowed_with_out_gpu_qualifier) - the GUI
        # always includes one by default. Since GPU qualification isn't a configurable
        # qualifier_type in this module (out of scope), append a wildcard one
        # (GpuEvaluationType = Unspecified means "ignore GPU for matching") so pools
        # aren't silently narrowed to exclude GPU-equipped servers.
        qualifiers = concat([
          for q in try(policy.qualifiers, []) : {
            object_type = local.qualifier_object_types[q.qualifier_type]
            additional_properties = jsonencode(merge(
              try(q.asset_tags, null) != null ? { AssetTags = q.asset_tags } : {},
              try(q.pids, null) != null ? { Pids = q.pids } : {},
              try(q.user_labels, null) != null ? { UserLabels = q.user_labels } : {},
              try(q.chassis_pids, null) != null ? { ChassisPids = q.chassis_pids } : {},
              try(q.slot_ids, null) != null ? { SlotIds = q.slot_ids } : {},
              length(try(q.rack_id_range, [])) > 0 ? {
                RackIdRange = [
                  for r in q.rack_id_range : {
                    ClassId       = "resource.RackIdRangeFilter"
                    ObjectType    = "resource.RackIdRangeFilter"
                    ConditionType = "RANGE"
                    MinValue      = try(r.min, 0)
                    MaxValue      = try(r.max, 0)
                  }
                ]
              } : {},
              length(try(q.chassis_and_slot_id_range, [])) > 0 ? {
                ChassisAndSlotIdRange = [
                  for c in q.chassis_and_slot_id_range : merge(
                    {
                      ClassId    = "resource.ChassisAndSlotQualification"
                      ObjectType = "resource.ChassisAndSlotQualification"
                    },
                    try(c.chassis_id_range, null) != null ? {
                      ChassisIdRange = {
                        ClassId       = "resource.ChassisIdRangeFilter"
                        ObjectType    = "resource.ChassisIdRangeFilter"
                        ConditionType = "RANGE"
                        MinValue      = try(c.chassis_id_range.min, 0)
                        MaxValue      = try(c.chassis_id_range.max, 0)
                      }
                    } : {},
                    length(try(c.slot_id_ranges, [])) > 0 ? {
                      SlotIdRanges = [
                        for s in c.slot_id_ranges : {
                          ClassId       = "resource.SlotIdRangeFilter"
                          ObjectType    = "resource.SlotIdRangeFilter"
                          ConditionType = "RANGE"
                          MinValue      = try(s.min, 0)
                          MaxValue      = try(s.max, 0)
                        }
                      ]
                    } : {}
                  )
                ]
              } : {}
            ))
          }
          ], [{
            object_type = "resource.GpuQualifier"
            additional_properties = jsonencode({
              GpuEvaluationType = "Unspecified"
            })
        }])
      }] : []
    ]
  ])
}

resource "intersight_resourcepool_qualification_policy" "qualification_policy" {
  for_each = { for p in local.qualification_policies : p.key => p if var.manage_intersight_policies }

  description = each.value.description
  name        = each.value.name

  dynamic "qualifiers" {
    for_each = each.value.qualifiers
    content {
      object_type           = qualifiers.value.object_type
      additional_properties = qualifiers.value.additional_properties
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
