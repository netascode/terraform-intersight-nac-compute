locals {
  lan_pin_groups = flatten([
    for policy in local.port_policies : [
      for pg in policy.lan_pin_groups : {
        key            = format("%s/%s", policy.key, pg.name)
        policy_key     = policy.key
        name           = pg.name
        interface_type = pg.interface_type
        slot_id        = try(pg.slot_id, 1)
        port_id        = try(pg.port_id, null)
        pc_id          = try(pg.port_channel_id, null)
      }
    ]
  ])

  san_pin_groups = flatten([
    for policy in local.port_policies : [
      for pg in policy.san_pin_groups : {
        key            = format("%s/%s", policy.key, pg.name)
        policy_key     = policy.key
        name           = pg.name
        interface_type = pg.interface_type
        slot_id        = try(pg.slot_id, 1)
        port_id        = try(pg.port_id, null)
        pc_id          = try(pg.port_channel_id, null)
      }
    ]
  ])
}

resource "intersight_fabric_lan_pin_group" "lan_pin_group" {
  for_each = { for g in local.lan_pin_groups : g.key => g if var.manage_intersight_policies }

  name = each.value.name

  pin_target_interface_role {
    object_type = each.value.interface_type == "port" ? "fabric.UplinkRole" : "fabric.UplinkPcRole"
    moid = each.value.interface_type == "port" ? (
      intersight_fabric_uplink_role.uplink_role[format("%s/%d/%d/%d", each.value.policy_key, each.value.slot_id, 0, each.value.port_id)].moid
      ) : (
      intersight_fabric_uplink_pc_role.uplink_pc_role[format("%s/%d", each.value.policy_key, each.value.pc_id)].moid
    )
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }
}

resource "intersight_fabric_san_pin_group" "san_pin_group" {
  for_each = { for g in local.san_pin_groups : g.key => g if var.manage_intersight_policies }

  name = each.value.name

  pin_target_interface_role {
    object_type = each.value.interface_type == "port" ? "fabric.FcUplinkRole" : "fabric.FcUplinkPcRole"
    moid = each.value.interface_type == "port" ? (
      intersight_fabric_fc_uplink_role.fc_uplink_role[format("%s/%d/%d/%d", each.value.policy_key, each.value.slot_id, 0, each.value.port_id)].moid
      ) : (
      intersight_fabric_fc_uplink_pc_role.fc_uplink_pc_role[format("%s/%d", each.value.policy_key, each.value.pc_id)].moid
    )
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }
}
