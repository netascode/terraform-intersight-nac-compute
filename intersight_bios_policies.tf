locals {
  bios_policies = flatten([
    for org in local.filtered_intersight_organizations : [
      for policy in try(org.policies.bios, []) :
      try(policy.managed, true) ? [merge(
        local.defaults.compute.intersight.organizations.policies.bios,
        try(policy.bios_template, null) != null ? merge(
          try(local.defaults.compute.intersight.organizations.policies.bios_templates[replace(replace(policy.bios_template, "-tpm", ""), "-Tpm", "")], {}),
          try(local.defaults.compute.intersight.organizations.policies.bios_templates[length(regexall("-tpm$", lower(policy.bios_template))) > 0 ? "tpm" : "tpm_disabled"], {})
        ) : {},
        policy,
        {
          key      = format("%s/%s", org.name, policy.name)
          org_name = org.name
          name     = policy.name
        }
      )] : []
    ]
  ])
}

resource "intersight_bios_policy" "bios_policy" {
  for_each = { for p in local.bios_policies : p.key => p if var.manage_intersight_policies }

  description = each.value.description
  name        = each.value.name
  #+++++++++++++++++++++++++++++++
  # Advanced Section
  #+++++++++++++++++++++++++++++++
  latency_optimized_mode = each.value.latency_optimized_mode # Latency Optimized Mode configuration
  #+++++++++++++++++++++++++++++++
  # Boot Options Section
  #+++++++++++++++++++++++++++++++
  boot_option_num_retry        = each.value.boot_option_num_retry        # Number of Retries
  boot_option_re_cool_down     = each.value.boot_option_re_cool_down     # Cool Down Time (sec)
  boot_option_retry            = each.value.boot_option_retry            # Boot Option Retry
  ipv4http                     = each.value.ipv4http                     # IPv4 HTTP Support
  ipv4pxe                      = each.value.ipv4pxe                      # IPv4 PXE Support
  ipv6http                     = each.value.ipv6http                     # IPv6 HTTP Support
  ipv6pxe                      = each.value.ipv6pxe                      # IPv6 PXE Support
  network_stack                = each.value.network_stack                # Network Stack
  onboard_scu_storage_support  = each.value.onboard_scu_storage_support  # Onboard SCU Storage Support
  onboard_scu_storage_sw_stack = each.value.onboard_scu_storage_sw_stack # Onboard SCU Storage SW Stack
  pop_support                  = each.value.pop_support                  # Power ON Password
  psata                        = each.value.psata                        # P-SATA Mode
  sata_mode_select             = each.value.sata_mode_select             # SATA Mode
  vmd_enable                   = each.value.vmd_enable                   # VMD Enablement
  #+++++++++++++++++++++++++++++++
  # Intel Directed IO Section
  #+++++++++++++++++++++++++++++++
  intel_vt_for_directed_io           = each.value.intel_vt_for_directed_io           # Intel VT for Directed IO
  intel_vtd_coherency_support        = each.value.intel_vtd_coherency_support        # Intel(R) VT-d Coherency Support
  intel_vtd_interrupt_remapping      = each.value.intel_vtd_interrupt_remapping      # Intel(R) VT-d interrupt Remapping
  intel_vtd_pass_through_dma_support = each.value.intel_vtd_pass_through_dma_support # Intel(R) VT-d PassThrough DMA Support
  intel_vtdats_support               = each.value.intel_vtdats_support               # Intel VTD ATS Support
  #+++++++++++++++++++++++++++++++
  # LOM and PCIe Slots Section
  #+++++++++++++++++++++++++++++++
  acs_control_gpu1state          = each.value.acs_control_gpu1state          # ACS Control GPU 1
  acs_control_gpu2state          = each.value.acs_control_gpu2state          # ACS Control GPU 2
  acs_control_gpu3state          = each.value.acs_control_gpu3state          # ACS Control GPU 3
  acs_control_gpu4state          = each.value.acs_control_gpu4state          # ACS Control GPU 4
  acs_control_gpu5state          = each.value.acs_control_gpu5state          # ACS Control GPU 5
  acs_control_gpu6state          = each.value.acs_control_gpu6state          # ACS Control GPU 6
  acs_control_gpu7state          = each.value.acs_control_gpu7state          # ACS Control GPU 7
  acs_control_gpu8state          = each.value.acs_control_gpu8state          # ACS Control GPU 8
  acs_control_slot11state        = each.value.acs_control_slot11state        # ACS Control Slot 11
  acs_control_slot12state        = each.value.acs_control_slot12state        # ACS Control Slot 12
  acs_control_slot13state        = each.value.acs_control_slot13state        # ACS Control Slot 13
  acs_control_slot14state        = each.value.acs_control_slot14state        # ACS Control Slot 14
  cdn_support                    = each.value.cdn_support                    # CDN Support for LOM
  edpc_en                        = each.value.edpc_en                        # IIO eDPC Support
  enable_clock_spread_spec       = each.value.enable_clock_spread_spec       # External SSC Enable
  lom_port0state                 = each.value.lom_port0state                 # LOM Port 0 OptionROM
  lom_port1state                 = each.value.lom_port1state                 # LOM Port 1 OptionROM
  lom_port2state                 = each.value.lom_port2state                 # LOM Port 2 OptionROM
  lom_port3state                 = each.value.lom_port3state                 # LOM Port 3 OptionROM
  lom_ports_all_state            = each.value.lom_ports_all_state            # All Onboard LOM Ports
  pch_pcie_pll_ssc               = each.value.pch_pcie_pll_ssc               # PCIe PLL SSC Percent *
  pci_option_ro_ms               = each.value.pci_option_ro_ms               # All PCIe Slots OptionROM
  pci_rom_clp                    = each.value.pci_rom_clp                    # PCI ROM CLP
  pcie_ari_support               = each.value.pcie_ari_support               # PCI ARI Support
  pcie_pll_ssc                   = each.value.pcie_pll_ssc                   # PCI PLL SSC
  pcie_slot_mraid1link_speed     = each.value.pcie_slot_mraid1link_speed     # MRAID1 Link Speed
  pcie_slot_mraid1option_rom     = each.value.pcie_slot_mraid1option_rom     # MRAID1 OptionROM
  pcie_slot_mraid2link_speed     = each.value.pcie_slot_mraid2link_speed     # MRAID2 Link Speed
  pcie_slot_mraid2option_rom     = each.value.pcie_slot_mraid2option_rom     # MRAID2 OptionROM
  pcie_slot_mstorraid_link_speed = each.value.pcie_slot_mstorraid_link_speed # PCIe Slot MSTOR Link Speed
  pcie_slot_mstorraid_option_rom = each.value.pcie_slot_mstorraid_option_rom # PCIe Slot MSTOR RAID OptionROM
  pcie_slot_nvme1link_speed      = each.value.pcie_slot_nvme1link_speed      # NVME 1 Link Speed
  pcie_slot_nvme1option_rom      = each.value.pcie_slot_nvme1option_rom      # NVME 1 OptionROM
  pcie_slot_nvme2link_speed      = each.value.pcie_slot_nvme2link_speed      # NVME 2 Link Speed
  pcie_slot_nvme2option_rom      = each.value.pcie_slot_nvme2option_rom      # NVME 2 OptionROM
  pcie_slot_nvme3link_speed      = each.value.pcie_slot_nvme3link_speed      # NVME 3 Link Speed
  pcie_slot_nvme3option_rom      = each.value.pcie_slot_nvme3option_rom      # NVME 3 OptionROM
  pcie_slot_nvme4link_speed      = each.value.pcie_slot_nvme4link_speed      # NVME 4 Link Speed
  pcie_slot_nvme4option_rom      = each.value.pcie_slot_nvme4option_rom      # NVME 4 OptionROM
  pcie_slot_nvme5link_speed      = each.value.pcie_slot_nvme5link_speed      # NVME 5 Link Speed
  pcie_slot_nvme5option_rom      = each.value.pcie_slot_nvme5option_rom      # NVME 5 OptionROM
  pcie_slot_nvme6link_speed      = each.value.pcie_slot_nvme6link_speed      # NVME 6 Link Speed
  pcie_slot_nvme6option_rom      = each.value.pcie_slot_nvme6option_rom      # NVME 6 OptionROM
  slot10link_speed               = each.value.slot10link_speed               # PCIe Slot:10 Link Speed
  slot10state                    = each.value.slot10state                    # Slot 10 State
  slot11link_speed               = each.value.slot11link_speed               # PCIe Slot:11 Link Speed
  slot11state                    = each.value.slot11state                    # Slot 11 State
  slot12link_speed               = each.value.slot12link_speed               # PCIe Slot:12 Link Speed
  slot12state                    = each.value.slot12state                    # Slot 12 State
  slot13state                    = each.value.slot13state                    # Slot 13 State
  slot14state                    = each.value.slot14state                    # Slot 14 State
  slot1link_speed                = each.value.slot1link_speed                # PCIe Slot: 1 Link Speed
  slot1state                     = each.value.slot1state                     # Slot 1 State
  slot2link_speed                = each.value.slot2link_speed                # PCIe Slot: 2 Link Speed
  slot2state                     = each.value.slot2state                     # Slot 2 State
  slot3link_speed                = each.value.slot3link_speed                # PCIe Slot: 3 Link Speed
  slot3state                     = each.value.slot3state                     # Slot 3 State
  slot4link_speed                = each.value.slot4link_speed                # PCIe Slot: 4 Link Speed
  slot4state                     = each.value.slot4state                     # Slot 4 State
  slot5link_speed                = each.value.slot5link_speed                # PCIe Slot: 5 Link Speed
  slot5state                     = each.value.slot5state                     # Slot 5 State
  slot6link_speed                = each.value.slot6link_speed                # PCIe Slot: 6 Link Speed
  slot6state                     = each.value.slot6state                     # Slot 6 State
  slot7link_speed                = each.value.slot7link_speed                # PCIe Slot: 7 Link Speed
  slot7state                     = each.value.slot7state                     # Slot 7 State
  slot8link_speed                = each.value.slot8link_speed                # PCIe Slot: 8 Link Speed
  slot8state                     = each.value.slot8state                     # Slot 8 State
  slot9link_speed                = each.value.slot9link_speed                # PCIe Slot: 9 Link Speed
  slot9state                     = each.value.slot9state                     # Slot 9 State
  slot_flom_link_speed           = each.value.slot_flom_link_speed           # PCIe Slot:FLOM Link Speed
  slot_front_nvme1link_speed     = each.value.slot_front_nvme1link_speed     # Front NVME 1 Link Speed
  slot_front_nvme1option_rom     = each.value.slot_front_nvme1option_rom     # Front NVME 1 OptionROM
  slot_front_nvme2link_speed     = each.value.slot_front_nvme2link_speed     # PCIe Slot:Front NVME 2 Link Speed
  slot_front_nvme2option_rom     = each.value.slot_front_nvme2option_rom     # Front NVME 2 OptionROM
  slot_front_nvme3link_speed     = each.value.slot_front_nvme3link_speed     # Front NVME 3 Link Speed
  slot_front_nvme3option_rom     = each.value.slot_front_nvme3option_rom     # Front NVME 3 OptionROM
  slot_front_nvme4link_speed     = each.value.slot_front_nvme4link_speed     # Front NVME 4 Link Speed
  slot_front_nvme4option_rom     = each.value.slot_front_nvme4option_rom     # Front NVME 4 OptionROM
  slot_front_nvme5link_speed     = each.value.slot_front_nvme5link_speed     # Front NVME 5 Link Speed
  slot_front_nvme5option_rom     = each.value.slot_front_nvme5option_rom     # Front NVME 5 OptionROM
  slot_front_nvme6link_speed     = each.value.slot_front_nvme6link_speed     # Front NVME 6 Link Speed
  slot_front_nvme6option_rom     = each.value.slot_front_nvme6option_rom     # Front NVME 6 OptionROM
  slot_front_nvme7link_speed     = each.value.slot_front_nvme7link_speed     # Front NVME 7 Link Speed
  slot_front_nvme7option_rom     = each.value.slot_front_nvme7option_rom     # Front NVME 7 OptionROM
  slot_front_nvme8link_speed     = each.value.slot_front_nvme8link_speed     # Front NVME 8 Link Speed
  slot_front_nvme8option_rom     = each.value.slot_front_nvme8option_rom     # Front NVME 8 OptionROM
  slot_front_nvme9link_speed     = each.value.slot_front_nvme9link_speed     # Front NVME 9 Link Speed
  slot_front_nvme9option_rom     = each.value.slot_front_nvme9option_rom     # Front NVME 9 OptionROM
  slot_front_nvme10link_speed    = each.value.slot_front_nvme10link_speed    # Front NVME 10 Link Speed
  slot_front_nvme10option_rom    = each.value.slot_front_nvme10option_rom    # Front NVME 10 OptionROM
  slot_front_nvme11link_speed    = each.value.slot_front_nvme11link_speed    # Front NVME 11 Link Speed
  slot_front_nvme11option_rom    = each.value.slot_front_nvme11option_rom    # Front NVME 11 OptionROM
  slot_front_nvme12link_speed    = each.value.slot_front_nvme12link_speed    # Front NVME 12 Link Speed
  slot_front_nvme12option_rom    = each.value.slot_front_nvme12option_rom    # Front NVME 12 OptionROM
  slot_front_nvme13link_speed    = each.value.slot_front_nvme13link_speed    # Front NVME 13 Link Speed
  slot_front_nvme13option_rom    = each.value.slot_front_nvme13option_rom    # Front NVME 13 OptionROM
  slot_front_nvme14link_speed    = each.value.slot_front_nvme14link_speed    # Front NVME 14 Link Speed
  slot_front_nvme14option_rom    = each.value.slot_front_nvme14option_rom    # Front NVME 14 OptionROM
  slot_front_nvme15link_speed    = each.value.slot_front_nvme15link_speed    # Front NVME 15 Link Speed
  slot_front_nvme15option_rom    = each.value.slot_front_nvme15option_rom    # Front NVME 15 OptionROM
  slot_front_nvme16link_speed    = each.value.slot_front_nvme16link_speed    # Front NVME 16 Link Speed
  slot_front_nvme16option_rom    = each.value.slot_front_nvme16option_rom    # Front NVME 16 OptionROM
  slot_front_nvme17link_speed    = each.value.slot_front_nvme17link_speed    # Front NVME 17 Link Speed
  slot_front_nvme17option_rom    = each.value.slot_front_nvme17option_rom    # Front NVME 17 OptionROM
  slot_front_nvme18link_speed    = each.value.slot_front_nvme18link_speed    # Front NVME 18 Link Speed
  slot_front_nvme18option_rom    = each.value.slot_front_nvme18option_rom    # Front NVME 18 OptionROM
  slot_front_nvme19link_speed    = each.value.slot_front_nvme19link_speed    # Front NVME 19 Link Speed
  slot_front_nvme19option_rom    = each.value.slot_front_nvme19option_rom    # Front NVME 19 OptionROM
  slot_front_nvme20link_speed    = each.value.slot_front_nvme20link_speed    # Front NVME 20 Link Speed
  slot_front_nvme20option_rom    = each.value.slot_front_nvme20option_rom    # Front NVME 20 OptionROM
  slot_front_nvme21link_speed    = each.value.slot_front_nvme21link_speed    # Front NVME 21 Link Speed
  slot_front_nvme21option_rom    = each.value.slot_front_nvme21option_rom    # Front NVME 21 OptionROM
  slot_front_nvme22link_speed    = each.value.slot_front_nvme22link_speed    # Front NVME 22 Link Speed
  slot_front_nvme22option_rom    = each.value.slot_front_nvme22option_rom    # Front NVME 22 OptionROM
  slot_front_nvme23link_speed    = each.value.slot_front_nvme23link_speed    # Front NVME 23 Link Speed
  slot_front_nvme23option_rom    = each.value.slot_front_nvme23option_rom    # Front NVME 23 OptionROM
  slot_front_nvme24link_speed    = each.value.slot_front_nvme24link_speed    # Front NVME 24 Link Speed
  slot_front_nvme24option_rom    = each.value.slot_front_nvme24option_rom    # Front NVME 24 OptionROM
  slot_front_nvme25link_speed    = each.value.slot_front_nvme25link_speed    # Front NVME 25 Link Speed
  slot_front_nvme25option_rom    = each.value.slot_front_nvme25option_rom    # Front NVME 25 OptionROM
  slot_front_nvme26link_speed    = each.value.slot_front_nvme26link_speed    # Front NVME 26 Link Speed
  slot_front_nvme26option_rom    = each.value.slot_front_nvme26option_rom    # Front NVME 26 OptionROM
  slot_front_nvme27link_speed    = each.value.slot_front_nvme27link_speed    # Front NVME 27 Link Speed
  slot_front_nvme27option_rom    = each.value.slot_front_nvme27option_rom    # Front NVME 27 OptionROM
  slot_front_nvme28link_speed    = each.value.slot_front_nvme28link_speed    # Front NVME 28 Link Speed
  slot_front_nvme28option_rom    = each.value.slot_front_nvme28option_rom    # Front NVME 28 OptionROM
  slot_front_nvme29link_speed    = each.value.slot_front_nvme29link_speed    # Front NVME 29 Link Speed
  slot_front_nvme29option_rom    = each.value.slot_front_nvme29option_rom    # Front NVME 29 OptionROM
  slot_front_nvme30link_speed    = each.value.slot_front_nvme30link_speed    # Front NVME 30 Link Speed
  slot_front_nvme30option_rom    = each.value.slot_front_nvme30option_rom    # Front NVME 30 OptionROM
  slot_front_nvme31link_speed    = each.value.slot_front_nvme31link_speed    # Front NVME 31 Link Speed
  slot_front_nvme31option_rom    = each.value.slot_front_nvme31option_rom    # Front NVME 31 OptionROM
  slot_front_nvme32link_speed    = each.value.slot_front_nvme32link_speed    # Front NVME 32 Link Speed
  slot_front_nvme32option_rom    = each.value.slot_front_nvme32option_rom    # Front NVME 32 OptionROM
  slot_front_slot5link_speed     = each.value.slot_front_slot5link_speed     # PCIe Slot:Front1 Link Speed
  slot_front_slot6link_speed     = each.value.slot_front_slot6link_speed     # PCIe Slot:Front2 Link Speed
  slot_gpu1state                 = each.value.slot_gpu1state                 # GPU 1 OptionROM
  slot_gpu2state                 = each.value.slot_gpu2state                 # GPU 2 OptionROM
  slot_gpu3state                 = each.value.slot_gpu3state                 # GPU 3 OptionROM
  slot_gpu4state                 = each.value.slot_gpu4state                 # GPU 4 OptionROM
  slot_gpu5state                 = each.value.slot_gpu5state                 # GPU 5 OptionROM
  slot_gpu6state                 = each.value.slot_gpu6state                 # GPU 6 OptionROM
  slot_gpu7state                 = each.value.slot_gpu7state                 # GPU 7 OptionROM
  slot_gpu8state                 = each.value.slot_gpu8state                 # GPU 8 OptionROM
  slot_hba_link_speed            = each.value.slot_hba_link_speed            # PCIe Slot:HBA Link Speed
  slot_hba_state                 = each.value.slot_hba_state                 # PCIe Slot:HBA OptionROM
  slot_lom1link                  = each.value.slot_lom1link                  # PCIe LOM:1 Link
  slot_lom2link                  = each.value.slot_lom2link                  # PCIe LOM:2 Link
  slot_mezz_state                = each.value.slot_mezz_state                # Slot Mezz State
  slot_mlom_link_speed           = each.value.slot_mlom_link_speed           # PCIe Slot:MLOM Link Speed
  slot_mlom_state                = each.value.slot_mlom_state                # PCIe Slot MLOM OptionROM
  slot_mraid_link_speed          = each.value.slot_mraid_link_speed          # MRAID Link Speed
  slot_mraid_state               = each.value.slot_mraid_state               # PCIe Slot MRAID OptionROM
  slot_n10state                  = each.value.slot_n10state                  # PCIe Slot N10 OptionROM
  slot_n11state                  = each.value.slot_n11state                  # PCIe Slot N11 OptionROM
  slot_n12state                  = each.value.slot_n12state                  # PCIe Slot N12 OptionROM
  slot_n13state                  = each.value.slot_n13state                  # PCIe Slot N13 OptionROM
  slot_n14state                  = each.value.slot_n14state                  # PCIe Slot N14 OptionROM
  slot_n15state                  = each.value.slot_n15state                  # PCIe Slot N15 OptionROM
  slot_n16state                  = each.value.slot_n16state                  # PCIe Slot N16 OptionROM
  slot_n17state                  = each.value.slot_n17state                  # PCIe Slot N17 OptionROM
  slot_n18state                  = each.value.slot_n18state                  # PCIe Slot N18 OptionROM
  slot_n19state                  = each.value.slot_n19state                  # PCIe Slot N19 OptionROM
  slot_n1state                   = each.value.slot_n1state                   # PCIe Slot N1 OptionROM
  slot_n20state                  = each.value.slot_n20state                  # PCIe Slot N20 OptionROM
  slot_n21state                  = each.value.slot_n21state                  # PCIe Slot N21 OptionROM
  slot_n22state                  = each.value.slot_n22state                  # PCIe Slot N22 OptionROM
  slot_n23state                  = each.value.slot_n23state                  # PCIe Slot N23 OptionROM
  slot_n24state                  = each.value.slot_n24state                  # PCIe Slot N24 OptionROM
  slot_n2state                   = each.value.slot_n2state                   # PCIe Slot N2 OptionROM
  slot_n3state                   = each.value.slot_n3state                   # PCIe Slot N3 OptionROM
  slot_n4state                   = each.value.slot_n4state                   # PCIe Slot N4 OptionROM
  slot_n5state                   = each.value.slot_n5state                   # PCIe Slot N5 OptionROM
  slot_n6state                   = each.value.slot_n6state                   # PCIe Slot N6 OptionROM
  slot_n7state                   = each.value.slot_n7state                   # PCIe Slot N7 OptionROM
  slot_n8state                   = each.value.slot_n8state                   # PCIe Slot N8 OptionROM
  slot_n9state                   = each.value.slot_n9state                   # PCIe Slot N9 OptionROM
  slot_raid_link_speed           = each.value.slot_raid_link_speed           # RAID Link Speed
  slot_raid_state                = each.value.slot_raid_state                # PCIe Slot RAID OptionROM
  slot_rear_nvme1link_speed      = each.value.slot_rear_nvme1link_speed      # PCIe Slot:Rear NVME 1 Link Speed
  slot_rear_nvme1state           = each.value.slot_rear_nvme1state           # PCIe Slot:Rear NVME 1 OptionROM
  slot_rear_nvme2link_speed      = each.value.slot_rear_nvme2link_speed      # PCIe Slot:Rear NVME 2 Link Speed
  slot_rear_nvme2state           = each.value.slot_rear_nvme2state           # PCIe Slot:Rear NVME 2 OptionROM
  slot_rear_nvme3link_speed      = each.value.slot_rear_nvme3link_speed      # PCIe Slot:Rear NVME 3 Link Speed
  slot_rear_nvme3state           = each.value.slot_rear_nvme3state           # PCIe Slot:Rear NVME 3 OptionROM
  slot_rear_nvme4link_speed      = each.value.slot_rear_nvme4link_speed      # PCIe Slot:Rear NVME 4 Link Speed
  slot_rear_nvme4state           = each.value.slot_rear_nvme4state           # PCIe Slot:Rear NVME 4 OptionROM
  slot_rear_nvme5state           = each.value.slot_rear_nvme5state           # PCIe Slot:Rear NVME 5 OptionROM
  slot_rear_nvme6state           = each.value.slot_rear_nvme6state           # PCIe Slot:Rear NVME 6 OptionROM
  slot_rear_nvme7state           = each.value.slot_rear_nvme7state           # PCIe Slot:Rear NVME 7 OptionROM
  slot_rear_nvme8state           = each.value.slot_rear_nvme8state           # PCIe Slot:Rear NVME 8 OptionROM
  slot_riser1link_speed          = each.value.slot_riser1link_speed          # PCIe Slot:Riser1 Link Speed
  slot_riser1slot1link_speed     = each.value.slot_riser1slot1link_speed     # PCIe Slot:Riser1 Slot1 Link Speed
  slot_riser1slot2link_speed     = each.value.slot_riser1slot2link_speed     # PCIe Slot:Riser2 Slot1 Link Speed
  slot_riser1slot3link_speed     = each.value.slot_riser1slot3link_speed     # PCIe Slot:Riser3 Slot1 Link Speed
  slot_riser2link_speed          = each.value.slot_riser2link_speed          # PCIe Slot:Riser2 Link Speed
  slot_riser2slot4link_speed     = each.value.slot_riser2slot4link_speed     # PCIe Slot:Riser2 Slot4 Link Speed
  slot_riser2slot5link_speed     = each.value.slot_riser2slot5link_speed     # PCIe Slot:Riser2 Slot5 Link Speed
  slot_riser2slot6link_speed     = each.value.slot_riser2slot6link_speed     # PCIe Slot:Riser2 Slot6 Link Speed
  slot_sas_state                 = each.value.slot_sas_state                 # PCIe Slot:SAS OptionROM
  slot_ssd_slot1link_speed       = each.value.slot_ssd_slot1link_speed       # PCIe Slot:FrontSSD1 Link Speed
  slot_ssd_slot2link_speed       = each.value.slot_ssd_slot2link_speed       # PCIe Slot:FrontSSD2 Link Speed
  #+++++++++++++++++++++++++++++++
  # Main Section
  #+++++++++++++++++++++++++++++++
  gpu_direct_cpu1       = each.value.gpu_direct_cpu1       # GPU Direct to CPU 1
  gpu_direct_cpu2       = each.value.gpu_direct_cpu2       # GPU Direct to CPU 2
  gpu_direct_cpu3       = each.value.gpu_direct_cpu3       # GPU Direct to CPU 3
  gpu_direct_cpu4       = each.value.gpu_direct_cpu4       # GPU Direct to CPU 4
  pcie_slots_cdn_enable = each.value.pcie_slots_cdn_enable # PCIe Slots CDN Control
  post_error_pause      = each.value.post_error_pause      # POST Error Pause
  #+++++++++++++++++++++++++++++++
  # Memory Section
  #+++++++++++++++++++++++++++++++
  acpi_srat_sp_flag_en                  = each.value.acpi_srat_sp_flag_en                  # ACPI SRAT L3 Cache As NUMA Domain configuration
  adaptive_refresh_mgmt_level           = each.value.adaptive_refresh_mgmt_level           # Adaptive Refresh Management Level
  advanced_mem_test                     = each.value.advanced_mem_test                     # Enhanced Memory Test
  bme_dma_mitigation                    = each.value.bme_dma_mitigation                    # BME DMA Mitigation
  burst_and_postponed_refresh           = each.value.burst_and_postponed_refresh           # Burst and Postponed Refresh
  cbs_cmn_cpu_sev_asid_space_limit      = each.value.cbs_cmn_cpu_sev_asid_space_limit      # SEV-ES ASID Space Limit
  cbs_cmn_cpu_smee                      = each.value.cbs_cmn_cpu_smee                      # CPU SMEE
  cbs_cmn_gnb_nb_iommu                  = each.value.cbs_cmn_gnb_nb_iommu                  # IOMMU
  cbs_cmn_mem_ctrl_bank_group_swap_ddr4 = each.value.cbs_cmn_mem_ctrl_bank_group_swap_ddr4 # Bank Group Swap
  cbs_cmn_mem_map_bank_interleave_ddr4  = each.value.cbs_cmn_mem_map_bank_interleave_ddr4  # Chipset Interleave
  cbs_cmn_mem_speed_ddr47xx2            = each.value.cbs_cmn_mem_speed_ddr47xx2            # Memory Clock Speed 7xx2
  cbs_cmn_mem_speed_ddr47xx3            = each.value.cbs_cmn_mem_speed_ddr47xx3            # Memory Clock Speed 7xx3
  cbs_dbg_cpu_snp_mem_cover             = each.value.cbs_dbg_cpu_snp_mem_cover             # SNP Memory Coverage
  cbs_dbg_cpu_snp_mem_size_cover        = each.value.cbs_dbg_cpu_snp_mem_size_cover        # SNP Memory Size to Cover in MiB
  cbs_df_cmn4link_max_xgmi_speed        = each.value.cbs_df_cmn4link_max_xgmi_speed        # 4-link xGMI max speed
  cbs_df_cmn_dram_nps                   = each.value.cbs_df_cmn_dram_nps                   # NUMA Nodes per Socket
  cbs_df_cmn_dram_scrub_time            = each.value.cbs_df_cmn_dram_scrub_time            # DRAM Scrub Time
  cbs_df_cmn_mem_intlv                  = each.value.cbs_df_cmn_mem_intlv                  # AMD Memory Interleaving
  cbs_df_cmn_mem_intlv_control          = each.value.cbs_df_cmn_mem_intlv_control          # AMD Memory Interleaving Control
  cbs_df_cmn_mem_intlv_size             = each.value.cbs_df_cmn_mem_intlv_size             # AMD Memory Interleaving Size
  cbs_gnb_dbg_pcie_tbt_support          = each.value.cbs_gnb_dbg_pcie_tbt_support          # PCIe Ten Bit Tag Support
  cbs_sev_snp_support                   = each.value.cbs_sev_snp_support                   # SEV-SNP Support
  cke_low_policy                        = each.value.cke_low_policy                        # CKE Low Policy
  cr_qos                                = each.value.cr_qos                                # CR QoS
  crfastgo_config                       = each.value.crfastgo_config                       # CR FastGo Config
  dcpmm_firmware_downgrade              = each.value.dcpmm_firmware_downgrade              # DCPMM Firmware Downgrade
  dram_refresh_rate                     = each.value.dram_refresh_rate                     # DRAM Refresh Rate
  dram_sw_thermal_throttling            = each.value.dram_sw_thermal_throttling            # DRAM SW Thermal Throttling
  eadr_support                          = each.value.eadr_support                          # eADR Support
  enable_rmt                            = each.value.enable_rmt                            # Rank Margin Tool
  error_check_scrub                     = each.value.error_check_scrub                     # Error Check Scrub
  lv_ddr_mode                           = each.value.lv_ddr_mode                           # Low Voltage DDR Mode
  memory_bandwidth_boost                = each.value.memory_bandwidth_boost                # Memory Bandwidth Boost
  memory_refresh_rate                   = each.value.memory_refresh_rate                   # Memory Refresh Rate
  memory_size_limit                     = each.value.memory_size_limit                     # Memory Size Limit in GiB
  memory_thermal_throttling             = each.value.memory_thermal_throttling             # Memory Thermal Throttling Mode
  mirroring_mode                        = each.value.mirroring_mode                        # Mirroring Mode
  mmioh_base                            = each.value.mmioh_base                            # MMIO High Base
  mmioh_size                            = each.value.mmioh_size                            # MMIO High Granularity Size
  numa_optimized                        = each.value.numa_optimized                        # NUMA Optimized
  nvmdimm_perform_config                = each.value.nvmdimm_perform_config                # NVM Performance Setting
  operation_mode                        = each.value.operation_mode                        # Operation Mode
  panic_high_watermark                  = each.value.panic_high_watermark                  # Panic and High Watermark
  partial_cache_line_sparing            = each.value.partial_cache_line_sparing            # Partial Cache Line Sparing
  partial_mirror_mode_config            = each.value.partial_mirror_mode_config            # Partial Memory Mirror Mode
  partial_mirror_percent                = each.value.partial_mirror_percent                # Partial Mirror Percentage
  partial_mirror_value1                 = each.value.partial_mirror_value1                 # Partial Mirror1 Size in GiB
  partial_mirror_value2                 = each.value.partial_mirror_value2                 # Partial Mirror2 Size in GiB
  partial_mirror_value3                 = each.value.partial_mirror_value3                 # Partial Mirror3 Size in GiB
  partial_mirror_value4                 = each.value.partial_mirror_value4                 # Partial Mirror4 Size in GiB
  pc_ie_ras_support                     = each.value.pc_ie_ras_support                     # PCIe RAS Support
  pre_boot_dma_protection               = each.value.pre_boot_dma_protection               # PreBoot DMA Protection configuration
  post_package_repair                   = each.value.post_package_repair                   # Post Package Repair
  runtime_post_package_repair           = each.value.runtime_post_package_repair           # Runtime Post Package Repair
  select_memory_ras_configuration       = each.value.select_memory_ras_configuration       # Memory RAS Configuration
  select_ppr_type                       = each.value.select_ppr_type                       # PPR Type
  sev                                   = each.value.sev                                   # Secured Encrypted Virtualization
  smee                                  = each.value.smee                                  # SMEE
  snoopy_mode_for2lm                    = each.value.snoopy_mode_for2lm                    # Snoopy Mode for 2LM
  snoopy_mode_for_ad                    = each.value.snoopy_mode_for_ad                    # Snoopy Mode for AD
  sparing_mode                          = each.value.sparing_mode                          # Sparing Mode
  tsme                                  = each.value.tsme                                  # Transparent Secure Memory Encryption
  uefi_mem_map_sp_flag_en               = each.value.uefi_mem_map_sp_flag_en               # UEFI Memory Map Special Purpose Memory
  uma_based_clustering                  = each.value.uma_based_clustering                  # UMA Based Clustering
  vol_memory_mode                       = each.value.vol_memory_mode                       # Volatile Memory Mode
  #+++++++++++++++++++++++++++++++
  # PCI Section
  #+++++++++++++++++++++++++++++++
  aspm_support               = each.value.aspm_support               # ASPM Support
  ioh_resource               = each.value.ioh_resource               # IOH Resource Allocation
  memory_mapped_io_above4gb  = each.value.memory_mapped_io_above4gb  # Memory Mapped IO Above 4GiB
  mmcfg_base                 = each.value.mmcfg_base                 # MMCFG BASE
  onboard10gbit_lom          = each.value.onboard10gbit_lom          # Onboard 10Gbit LOM
  onboard_gbit_lom           = each.value.onboard_gbit_lom           # Onboard Gbit LOM
  pc_ie_ssd_hot_plug_support = each.value.pc_ie_ssd_hot_plug_support # NVMe SSD Hot-Plug Support
  resize_bar_support         = each.value.resize_bar_support         # Re-Size BAR Support
  sr_iov                     = each.value.sr_iov                     # SR-IOV Support
  vga_priority               = each.value.vga_priority               # VGA Priority
  #+++++++++++++++++++++++++++++++
  # Power and Performance Section
  #+++++++++++++++++++++++++++++++
  c1auto_demotion                    = each.value.c1auto_demotion                    # C1 Auto Demotion
  c1auto_un_demotion                 = each.value.c1auto_un_demotion                 # C1 Auto UnDemotion
  cbs_cmn_cpu_cpb                    = each.value.cbs_cmn_cpu_cpb                    # Core Performance Boost
  cbs_cmn_cpu_global_cstate_ctrl     = each.value.cbs_cmn_cpu_global_cstate_ctrl     # Global C State Control
  cbs_cmn_cpu_l1stream_hw_prefetcher = each.value.cbs_cmn_cpu_l1stream_hw_prefetcher # L1 Stream HW Prefetcher
  cbs_cmn_cpu_l2stream_hw_prefetcher = each.value.cbs_cmn_cpu_l2stream_hw_prefetcher # L2 Stream HW Prefetcher
  cbs_cmn_determinism_slider         = each.value.cbs_cmn_determinism_slider         # Determinism Slider
  cbs_cmn_efficiency_mode_en         = each.value.cbs_cmn_efficiency_mode_en         # Efficiency Mode Enable
  cbs_cmn_efficiency_mode_en_rs      = each.value.cbs_cmn_efficiency_mode_en_rs      # Power Profile Selection F19h
  cbs_cmn_gnb_smucppc                = each.value.cbs_cmn_gnb_smucppc                # CPPC
  cbs_cmnc_tdp_ctl                   = each.value.cbs_cmnc_tdp_ctl                   # cTDP Control
  cpu_perf_enhancement               = each.value.cpu_perf_enhancement               # Enhanced CPU Performance
  llc_alloc                          = each.value.llc_alloc                          # LLC Dead Line
  optimized_power_mode               = each.value.optimized_power_mode               # Optimized Power Mode
  upi_link_enablement                = each.value.upi_link_enablement                # UPI Link Enablement
  upi_power_management               = each.value.upi_power_management               # UPI Power Management
  virtual_numa                       = each.value.virtual_numa                       # Virtual Numa
  xpt_remote_prefetch                = each.value.xpt_remote_prefetch                # XPT Remote Prefetch
  #+++++++++++++++++++++++++++++++
  # Processor Section
  #+++++++++++++++++++++++++++++++
  adjacent_cache_line_prefetch      = each.value.adjacent_cache_line_prefetch      # Adjacent Cache Line Prefetcher
  altitude                          = each.value.altitude                          # Altitude
  auto_cc_state                     = each.value.auto_cc_state                     # Autonomous Core C State
  autonumous_cstate_enable          = each.value.autonumous_cstate_enable          # CPU Autonomous C State
  boot_performance_mode             = each.value.boot_performance_mode             # Boot Performance Mode
  cbs_cmn_apbdis                    = each.value.cbs_cmn_apbdis                    # APBDIS
  cbs_cmn_apbdis_df_pstate_rs       = each.value.cbs_cmn_apbdis_df_pstate_rs       # Fixed SOC P-State SP5 F19h
  cbs_cmn_cpu_avx512                = each.value.cbs_cmn_cpu_avx512                # AVX512
  cbs_cmn_cpu_gen_downcore_ctrl     = each.value.cbs_cmn_cpu_gen_downcore_ctrl     # Downcore Control
  cbs_cmn_cpu_streaming_stores_ctrl = each.value.cbs_cmn_cpu_streaming_stores_ctrl # Streaming Stores Control
  cbs_cmn_edc_control_throttle      = each.value.cbs_cmn_edc_control_throttle      # EDC Control Throttle
  cbs_cmn_fixed_soc_pstate          = each.value.cbs_cmn_fixed_soc_pstate          # Fixed SOC P-State
  cbs_cmn_gnb_smu_df_cstates        = each.value.cbs_cmn_gnb_smu_df_cstates        # DF C-States
  cbs_cmn_gnb_smu_dffo_rs           = each.value.cbs_cmn_gnb_smu_dffo_rs           # DF PState Frequency Optimizer
  cbs_cmn_gnb_smu_dlwm_support      = each.value.cbs_cmn_gnb_smu_dlwm_support      # DLWM Support
  cbs_cmn_mem_ctrller_pwr_dn_en_ddr = each.value.cbs_cmn_mem_ctrller_pwr_dn_en_ddr # Power Down Enable
  cbs_cmn_preferred_io7xx2          = each.value.cbs_cmn_preferred_io7xx2          # Preferred IO 7xx2
  cbs_cmn_preferred_io7xx3          = each.value.cbs_cmn_preferred_io7xx3          # Preferred IO 7xx3
  cbs_cmnx_gmi_force_link_width_rs  = each.value.cbs_cmnx_gmi_force_link_width_rs  # xGMI Force Link Width
  cbs_cpu_ccd_ctrl_ssp              = each.value.cbs_cpu_ccd_ctrl_ssp              # CCD Control
  cbs_cpu_core_ctrl                 = each.value.cbs_cpu_core_ctrl                 # CPU Downcore Control
  cbs_cpu_down_core_ctrl_bergamo    = each.value.cbs_cpu_down_core_ctrl_bergamo    # CPU Downcore Control - Bergamo
  cbs_cpu_down_core_ctrl_genoa      = each.value.cbs_cpu_down_core_ctrl_genoa      # CPU Downcore Control - Genoa
  cbs_cpu_smt_ctrl                  = each.value.cbs_cpu_smt_ctrl                  # CPU SMT Mode
  cbs_dbg_cpu_gen_cpu_wdt           = each.value.cbs_dbg_cpu_gen_cpu_wdt           # Core Watchdog Timer Enable
  cbs_dbg_cpu_lapic_mode            = each.value.cbs_dbg_cpu_lapic_mode            # Local APIC Mode
  cbs_df_cmn_acpi_srat_l3numa       = each.value.cbs_df_cmn_acpi_srat_l3numa       # ACPI SRAT L3 Cache As NUMA Domain
  cbs_df_dbg_xgmi_link_cfg          = each.value.cbs_df_dbg_xgmi_link_cfg          # Cisco xGMI Max Speed
  channel_inter_leave               = each.value.channel_inter_leave               # Channel Interleaving
  cisco_xgmi_max_speed              = each.value.cisco_xgmi_max_speed              # Cisco xGMI Max Speed
  closed_loop_therm_throtl          = each.value.closed_loop_therm_throtl          # Closed Loop Thermal Throttling
  cmci_enable                       = each.value.cmci_enable                       # Processor CMCI
  config_tdp                        = each.value.config_tdp                        # Config TDP
  config_tdp_level                  = each.value.config_tdp_level                  # Configurable TDP Level
  core_multi_processing             = each.value.core_multi_processing             # Core Multi Processing
  cpu_energy_performance            = each.value.cpu_energy_performance            # Energy Performance
  cpu_frequency_floor               = each.value.cpu_frequency_floor               # Frequency Floor Override
  cpu_performance                   = each.value.cpu_performance                   # CPU Performance
  cpu_power_management              = each.value.cpu_power_management              # Power Technology
  demand_scrub                      = each.value.demand_scrub                      # Demand Scrub
  dfx_osb_en                        = each.value.dfx_osb_en                        # DFX OSB
  direct_cache_access               = each.value.direct_cache_access               # Direct Cache Access Support
  dram_clock_throttling             = each.value.dram_clock_throttling             # DRAM Clock Throttling
  energy_efficient_turbo            = each.value.energy_efficient_turbo            # Energy Efficient Turbo
  eng_perf_tuning                   = each.value.eng_perf_tuning                   # Energy Performance Tuning
  enhanced_intel_speed_step_tech    = each.value.enhanced_intel_speed_step_tech    # Enhanced Intel Speedstep(R) Technology
  epp_enable                        = each.value.epp_enable                        # Processor EPP Enable
  epp_profile                       = each.value.epp_profile                       # EPP Profile
  execute_disable_bit               = each.value.execute_disable_bit               # Execute Disable Bit
  extended_apic                     = each.value.extended_apic                     # Local X2 Apic
  hardware_prefetch                 = each.value.hardware_prefetch                 # Hardware Prefetcher
  hwpm_enable                       = each.value.hwpm_enable                       # CPU Hardware Power Management
  imc_interleave                    = each.value.imc_interleave                    # IMC Interleaving
  intel_dynamic_speed_select        = each.value.intel_dynamic_speed_select        # Intel Dynamic Speed Select
  intel_hyper_threading_tech        = each.value.intel_hyper_threading_tech        # Intel HyperThreading Tech
  intel_speed_select                = each.value.intel_speed_select                # Intel Speed Select
  intel_turbo_boost_tech            = each.value.intel_turbo_boost_tech            # Intel Turbo Boost Tech
  intel_virtualization_technology   = each.value.intel_virtualization_technology   # Intel(R) VT
  ioat_config_cpm                   = each.value.ioat_config_cpm                   # IOAT Configuration
  ioh_error_enable                  = each.value.ioh_error_enable                  # IIO Error Enable
  ip_prefetch                       = each.value.ip_prefetch                       # DCU IP Prefetcher
  kti_prefetch                      = each.value.kti_prefetch                      # KTI Prefetch
  llc_prefetch                      = each.value.llc_prefetch                      # LLC Prefetch
  memory_inter_leave                = each.value.memory_inter_leave                # Intel Memory Interleaving
  package_cstate_limit              = each.value.package_cstate_limit              # Package C State Limit
  patrol_scrub                      = each.value.patrol_scrub                      # Patrol Scrub
  patrol_scrub_duration             = each.value.patrol_scrub_duration             # Patrol Scrub Interval
  processor_c1e                     = each.value.processor_c1e                     # Processor C1E
  processor_c3report                = each.value.processor_c3report                # Processor C3 Report
  processor_c6report                = each.value.processor_c6report                # Processor C6 Report
  processor_cstate                  = each.value.processor_cstate                  # CPU C State
  pstate_coord_type                 = each.value.pstate_coord_type                 # P-State Coordination
  pwr_perf_tuning                   = each.value.pwr_perf_tuning                   # Power Performance Tuning
  qpi_link_speed                    = each.value.qpi_link_speed                    # UPI Link Frequency Select
  rank_inter_leave                  = each.value.rank_inter_leave                  # Rank Interleaving
  single_pctl_enable                = each.value.single_pctl_enable                # Single PCTL
  smt_mode                          = each.value.smt_mode                          # SMT Mode
  snc                               = each.value.snc                               # Sub Numa Clustering
  streamer_prefetch                 = each.value.streamer_prefetch                 # DCU Streamer Prefetch
  svm_mode                          = each.value.svm_mode                          # SVM Mode
  ufs_disable                       = each.value.ufs_disable                       # Uncore Frequency Scaling
  # ufs_disable_io                    = each.value.ufs_disable_io                    # Uncore Frequency Scaling IO
  work_load_config = each.value.work_load_config # Workload Configuration
  x2apic_opt_out   = each.value.x2apic_opt_out   # X2 APIC Opt-Out Flag
  xpt_prefetch     = each.value.xpt_prefetch     # XPT Prefetch
  #+++++++++++++++++++++++++++++++
  # QPI Section
  #+++++++++++++++++++++++++++++++
  qpi_link_frequency = each.value.qpi_link_frequency # QPI Link Frequency Select
  qpi_snoop_mode     = each.value.qpi_snoop_mode     # QPI Snoop Mode
  #+++++++++++++++++++++++++++++++
  # Security Section
  #+++++++++++++++++++++++++++++++
  enable_tdx         = each.value.enable_tdx         # Trust Domain Extension (TDX)
  enable_tdx_seamldr = each.value.enable_tdx_seamldr # TDX Secure Arbitration Mode (SEAM) Loader
  #+++++++++++++++++++++++++++++++
  # Serial Port Section
  #+++++++++++++++++++++++++++++++
  serial_port_aenable = each.value.serial_port_aenable # Serial A Enable
  #+++++++++++++++++++++++++++++++
  # Server Management Section
  #+++++++++++++++++++++++++++++++
  assert_nmi_on_perr              = each.value.assert_nmi_on_perr              # Assert NMI on PERR
  assert_nmi_on_serr              = each.value.assert_nmi_on_serr              # Assert NMI on SERR
  baud_rate                       = each.value.baud_rate                       # Baud Rate
  cdn_enable                      = each.value.cdn_enable                      # Consistent Device Naming
  cisco_adaptive_mem_training     = each.value.cisco_adaptive_mem_training     # Adaptive Memory Training
  cisco_debug_level               = each.value.cisco_debug_level               # BIOS Techlog Level
  cisco_oprom_launch_optimization = each.value.cisco_oprom_launch_optimization # OptionROM Launch Optimization
  console_redirection             = each.value.console_redirection             # Console Redirection
  flow_control                    = each.value.flow_control                    # Flow Control
  frb2enable                      = each.value.frb2enable                      # FRB-2 Timer
  legacy_os_redirection           = each.value.legacy_os_redirection           # Legacy OS Redirection
  os_boot_watchdog_timer          = each.value.os_boot_watchdog_timer          # OS Boot Watchdog Timer
  os_boot_watchdog_timer_policy   = each.value.os_boot_watchdog_timer_policy   # OS Boot Watchdog Timer Policy
  os_boot_watchdog_timer_timeout  = each.value.os_boot_watchdog_timer_timeout  # OS Boot Watchdog Timer Timeout
  out_of_band_mgmt_port           = each.value.out_of_band_mgmt_port           # Out-of-Band Mgmt Port
  putty_key_pad                   = each.value.putty_key_pad                   # Putty KeyPad
  redirection_after_post          = each.value.redirection_after_post          # Redirection After BIOS POST
  serial_mux                      = each.value.serial_mux                      # Serial Mux
  terminal_type                   = each.value.terminal_type                   # Terminal Type
  ucsm_boot_order_rule            = each.value.ucsm_boot_order_rule            # Boot Order Rules
  #+++++++++++++++++++++++++++++++
  # Trusted Platform Section
  #+++++++++++++++++++++++++++++++
  cpu_pa_limit                    = each.value.cpu_pa_limit                    # CPU PA to 46 Bits
  dma_ctrl_opt_in                 = each.value.dma_ctrl_opt_in                 # DMA Control Opt-In Flag
  enable_mktme                    = each.value.enable_mktme                    # Multikey Total Memory Encryption (MK-TME)
  enable_sgx                      = each.value.enable_sgx                      # Software Guard Extensions
  enable_tme                      = each.value.enable_tme                      # Total Memory Encryption
  epoch_update                    = each.value.epoch_update                    # Select Owner EPOCH Input Type
  sgx_auto_registration_agent     = each.value.sgx_auto_registration_agent     # SGX Auto MP Registration Agent
  sgx_epoch0                      = each.value.sgx_epoch0                      # SGX Epoch 0
  sgx_epoch1                      = each.value.sgx_epoch1                      # SGX Epoch 1
  sgx_factory_reset               = each.value.sgx_factory_reset               # SGX Factory Reset
  sgx_le_pub_key_hash0            = each.value.sgx_le_pub_key_hash0            # SGX PubKey Hash0
  sgx_le_pub_key_hash1            = each.value.sgx_le_pub_key_hash1            # SGX PubKey Hash1
  sgx_le_pub_key_hash2            = each.value.sgx_le_pub_key_hash2            # SGX PubKey Hash2
  sgx_le_pub_key_hash3            = each.value.sgx_le_pub_key_hash3            # SGX PubKey Hash3
  sgx_le_wr                       = each.value.sgx_le_wr                       # SGX Write Eanble
  sgx_package_info_in_band_access = each.value.sgx_package_info_in_band_access # SGX Package Information In-Band Access
  sgx_qos                         = each.value.sgx_qos                         # SGX QoS
  sha1pcr_bank                    = each.value.sha1pcr_bank                    # SHA1 PCR Bank
  sha256pcr_bank                  = each.value.sha256pcr_bank                  # SHA256 PCR Bank
  sha384pcr_bank                  = each.value.sha384pcr_bank                  # SHA384 PCR Bank
  tpm_control                     = each.value.tpm_control                     # Trusted Platform Module State
  tpm_pending_operation           = each.value.tpm_pending_operation           # TPM Pending Operation
  tpm_ppi_required                = each.value.tpm_ppi_required                # TPM Minimal Physical Presence
  tpm_support                     = each.value.tpm_support                     # Trusted Platform Module State
  txt_support                     = each.value.txt_support                     # Intel Trusted Execution Technology Support
  #+++++++++++++++++++++++++++++++
  # USB Section
  #+++++++++++++++++++++++++++++++
  all_usb_devices          = each.value.all_usb_devices          # All USB Devices
  legacy_usb_support       = each.value.legacy_usb_support       # Legacy USB Support
  make_device_non_bootable = each.value.make_device_non_bootable # Make Device Non Bootable
  pch_usb30mode            = each.value.pch_usb30mode            # xHCI Mode
  usb_emul6064             = each.value.usb_emul6064             # Port 60/64 Emulation
  usb_port_front           = each.value.usb_port_front           # USB Port Front
  usb_port_internal        = each.value.usb_port_internal        # USB Port Internal
  usb_port_kvm             = each.value.usb_port_kvm             # USB Port KVM
  usb_port_rear            = each.value.usb_port_rear            # USB Port Rear
  usb_port_sd_card         = each.value.usb_port_sd_card         # USB Port SD Card
  usb_port_vmedia          = each.value.usb_port_vmedia          # USB Port VMedia
  usb_xhci_support         = each.value.usb_xhci_support         # XHCI Legacy Support

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
