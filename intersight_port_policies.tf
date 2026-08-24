locals {
  port_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.port, []) :
      try(policy.managed, true) ? [{
        key          = format("%s/%s", org.name, policy.name)
        org_name     = org.name
        name         = policy.name
        description  = try(policy.description, local.defaults.compute.intersight.organizations.policies.port.description, "")
        device_model = try(policy.device_model, local.defaults.compute.intersight.organizations.policies.port.device_model)
        tags         = try(policy.tags, [])

        port_modes                    = try(policy.port_modes, [])
        port_role_servers             = try(policy.port_role_servers, [])
        port_role_ethernet_uplinks    = try(policy.port_role_ethernet_uplinks, [])
        port_channel_ethernet_uplinks = try(policy.port_channel_ethernet_uplinks, [])
        port_role_fc_uplinks          = try(policy.port_role_fc_uplinks, [])
        port_channel_fc_uplinks       = try(policy.port_channel_fc_uplinks, [])
        port_role_fcoe_uplinks        = try(policy.port_role_fcoe_uplinks, [])
        port_channel_fcoe_uplinks     = try(policy.port_channel_fcoe_uplinks, [])
        port_role_appliances          = try(policy.port_role_appliances, [])
        port_channel_appliances       = try(policy.port_channel_appliances, [])
        port_role_fc_storage          = try(policy.port_role_fc_storage, [])
      }] : []
    ]
  ])

  port_modes = flatten([
    for policy in local.port_policies : [
      for mode in policy.port_modes : {
        key         = format("%s/%d/%d-%d", policy.key, try(mode.slot_id, 1), mode.from, mode.to)
        policy_key  = policy.key
        custom_mode = mode.custom_mode
        from        = mode.from
        to          = mode.to
        slot_id     = try(mode.slot_id, 1)
      }
    ]
  ])

  port_role_servers = flatten([
    for policy in local.port_policies : flatten([
      for role in policy.port_role_servers : flatten([
        for block in role.ports : [
          for phys_port in range(block.from, block.to + 1) : [
            for leg in(try(block.from_sub_port, null) != null
              ? range(block.from_sub_port, block.to_sub_port + 1)
              : [0]) : {
              key                       = format("%s/%d/%d/%d", policy.key, try(block.slot_id, 1), leg, phys_port)
              policy_key                = policy.key
              slot_id                   = try(block.slot_id, 1)
              port_id                   = leg == 0 ? phys_port : leg
              aggregate_port_id         = leg == 0 ? 0 : phys_port
              fec                       = try(role.fec, "Auto")
              preferred_device_type     = try(role.preferred_device_type, "Auto")
              auto_negotiation_disabled = try(role.auto_negotiation_disabled, false)
              user_label                = try(role.user_label, "")
              port_mode_key = try([
                for pm in local.port_modes : pm.key
                if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
              ][0], null)
            }
          ]
        ]
      ])
    ])
  ])

  port_role_ethernet_uplinks = flatten([
    for policy in local.port_policies : flatten([
      for role in policy.port_role_ethernet_uplinks : flatten([
        for block in role.ports : [
          for phys_port in range(block.from, block.to + 1) : [
            for leg in(try(block.from_sub_port, null) != null
              ? range(block.from_sub_port, block.to_sub_port + 1)
              : [0]) : {
              key                          = format("%s/%d/%d/%d", policy.key, try(block.slot_id, 1), leg, phys_port)
              policy_key                   = policy.key
              org_name                     = policy.org_name
              slot_id                      = try(block.slot_id, 1)
              port_id                      = leg == 0 ? phys_port : leg
              aggregate_port_id            = leg == 0 ? 0 : phys_port
              admin_speed                  = try(role.admin_speed, "Auto")
              fec                          = try(role.fec, "Auto")
              eth_network_group_policy_key = try(role.ethernet_network_group_policy, null) != null ? format("%s/%s", policy.org_name, role.ethernet_network_group_policy) : null
              flow_control_policy_key      = try(role.flow_control_policy, null) != null ? format("%s/%s", policy.org_name, role.flow_control_policy) : null
              link_control_policy_key      = try(role.link_control_policy, null) != null ? format("%s/%s", policy.org_name, role.link_control_policy) : null
              mac_sec_policy_key           = try(role.mac_sec_policy, null) != null ? format("%s/%s", policy.org_name, role.mac_sec_policy) : null
              user_label                   = try(role.user_label, "")
              port_mode_key = try([
                for pm in local.port_modes : pm.key
                if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
              ][0], null)
            }
          ]
        ]
      ])
    ])
  ])

  port_channel_ethernet_uplinks = flatten([
    for policy in local.port_policies : [
      for channel in policy.port_channel_ethernet_uplinks : {
        key                          = format("%s/%d", policy.key, channel.pc_id)
        policy_key                   = policy.key
        org_name                     = policy.org_name
        pc_id                        = channel.pc_id
        admin_speed                  = try(channel.admin_speed, "Auto")
        fec                          = try(channel.fec, "Auto")
        eth_network_group_policy_key = try(channel.ethernet_network_group_policy, null) != null ? format("%s/%s", policy.org_name, channel.ethernet_network_group_policy) : null
        flow_control_policy_key      = try(channel.flow_control_policy, null) != null ? format("%s/%s", policy.org_name, channel.flow_control_policy) : null
        link_aggregation_policy_key  = try(channel.link_aggregation_policy, null) != null ? format("%s/%s", policy.org_name, channel.link_aggregation_policy) : null
        link_control_policy_key      = try(channel.link_control_policy, null) != null ? format("%s/%s", policy.org_name, channel.link_control_policy) : null
        mac_sec_policy_key           = try(channel.mac_sec_policy, null) != null ? format("%s/%s", policy.org_name, channel.mac_sec_policy) : null
        interfaces = flatten([
          for block in channel.ports : [
            for phys_port in range(block.from, block.to + 1) : [
              for leg in(try(block.from_sub_port, null) != null
                ? range(block.from_sub_port, block.to_sub_port + 1)
                : [0]) : {
                slot_id           = try(block.slot_id, 1)
                port_id           = leg == 0 ? phys_port : leg
                aggregate_port_id = leg == 0 ? 0 : phys_port
              }
            ]
          ]
        ])
        port_mode_keys = distinct(flatten([
          for block in channel.ports : [
            for phys_port in range(block.from, block.to + 1) : [
              for pm in local.port_modes : pm.key
              if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
            ]
          ]
        ]))
        user_label = try(channel.user_label, "")
      }
    ]
  ])

  port_role_fc_uplinks = flatten([
    for policy in local.port_policies : flatten([
      for role in policy.port_role_fc_uplinks : flatten([
        for block in role.ports : [
          for phys_port in range(block.from, block.to + 1) : [
            for leg in(try(block.from_sub_port, null) != null
              ? range(block.from_sub_port, block.to_sub_port + 1)
              : [0]) : {
              key               = format("%s/%d/%d/%d", policy.key, try(block.slot_id, 1), leg, phys_port)
              policy_key        = policy.key
              slot_id           = try(block.slot_id, 1)
              port_id           = leg == 0 ? phys_port : leg
              aggregate_port_id = leg == 0 ? 0 : phys_port
              admin_speed       = try(role.admin_speed, "32Gbps")
              fill_pattern      = try(role.fill_pattern, "Idle")
              vsan_id           = role.vsan_id
              user_label        = try(role.user_label, "")
              port_mode_key = try([
                for pm in local.port_modes : pm.key
                if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
              ][0], null)
            }
          ]
        ]
      ])
    ])
  ])

  port_channel_fc_uplinks = flatten([
    for policy in local.port_policies : [
      for channel in policy.port_channel_fc_uplinks : {
        key          = format("%s/%d", policy.key, channel.pc_id)
        policy_key   = policy.key
        pc_id        = channel.pc_id
        admin_speed  = try(channel.admin_speed, "32Gbps")
        fill_pattern = try(channel.fill_pattern, "Idle")
        vsan_id      = channel.vsan_id
        interfaces = flatten([
          for block in channel.ports : [
            for phys_port in range(block.from, block.to + 1) : [
              for leg in(try(block.from_sub_port, null) != null
                ? range(block.from_sub_port, block.to_sub_port + 1)
                : [0]) : {
                slot_id           = try(block.slot_id, 1)
                port_id           = leg == 0 ? phys_port : leg
                aggregate_port_id = leg == 0 ? 0 : phys_port
              }
            ]
          ]
        ])
        port_mode_keys = distinct(flatten([
          for block in channel.ports : [
            for phys_port in range(block.from, block.to + 1) : [
              for pm in local.port_modes : pm.key
              if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
            ]
          ]
        ]))
        user_label = try(channel.user_label, "")
      }
    ]
  ])

  port_role_fcoe_uplinks = flatten([
    for policy in local.port_policies : flatten([
      for role in policy.port_role_fcoe_uplinks : flatten([
        for block in role.ports : [
          for phys_port in range(block.from, block.to + 1) : [
            for leg in(try(block.from_sub_port, null) != null
              ? range(block.from_sub_port, block.to_sub_port + 1)
              : [0]) : {
              key                     = format("%s/%d/%d/%d", policy.key, try(block.slot_id, 1), leg, phys_port)
              policy_key              = policy.key
              slot_id                 = try(block.slot_id, 1)
              port_id                 = leg == 0 ? phys_port : leg
              aggregate_port_id       = leg == 0 ? 0 : phys_port
              admin_speed             = try(role.admin_speed, "Auto")
              fec                     = try(role.fec, "Auto")
              link_control_policy_key = try(role.link_control_policy, null) != null ? format("%s/%s", policy.org_name, role.link_control_policy) : null
              user_label              = try(role.user_label, "")
              port_mode_key = try([
                for pm in local.port_modes : pm.key
                if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
              ][0], null)
            }
          ]
        ]
      ])
    ])
  ])

  port_channel_fcoe_uplinks = flatten([
    for policy in local.port_policies : [
      for channel in policy.port_channel_fcoe_uplinks : {
        key                         = format("%s/%d", policy.key, channel.pc_id)
        policy_key                  = policy.key
        pc_id                       = channel.pc_id
        admin_speed                 = try(channel.admin_speed, "Auto")
        fec                         = try(channel.fec, "Auto")
        link_aggregation_policy_key = try(channel.link_aggregation_policy, null) != null ? format("%s/%s", policy.org_name, channel.link_aggregation_policy) : null
        link_control_policy_key     = try(channel.link_control_policy, null) != null ? format("%s/%s", policy.org_name, channel.link_control_policy) : null
        interfaces = flatten([
          for block in channel.ports : [
            for phys_port in range(block.from, block.to + 1) : [
              for leg in(try(block.from_sub_port, null) != null
                ? range(block.from_sub_port, block.to_sub_port + 1)
                : [0]) : {
                slot_id           = try(block.slot_id, 1)
                port_id           = leg == 0 ? phys_port : leg
                aggregate_port_id = leg == 0 ? 0 : phys_port
              }
            ]
          ]
        ])
        port_mode_keys = distinct(flatten([
          for block in channel.ports : [
            for phys_port in range(block.from, block.to + 1) : [
              for pm in local.port_modes : pm.key
              if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
            ]
          ]
        ]))
        user_label = try(channel.user_label, "")
      }
    ]
  ])

  port_role_appliances = flatten([
    for policy in local.port_policies : flatten([
      for role in policy.port_role_appliances : flatten([
        for block in role.ports : [
          for phys_port in range(block.from, block.to + 1) : [
            for leg in(try(block.from_sub_port, null) != null
              ? range(block.from_sub_port, block.to_sub_port + 1)
              : [0]) : {
              key                            = format("%s/%d/%d/%d", policy.key, try(block.slot_id, 1), leg, phys_port)
              policy_key                     = policy.key
              org_name                       = policy.org_name
              slot_id                        = try(block.slot_id, 1)
              port_id                        = leg == 0 ? phys_port : leg
              aggregate_port_id              = leg == 0 ? 0 : phys_port
              admin_speed                    = try(role.admin_speed, "Auto")
              fec                            = try(role.fec, "Auto")
              mode                           = try(role.mode, "trunk")
              priority                       = try(role.priority, "Best Effort")
              eth_network_control_policy_key = try(role.ethernet_network_control_policy, null) != null ? format("%s/%s", policy.org_name, role.ethernet_network_control_policy) : null
              eth_network_group_policy_key   = try(role.ethernet_network_group_policy, null) != null ? format("%s/%s", policy.org_name, role.ethernet_network_group_policy) : null
              flow_control_policy_key        = try(role.flow_control_policy, null) != null ? format("%s/%s", policy.org_name, role.flow_control_policy) : null
              link_control_policy_key        = try(role.link_control_policy, null) != null ? format("%s/%s", policy.org_name, role.link_control_policy) : null
              user_label                     = try(role.user_label, "")
              port_mode_key = try([
                for pm in local.port_modes : pm.key
                if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
              ][0], null)
            }
          ]
        ]
      ])
    ])
  ])

  port_channel_appliances = flatten([
    for policy in local.port_policies : [
      for channel in policy.port_channel_appliances : {
        key                            = format("%s/%d", policy.key, channel.pc_id)
        policy_key                     = policy.key
        org_name                       = policy.org_name
        pc_id                          = channel.pc_id
        admin_speed                    = try(channel.admin_speed, "Auto")
        fec                            = try(channel.fec, "Auto")
        mode                           = try(channel.mode, "trunk")
        priority                       = try(channel.priority, "Best Effort")
        eth_network_control_policy_key = try(channel.ethernet_network_control_policy, null) != null ? format("%s/%s", policy.org_name, channel.ethernet_network_control_policy) : null
        eth_network_group_policy_key   = try(channel.ethernet_network_group_policy, null) != null ? format("%s/%s", policy.org_name, channel.ethernet_network_group_policy) : null
        link_aggregation_policy_key    = try(channel.link_aggregation_policy, null) != null ? format("%s/%s", policy.org_name, channel.link_aggregation_policy) : null
        interfaces = flatten([
          for block in channel.ports : [
            for phys_port in range(block.from, block.to + 1) : [
              for leg in(try(block.from_sub_port, null) != null
                ? range(block.from_sub_port, block.to_sub_port + 1)
                : [0]) : {
                slot_id           = try(block.slot_id, 1)
                port_id           = leg == 0 ? phys_port : leg
                aggregate_port_id = leg == 0 ? 0 : phys_port
              }
            ]
          ]
        ])
        port_mode_keys = distinct(flatten([
          for block in channel.ports : [
            for phys_port in range(block.from, block.to + 1) : [
              for pm in local.port_modes : pm.key
              if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
            ]
          ]
        ]))
        user_label = try(channel.user_label, "")
      }
    ]
  ])

  port_role_fc_storage = flatten([
    for policy in local.port_policies : flatten([
      for role in policy.port_role_fc_storage : flatten([
        for block in role.ports : [
          for phys_port in range(block.from, block.to + 1) : [
            for leg in(try(block.from_sub_port, null) != null
              ? range(block.from_sub_port, block.to_sub_port + 1)
              : [0]) : {
              key               = format("%s/%d/%d/%d", policy.key, try(block.slot_id, 1), leg, phys_port)
              policy_key        = policy.key
              slot_id           = try(block.slot_id, 1)
              port_id           = leg == 0 ? phys_port : leg
              aggregate_port_id = leg == 0 ? 0 : phys_port
              admin_speed       = try(role.admin_speed, "Auto")
              vsan_id           = role.vsan_id
              user_label        = try(role.user_label, "")
              port_mode_key = try([
                for pm in local.port_modes : pm.key
                if pm.policy_key == policy.key && pm.slot_id == try(block.slot_id, 1) && phys_port >= pm.from && phys_port <= pm.to
              ][0], null)
            }
          ]
        ]
      ])
    ])
  ])
}

resource "intersight_fabric_port_policy" "port_policy" {
  for_each = { for p in local.port_policies : p.key => p if var.manage_intersight_policies }

  name         = each.value.name
  description  = each.value.description
  device_model = each.value.device_model

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

resource "intersight_fabric_port_mode" "port_mode" {
  for_each = { for m in local.port_modes : m.key => m if var.manage_intersight_policies }

  custom_mode   = each.value.custom_mode
  port_id_end   = each.value.to
  port_id_start = each.value.from
  slot_id       = each.value.slot_id

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  depends_on = [intersight_fabric_port_policy.port_policy]
}

resource "intersight_fabric_server_role" "server_role" {
  for_each = { for r in local.port_role_servers : r.key => r if var.manage_intersight_policies }

  slot_id                   = each.value.slot_id
  port_id                   = each.value.port_id
  aggregate_port_id         = each.value.aggregate_port_id
  fec                       = each.value.fec
  preferred_device_type     = each.value.preferred_device_type
  auto_negotiation_disabled = each.value.auto_negotiation_disabled
  user_label                = each.value.user_label

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = each.value.port_mode_key == null || can(intersight_fabric_port_mode.port_mode[each.value.port_mode_key].moid)
      error_message = "Required port mode was not created for this port."
    }
  }
}

resource "intersight_fabric_uplink_role" "uplink_role" {
  for_each = { for r in local.port_role_ethernet_uplinks : r.key => r if var.manage_intersight_policies }

  slot_id           = each.value.slot_id
  port_id           = each.value.port_id
  aggregate_port_id = each.value.aggregate_port_id
  admin_speed       = each.value.admin_speed
  fec               = each.value.fec
  user_label        = each.value.user_label

  dynamic "eth_network_group_policy" {
    for_each = each.value.eth_network_group_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkGroupPolicy"
      moid        = intersight_fabric_eth_network_group_policy.ethernet_network_group_policy[each.value.eth_network_group_policy_key].moid
    }
  }

  dynamic "flow_control_policy" {
    for_each = each.value.flow_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.FlowControlPolicy"
      moid        = intersight_fabric_flow_control_policy.flow_control_policy[each.value.flow_control_policy_key].moid
    }
  }

  dynamic "link_control_policy" {
    for_each = each.value.link_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.LinkControlPolicy"
      moid        = intersight_fabric_link_control_policy.link_control_policy[each.value.link_control_policy_key].moid
    }
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = each.value.port_mode_key == null || can(intersight_fabric_port_mode.port_mode[each.value.port_mode_key].moid)
      error_message = "Required port mode was not created for this port."
    }
  }
}

resource "intersight_fabric_uplink_pc_role" "uplink_pc_role" {
  for_each = { for c in local.port_channel_ethernet_uplinks : c.key => c if var.manage_intersight_policies }

  pc_id       = each.value.pc_id
  admin_speed = each.value.admin_speed
  fec         = each.value.fec
  user_label  = each.value.user_label

  dynamic "ports" {
    for_each = each.value.interfaces
    content {
      object_type       = "fabric.PortIdentifier"
      slot_id           = ports.value.slot_id
      port_id           = ports.value.port_id
      aggregate_port_id = try(ports.value.aggregate_port_id, 0)
    }
  }

  dynamic "eth_network_group_policy" {
    for_each = each.value.eth_network_group_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkGroupPolicy"
      moid        = intersight_fabric_eth_network_group_policy.ethernet_network_group_policy[each.value.eth_network_group_policy_key].moid
    }
  }

  dynamic "flow_control_policy" {
    for_each = each.value.flow_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.FlowControlPolicy"
      moid        = intersight_fabric_flow_control_policy.flow_control_policy[each.value.flow_control_policy_key].moid
    }
  }

  dynamic "link_aggregation_policy" {
    for_each = each.value.link_aggregation_policy_key != null ? [1] : []
    content {
      object_type = "fabric.LinkAggregationPolicy"
      moid        = intersight_fabric_link_aggregation_policy.link_aggregation_policy[each.value.link_aggregation_policy_key].moid
    }
  }

  dynamic "link_control_policy" {
    for_each = each.value.link_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.LinkControlPolicy"
      moid        = intersight_fabric_link_control_policy.link_control_policy[each.value.link_control_policy_key].moid
    }
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = alltrue([for k in each.value.port_mode_keys : can(intersight_fabric_port_mode.port_mode[k].moid)])
      error_message = "Required port mode(s) were not created for this port channel."
    }
  }
}

resource "intersight_fabric_fc_uplink_role" "fc_uplink_role" {
  for_each = { for r in local.port_role_fc_uplinks : r.key => r if var.manage_intersight_policies }

  slot_id           = each.value.slot_id
  port_id           = each.value.port_id
  aggregate_port_id = each.value.aggregate_port_id
  admin_speed       = each.value.admin_speed
  fill_pattern      = each.value.fill_pattern
  vsan_id           = each.value.vsan_id
  user_label        = each.value.user_label

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = each.value.port_mode_key == null || can(intersight_fabric_port_mode.port_mode[each.value.port_mode_key].moid)
      error_message = "Required port mode was not created for this port."
    }
  }
}

resource "intersight_fabric_fc_uplink_pc_role" "fc_uplink_pc_role" {
  for_each = { for c in local.port_channel_fc_uplinks : c.key => c if var.manage_intersight_policies }

  pc_id        = each.value.pc_id
  admin_speed  = each.value.admin_speed
  fill_pattern = each.value.fill_pattern
  vsan_id      = each.value.vsan_id
  user_label   = each.value.user_label

  dynamic "ports" {
    for_each = each.value.interfaces
    content {
      object_type       = "fabric.PortIdentifier"
      slot_id           = ports.value.slot_id
      port_id           = ports.value.port_id
      aggregate_port_id = try(ports.value.aggregate_port_id, 0)
    }
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = alltrue([for k in each.value.port_mode_keys : can(intersight_fabric_port_mode.port_mode[k].moid)])
      error_message = "Required port mode(s) were not created for this port channel."
    }
  }
}

resource "intersight_fabric_fcoe_uplink_role" "fcoe_uplink_role" {
  for_each = { for r in local.port_role_fcoe_uplinks : r.key => r if var.manage_intersight_policies }

  slot_id           = each.value.slot_id
  port_id           = each.value.port_id
  aggregate_port_id = each.value.aggregate_port_id
  admin_speed       = each.value.admin_speed
  fec               = each.value.fec
  user_label        = each.value.user_label

  dynamic "link_control_policy" {
    for_each = each.value.link_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.LinkControlPolicy"
      moid        = intersight_fabric_link_control_policy.link_control_policy[each.value.link_control_policy_key].moid
    }
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = each.value.port_mode_key == null || can(intersight_fabric_port_mode.port_mode[each.value.port_mode_key].moid)
      error_message = "Required port mode was not created for this port."
    }
  }
}

resource "intersight_fabric_fcoe_uplink_pc_role" "fcoe_uplink_pc_role" {
  for_each = { for c in local.port_channel_fcoe_uplinks : c.key => c if var.manage_intersight_policies }

  pc_id       = each.value.pc_id
  admin_speed = each.value.admin_speed
  fec         = each.value.fec
  user_label  = each.value.user_label

  dynamic "ports" {
    for_each = each.value.interfaces
    content {
      object_type       = "fabric.PortIdentifier"
      slot_id           = ports.value.slot_id
      port_id           = ports.value.port_id
      aggregate_port_id = try(ports.value.aggregate_port_id, 0)
    }
  }

  dynamic "link_aggregation_policy" {
    for_each = each.value.link_aggregation_policy_key != null ? [1] : []
    content {
      object_type = "fabric.LinkAggregationPolicy"
      moid        = intersight_fabric_link_aggregation_policy.link_aggregation_policy[each.value.link_aggregation_policy_key].moid
    }
  }

  dynamic "link_control_policy" {
    for_each = each.value.link_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.LinkControlPolicy"
      moid        = intersight_fabric_link_control_policy.link_control_policy[each.value.link_control_policy_key].moid
    }
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = alltrue([for k in each.value.port_mode_keys : can(intersight_fabric_port_mode.port_mode[k].moid)])
      error_message = "Required port mode(s) were not created for this port channel."
    }
  }
}

resource "intersight_fabric_appliance_role" "appliance_role" {
  for_each = { for r in local.port_role_appliances : r.key => r if var.manage_intersight_policies }

  slot_id           = each.value.slot_id
  port_id           = each.value.port_id
  aggregate_port_id = each.value.aggregate_port_id
  admin_speed       = each.value.admin_speed
  fec               = each.value.fec
  mode              = each.value.mode
  priority          = each.value.priority
  user_label        = each.value.user_label

  dynamic "eth_network_control_policy" {
    for_each = each.value.eth_network_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkControlPolicy"
      moid        = intersight_fabric_eth_network_control_policy.ethernet_network_control_policy[each.value.eth_network_control_policy_key].moid
    }
  }

  dynamic "eth_network_group_policy" {
    for_each = each.value.eth_network_group_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkGroupPolicy"
      moid        = intersight_fabric_eth_network_group_policy.ethernet_network_group_policy[each.value.eth_network_group_policy_key].moid
    }
  }

  dynamic "flow_control_policy" {
    for_each = each.value.flow_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.FlowControlPolicy"
      moid        = intersight_fabric_flow_control_policy.flow_control_policy[each.value.flow_control_policy_key].moid
    }
  }

  dynamic "link_control_policy" {
    for_each = each.value.link_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.LinkControlPolicy"
      moid        = intersight_fabric_link_control_policy.link_control_policy[each.value.link_control_policy_key].moid
    }
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = each.value.port_mode_key == null || can(intersight_fabric_port_mode.port_mode[each.value.port_mode_key].moid)
      error_message = "Required port mode was not created for this port."
    }
  }
}

resource "intersight_fabric_appliance_pc_role" "appliance_pc_role" {
  for_each = { for c in local.port_channel_appliances : c.key => c if var.manage_intersight_policies }

  pc_id       = each.value.pc_id
  admin_speed = each.value.admin_speed
  fec         = each.value.fec
  mode        = each.value.mode
  priority    = each.value.priority
  user_label  = each.value.user_label

  dynamic "ports" {
    for_each = each.value.interfaces
    content {
      object_type       = "fabric.PortIdentifier"
      slot_id           = ports.value.slot_id
      port_id           = ports.value.port_id
      aggregate_port_id = try(ports.value.aggregate_port_id, 0)
    }
  }

  dynamic "eth_network_control_policy" {
    for_each = each.value.eth_network_control_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkControlPolicy"
      moid        = intersight_fabric_eth_network_control_policy.ethernet_network_control_policy[each.value.eth_network_control_policy_key].moid
    }
  }

  dynamic "eth_network_group_policy" {
    for_each = each.value.eth_network_group_policy_key != null ? [1] : []
    content {
      object_type = "fabric.EthNetworkGroupPolicy"
      moid        = intersight_fabric_eth_network_group_policy.ethernet_network_group_policy[each.value.eth_network_group_policy_key].moid
    }
  }

  dynamic "link_aggregation_policy" {
    for_each = each.value.link_aggregation_policy_key != null ? [1] : []
    content {
      object_type = "fabric.LinkAggregationPolicy"
      moid        = intersight_fabric_link_aggregation_policy.link_aggregation_policy[each.value.link_aggregation_policy_key].moid
    }
  }

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = alltrue([for k in each.value.port_mode_keys : can(intersight_fabric_port_mode.port_mode[k].moid)])
      error_message = "Required port mode(s) were not created for this port channel."
    }
  }
}

resource "intersight_fabric_fc_storage_role" "fc_storage_role" {
  for_each = { for r in local.port_role_fc_storage : r.key => r if var.manage_intersight_policies }

  slot_id           = each.value.slot_id
  port_id           = each.value.port_id
  aggregate_port_id = each.value.aggregate_port_id
  admin_speed       = each.value.admin_speed
  vsan_id           = each.value.vsan_id
  user_label        = each.value.user_label

  port_policy {
    object_type = "fabric.PortPolicy"
    moid        = intersight_fabric_port_policy.port_policy[each.value.policy_key].moid
  }

  lifecycle {
    precondition {
      condition     = each.value.port_mode_key == null || can(intersight_fabric_port_mode.port_mode[each.value.port_mode_key].moid)
      error_message = "Required port mode was not created for this port."
    }
  }
}
