## Unreleased

- Add support for Intersight policies: adapter configuration, certificate management, device connector, drive security, FC zone, flow control, iSCSI adapter, iSCSI boot, iSCSI static target, LDAP, link aggregation, link control, MACsec, memory, multicast, persistent memory, qualification, SD card, scrub, switch control, system QoS, VLAN, VSAN
- Add `servers[].provisioning.power_state` (`on`, `shutdown`, `off`) to manage the server power state declaratively: the power operation is only sent when the actual power state differs from the desired one, and is sent again on every apply until the server has the desired state. Servers without the attribute are never touched. Requires `provisioning.intersight.serial_number`. The provider has no resource for `compute.ServerSetting`, so the module calls `scripts/set_server_power.py`, which needs `python3` with the `requests` and `cryptography` packages and the `INTERSIGHT_*` environment variables
- Fix a perpetual diff on server profile templates that reference a firmware or boot order policy: the provider misread these policies, so every plan showed a change to the template. Templates now set their policies in a way the provider reads back correctly
- Add support for Intersight templates: chassis, domain, vHBA, vNIC
- Add support for Intersight pools: IQN, resource
- Add support for Intersight server, chassis and domain profiles, including assignment and pre-assignment by serial number before Intersight has inventoried the hardware. Profiles are derived from their template, inheriting its policies and target platform (unless a server overrides them, see below), and are synced and deployed according to the `action` attribute (`sync`, `deploy`, `sync_and_deploy`, `unassign`), with consistent behavior across the three profile types
  - Deploys wait for the profile workflows to finish, so `terraform apply` blocks until the deploy completes
  - Server profile deploys schedule an Intersight Activate with proceed-on-reboot, so changes that need a host reboot are applied without a manual activation. `terraform apply` waits for the deploy workflow only: the activation (host reboot) runs after it, so the profile can still be activating when the apply completes and reaches `Associated` later
  - `deploy` only runs when the profile is created, its template changes, the server starts or stops overriding its template's settings, or `action` is set to `deploy`, not on later applies or when the template contents change
  - Commenting out or removing a serial number does not detach the profile from the hardware. Set `action: unassign` to send Intersight's `Unassign` command
  - Changing the template of a profile derived from a template requires two applies: one with the template key removed (detaches the profile) and one with the new template set
  - Destroying a profile waits for the hardware to be unassigned before the profile is deleted
- Add per-server policies, UUID pool and target platform (`servers[].provisioning.intersight.policies`, `uuid_pool`, `target_platform`), so a server profile can override some of its template's settings, or be configured without a template at all, without a dedicated template for every server that differs from the others
  - A server that overrides some of its template's settings, or has no template, gets a standalone profile: Intersight does not allow a profile derived from a template to differ from it. The profile's policies are the template's, with the server's settings replacing them
  - The template's settings are taken at the same points in time as a derived profile is synced with its template, so `action` works the same for both
  - A server that starts or stops overriding its template's settings is detached from, or attached to, its template in a single apply
  - Intersight cannot change the target platform of an existing server profile. To change it, remove the server's entry and apply, so the profile is deleted, then add it back
- Add `profile_sync_wait` input (default `30s`) to set how long to wait between syncing a server or domain profile with its template and deploying it. The module now requires the `hashicorp/time` provider
- Add support for Intersight LAN/SAN pin-groups
- Add support for managing Intersight organizations (create/update), with the built-in `default` organization always resolved by lookup
- Add path tag support across policies and templates
- Add multi-workspace deployment support via `manage_*` category flags and `managed_*` name/tag inclusion lists for pools, policies, templates, profiles, and servers
- Fix `tags` (key/value and path tags) being ignored on all pools, policies and server profile templates, so tags defined in the data model were never applied
- **Breaking:** the Intersight endpoint is no longer hardcoded to `https://intersight.com` — set the `INTERSIGHT_ENDPOINT_URL` environment variable (required, no default) to configure it, matching the existing `INTERSIGHT_API_KEY` / `INTERSIGHT_SECRET_KEY` pattern
- **Breaking:** data model inputs renamed or retyped since 0.1.0, which existing configurations must be updated for:
  - NTP policy `authenticated_ntp_servers`: `sym_key_id` and `sym_key_value` are now `symmetric_key_id` and `symmetric_key_value`
  - Ethernet adapter policy: `nr_count` is now `completion_queue_count`, `interrupt_count`, `rx_queue_count` and `tx_queue_count` in `completion_queue_settings`, `interrupt_settings`, `rx_queue_settings` and `tx_queue_settings` respectively, and `roce_settings.class_of_service` is now `cos`
  - Power policy: `dynamic_rebalancing`, `extended_power_capacity`, `power_profiling` and `power_save_mode` are now booleans instead of `Enabled`/`Disabled`

## 0.1.0

Initial release of the Network as Code Compute Terraform module.

- Add support for organizations (as pre-existing Intersight organizations)
- Add support for pools: IP, MAC, UUID, WWNN, WWPN
- Add support for policies: BIOS, boot order, IMC access, ethernet adapter, ethernet network, ethernet network control, ethernet network group, ethernet QoS, fibre channel adapter, fibre channel network, fibre channel QoS, firmware, IPMI over LAN, LAN connectivity, local user, network connectivity, NTP, power, SAN connectivity, serial over LAN, SMTP, SNMP, SSH, storage, syslog, thermal, virtual KVM, virtual media
- Add support for server profile templates, referencing pools and policies by name
- Add support for tags on managed objects
- Add support for modeling configuration via YAML files or native Terraform variables
- Add `write_default_values_file` input to export all default values to a YAML file
- Add HCL and YAML example configurations under `examples/`
