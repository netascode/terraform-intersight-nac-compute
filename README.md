<!-- BEGIN_TF_DOCS -->
# Terraform Compute Network-as-Code Module

A Terraform module to configure Compute (Intersight and UCS).

This module is part of the Cisco [*Network-as-Code*](https://netascode.cisco.com) project. Its goal is to allow users to instantiate network fabrics in minutes using an easy to use, opinionated data model. It takes away the complexity of having to deal with references, dependencies or loops. By completely separating data (defining variables) from logic (infrastructure declaration), it allows the user to focus on describing the intended configuration while using a set of maintained and tested Terraform Modules without the need to understand the low-level object model. More information can be found here: https://netascode.cisco.com.

## Usage

This module supports an inventory driven approach, where a complete compute configuration or parts of it are either modeled in one or more YAML files or natively using Terraform variables.

Configuration is modeled as a list of Intersight `organizations`, each of which must already exist in Intersight. Every organization contains the following building blocks, all referenced by name:

- `pools`: Identifier pools assigned to server profile templates (e.g., IP, MAC, UUID, WWNN, WWPN)
- `policies`: Configuration policies applied to servers and domains (e.g., BIOS, boot order, network/adapter/QoS, firmware, NTP, local user, storage, port, switch control, system QoS)
- `templates.server`: Server profile templates, which reference pools and policies to define a complete, reusable server configuration
- `templates.domain`: UCS domain (FI pair) profile templates
- `templates.chassis`: UCS chassis profile templates
- `profiles.domain`: UCS domain profiles, optionally derived from a domain template
- `profiles.chassis`: UCS chassis profiles, optionally derived from a chassis template

A top-level `servers` list provisions individual servers through Intersight or Redfish.

The full data model documentation is available here: https://netascode.cisco.com/docs/data_models/compute/overview/

## Multi-Workspace Deployment

As the number of UCS domains, chassis, and servers grows, a single Terraform workspace managing all resources can become slow and creates a wide blast radius. Two orthogonal mechanisms let you split the data model across multiple workspaces:

**Category flags** (`manage_*`) enable or disable entire resource categories. All default to `false` — add the flags you need in your workspace `terraform.tfvars`.

**Inclusion lists** (`managed_*`) restrict which named objects or tagged objects within an enabled category are managed. Both a name list and a tag list (supplied as `"key=value"` strings) can be combined — an object is included when its name is in the name list **or** it carries **all** required tags. Empty lists on both variables means include everything.

### Example: policies workspace for DC-A by org name

```hcl
manage_intersight_policies       = true
manage_intersight_pools          = true
managed_intersight_organizations = ["dc-a-prod", "dc-a-dev"]
```

### Example: profiles workspace filtering by tag

```hcl
manage_intersight_profiles           = true
manage_intersight_templates          = true
managed_intersight_organization_tags = ["datacenter=dc-a"]
managed_intersight_domains           = ["dc-a-ucs-01", "dc-a-ucs-02"]
```

### Example: server workspace by tag

```hcl
manage_servers      = true
managed_server_tags = ["cluster=vsphere-prod-01"]
```

### Example: full single-workspace (all categories enabled)

```hcl
manage_intersight_policies  = true
manage_intersight_pools     = true
manage_intersight_templates = true
manage_intersight_profiles  = true
manage_servers              = true
```

## Examples

Configuring an NTP Policy using native HCL:

#### `main.tf`

```hcl
module "ntp_policy" {
  source  = "netascode/nac-compute/compute"
  version = ">= 0.1.0"

  model = {
    compute = {
      intersight = {
        organizations = [
          {
            name = "default"
            policies = {
              ntp = [
                {
                  name        = "NTP_POLICY_1"
                  ntp_servers = ["173.38.201.115", "173.38.201.116"]
                  timezone    = "America/New_York"
                }
              ]
            }
          }
        ]
      }
    }
  }
}
````

Configuring an IP Pool using YAML:

#### `ip_pool.yaml`

```hcl
compute:
  intersight:
    organizations:
      - name: default
        pools:
          ip:
            - name: IP_POOL_1
              ipv4_config:
                gateway: 192.168.1.1
                netmask: 255.255.255.0
                primary_dns: 8.8.8.8
              ipv4_blocks:
                - from: 192.168.1.10
                  size: 100
```

#### `main.tf`

```hcl
module "ip_pool" {
  source  = "netascode/nac-compute/compute"
  version = ">= 0.1.0"

  yaml_files = ["ip_pool.yaml"]
}
````

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_intersight"></a> [intersight](#requirement\_intersight) | >= 1.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.3.0 |
| <a name="requirement_utils"></a> [utils](#requirement\_utils) | =2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_manage_intersight_policies"></a> [manage\_intersight\_policies](#input\_manage\_intersight\_policies) | When true, manage all policy resources under intersight.organizations[].policies. | `bool` | `false` | no |
| <a name="input_manage_intersight_pools"></a> [manage\_intersight\_pools](#input\_manage\_intersight\_pools) | When true, manage all pool resources under intersight.organizations[].pools. | `bool` | `false` | no |
| <a name="input_manage_intersight_profiles"></a> [manage\_intersight\_profiles](#input\_manage\_intersight\_profiles) | When true, manage all profile resources (domain and chassis profiles). | `bool` | `false` | no |
| <a name="input_manage_intersight_templates"></a> [manage\_intersight\_templates](#input\_manage\_intersight\_templates) | When true, manage all template resources (server, domain, chassis). | `bool` | `false` | no |
| <a name="input_manage_servers"></a> [manage\_servers](#input\_manage\_servers) | When true, manage server provisioning resources under servers[]. | `bool` | `false` | no |
| <a name="input_managed_intersight_chassis"></a> [managed\_intersight\_chassis](#input\_managed\_intersight\_chassis) | List of chassis profile names to include within filtered orgs. Empty = include all. | `list(string)` | `[]` | no |
| <a name="input_managed_intersight_chassis_tags"></a> [managed\_intersight\_chassis\_tags](#input\_managed\_intersight\_chassis\_tags) | List of "key=value" tag strings. Chassis profiles that carry ALL listed tags are included. Empty = include all. | `list(string)` | `[]` | no |
| <a name="input_managed_intersight_domain_tags"></a> [managed\_intersight\_domain\_tags](#input\_managed\_intersight\_domain\_tags) | List of "key=value" tag strings. Domain profiles that carry ALL listed tags are included. Empty = include all. | `list(string)` | `[]` | no |
| <a name="input_managed_intersight_domains"></a> [managed\_intersight\_domains](#input\_managed\_intersight\_domains) | List of domain profile names to include within filtered orgs. Empty = include all. | `list(string)` | `[]` | no |
| <a name="input_managed_intersight_organization_tags"></a> [managed\_intersight\_organization\_tags](#input\_managed\_intersight\_organization\_tags) | List of "key=value" tag strings. Orgs that carry ALL listed tags are included. Empty = include all. | `list(string)` | `[]` | no |
| <a name="input_managed_intersight_organizations"></a> [managed\_intersight\_organizations](#input\_managed\_intersight\_organizations) | List of organization names to include. Empty = include all. | `list(string)` | `[]` | no |
| <a name="input_managed_server_tags"></a> [managed\_server\_tags](#input\_managed\_server\_tags) | List of "key=value" tag strings. Servers that carry ALL listed tags are included. Empty = include all. | `list(string)` | `[]` | no |
| <a name="input_managed_servers"></a> [managed\_servers](#input\_managed\_servers) | List of server names to include. Empty = include all. | `list(string)` | `[]` | no |
| <a name="input_model"></a> [model](#input\_model) | As an alternative to YAML files, a native Terraform data structure can be provided. | `map(any)` | `{}` | no |
| <a name="input_write_default_values_file"></a> [write\_default\_values\_file](#input\_write\_default\_values\_file) | Write all default values to a YAML file. Value is a path pointing to the file to be created. | `string` | `""` | no |
| <a name="input_yaml_directories"></a> [yaml\_directories](#input\_yaml\_directories) | List of paths to YAML directories. | `list(string)` | `[]` | no |
| <a name="input_yaml_files"></a> [yaml\_files](#input\_yaml\_files) | List of paths to YAML files. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_values"></a> [default\_values](#output\_default\_values) | All default values. |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_intersight"></a> [intersight](#provider\_intersight) | >= 1.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.3.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Resources

| Name | Type |
|------|------|
| [intersight_access_policy.imc_access_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/access_policy) | resource |
| [intersight_adapter_config_policy.adapter_configuration_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/adapter_config_policy) | resource |
| [intersight_bios_policy.bios_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/bios_policy) | resource |
| [intersight_boot_precision_policy.boot_precision_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/boot_precision_policy) | resource |
| [intersight_certificatemanagement_policy.certificate_management_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/certificatemanagement_policy) | resource |
| [intersight_chassis_profile.chassis_profile](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/chassis_profile) | resource |
| [intersight_chassis_profile_template.chassis_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/chassis_profile_template) | resource |
| [intersight_compute_scrub_policy.scrub_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/compute_scrub_policy) | resource |
| [intersight_deviceconnector_policy.device_connector_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/deviceconnector_policy) | resource |
| [intersight_fabric_appliance_pc_role.appliance_pc_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_appliance_pc_role) | resource |
| [intersight_fabric_appliance_role.appliance_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_appliance_role) | resource |
| [intersight_fabric_eth_network_control_policy.ethernet_network_control_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_eth_network_control_policy) | resource |
| [intersight_fabric_eth_network_group_policy.ethernet_network_group_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_eth_network_group_policy) | resource |
| [intersight_fabric_eth_network_policy.vlan_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_eth_network_policy) | resource |
| [intersight_fabric_fc_network_policy.vsan_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_fc_network_policy) | resource |
| [intersight_fabric_fc_storage_role.fc_storage_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_fc_storage_role) | resource |
| [intersight_fabric_fc_uplink_pc_role.fc_uplink_pc_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_fc_uplink_pc_role) | resource |
| [intersight_fabric_fc_uplink_role.fc_uplink_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_fc_uplink_role) | resource |
| [intersight_fabric_fc_zone_policy.fc_zone_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_fc_zone_policy) | resource |
| [intersight_fabric_fcoe_uplink_pc_role.fcoe_uplink_pc_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_fcoe_uplink_pc_role) | resource |
| [intersight_fabric_fcoe_uplink_role.fcoe_uplink_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_fcoe_uplink_role) | resource |
| [intersight_fabric_flow_control_policy.flow_control_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_flow_control_policy) | resource |
| [intersight_fabric_link_aggregation_policy.link_aggregation_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_link_aggregation_policy) | resource |
| [intersight_fabric_link_control_policy.link_control_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_link_control_policy) | resource |
| [intersight_fabric_multicast_policy.multicast_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_multicast_policy) | resource |
| [intersight_fabric_port_mode.port_mode](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_port_mode) | resource |
| [intersight_fabric_port_policy.port_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_port_policy) | resource |
| [intersight_fabric_server_role.server_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_server_role) | resource |
| [intersight_fabric_switch_cluster_profile.domain_profile](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_switch_cluster_profile) | resource |
| [intersight_fabric_switch_cluster_profile_template.domain_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_switch_cluster_profile_template) | resource |
| [intersight_fabric_switch_control_policy.switch_control_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_switch_control_policy) | resource |
| [intersight_fabric_switch_profile.domain_switch_profile](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_switch_profile) | resource |
| [intersight_fabric_switch_profile_template.domain_switch_profile_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_switch_profile_template) | resource |
| [intersight_fabric_system_qos_policy.system_qos_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_system_qos_policy) | resource |
| [intersight_fabric_uplink_pc_role.uplink_pc_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_uplink_pc_role) | resource |
| [intersight_fabric_uplink_role.uplink_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_uplink_role) | resource |
| [intersight_fabric_vlan.vlan](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_vlan) | resource |
| [intersight_fabric_vsan.vsan](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_vsan) | resource |
| [intersight_fcpool_pool.wwnn_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fcpool_pool) | resource |
| [intersight_fcpool_pool.wwpn_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fcpool_pool) | resource |
| [intersight_firmware_policy.firmware_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/firmware_policy) | resource |
| [intersight_iam_end_point_user.local_user](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/iam_end_point_user) | resource |
| [intersight_iam_end_point_user_policy.local_user_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/iam_end_point_user_policy) | resource |
| [intersight_iam_end_point_user_role.local_user_role](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/iam_end_point_user_role) | resource |
| [intersight_iam_ldap_group.ldap_group](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/iam_ldap_group) | resource |
| [intersight_iam_ldap_policy.ldap_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/iam_ldap_policy) | resource |
| [intersight_iam_ldap_provider.ldap_provider](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/iam_ldap_provider) | resource |
| [intersight_ipmioverlan_policy.ipmi_over_lan_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/ipmioverlan_policy) | resource |
| [intersight_ippool_pool.ip_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/ippool_pool) | resource |
| [intersight_iqnpool_pool.iqn_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/iqnpool_pool) | resource |
| [intersight_kvm_policy.virtual_kvm_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/kvm_policy) | resource |
| [intersight_macpool_pool.mac_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/macpool_pool) | resource |
| [intersight_networkconfig_policy.network_connectivity_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/networkconfig_policy) | resource |
| [intersight_ntp_policy.ntp_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/ntp_policy) | resource |
| [intersight_power_policy.power_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/power_policy) | resource |
| [intersight_resourcepool_pool.resource_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/resourcepool_pool) | resource |
| [intersight_server_profile.server_profile](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/server_profile) | resource |
| [intersight_server_profile_template.server_profile_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/server_profile_template) | resource |
| [intersight_smtp_policy.smtp_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/smtp_policy) | resource |
| [intersight_snmp_policy.snmp_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/snmp_policy) | resource |
| [intersight_sol_policy.serial_over_lan_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/sol_policy) | resource |
| [intersight_ssh_policy.ssh_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/ssh_policy) | resource |
| [intersight_storage_drive_group.storage_drive_group](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/storage_drive_group) | resource |
| [intersight_storage_drive_security_policy.drive_security_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/storage_drive_security_policy) | resource |
| [intersight_storage_storage_policy.storage_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/storage_storage_policy) | resource |
| [intersight_syslog_policy.syslog_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/syslog_policy) | resource |
| [intersight_thermal_policy.thermal_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/thermal_policy) | resource |
| [intersight_uuidpool_pool.uuid_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/uuidpool_pool) | resource |
| [intersight_vmedia_policy.virtual_media_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vmedia_policy) | resource |
| [intersight_vnic_eth_adapter_policy.ethernet_adapter_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_eth_adapter_policy) | resource |
| [intersight_vnic_eth_if.vnic_eth_if](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_eth_if) | resource |
| [intersight_vnic_eth_network_policy.ethernet_network_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_eth_network_policy) | resource |
| [intersight_vnic_eth_qos_policy.ethernet_qos_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_eth_qos_policy) | resource |
| [intersight_vnic_fc_adapter_policy.fibre_channel_adapter_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_fc_adapter_policy) | resource |
| [intersight_vnic_fc_if.vnic_fc_if](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_fc_if) | resource |
| [intersight_vnic_fc_network_policy.fibre_channel_network_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_fc_network_policy) | resource |
| [intersight_vnic_fc_qos_policy.fibre_channel_qos_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_fc_qos_policy) | resource |
| [intersight_vnic_iscsi_adapter_policy.iscsi_adapter_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_iscsi_adapter_policy) | resource |
| [intersight_vnic_iscsi_boot_policy.iscsi_boot_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_iscsi_boot_policy) | resource |
| [intersight_vnic_iscsi_static_target_policy.iscsi_static_target_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_iscsi_static_target_policy) | resource |
| [intersight_vnic_lan_connectivity_policy.lan_connectivity_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_lan_connectivity_policy) | resource |
| [intersight_vnic_san_connectivity_policy.san_connectivity_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_san_connectivity_policy) | resource |
| [intersight_vnic_vhba_template.vhba_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_vhba_template) | resource |
| [intersight_vnic_vnic_template.vnic_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_vnic_template) | resource |
| [local_sensitive_file.defaults](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [terraform_data.validation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [intersight_access_policy.imc_access_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/access_policy) | data source |
| [intersight_adapter_config_policy.adapter_configuration_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/adapter_config_policy) | data source |
| [intersight_bios_policy.bios_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/bios_policy) | data source |
| [intersight_boot_precision_policy.boot_precision_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/boot_precision_policy) | data source |
| [intersight_certificatemanagement_policy.certificate_management_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/certificatemanagement_policy) | data source |
| [intersight_chassis_profile_template.chassis_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/chassis_profile_template) | data source |
| [intersight_compute_physical_summary.server](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/compute_physical_summary) | data source |
| [intersight_compute_scrub_policy.scrub_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/compute_scrub_policy) | data source |
| [intersight_deviceconnector_policy.device_connector_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/deviceconnector_policy) | data source |
| [intersight_fabric_eth_network_control_policy.ethernet_network_control_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_eth_network_control_policy) | data source |
| [intersight_fabric_eth_network_group_policy.ethernet_network_group_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_eth_network_group_policy) | data source |
| [intersight_fabric_eth_network_policy.vlan_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_eth_network_policy) | data source |
| [intersight_fabric_fc_network_policy.vsan_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_fc_network_policy) | data source |
| [intersight_fabric_fc_zone_policy.fc_zone_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_fc_zone_policy) | data source |
| [intersight_fabric_port_policy.port_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_port_policy) | data source |
| [intersight_fabric_switch_cluster_profile_template.domain_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_switch_cluster_profile_template) | data source |
| [intersight_fabric_switch_control_policy.switch_control_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_switch_control_policy) | data source |
| [intersight_fabric_system_qos_policy.system_qos_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fabric_system_qos_policy) | data source |
| [intersight_fcpool_pool.wwpn_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/fcpool_pool) | data source |
| [intersight_firmware_policy.firmware_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/firmware_policy) | data source |
| [intersight_iam_end_point_user_policy.local_user_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/iam_end_point_user_policy) | data source |
| [intersight_iam_ldap_policy.ldap_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/iam_ldap_policy) | data source |
| [intersight_ipmioverlan_policy.ipmi_over_lan_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/ipmioverlan_policy) | data source |
| [intersight_ippool_pool.ip_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/ippool_pool) | data source |
| [intersight_kvm_policy.virtual_kvm_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/kvm_policy) | data source |
| [intersight_macpool_pool.mac_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/macpool_pool) | data source |
| [intersight_network_element_summary.fi](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/network_element_summary) | data source |
| [intersight_networkconfig_policy.network_connectivity_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/networkconfig_policy) | data source |
| [intersight_ntp_policy.ntp_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/ntp_policy) | data source |
| [intersight_organization_organization.organizations](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/organization_organization) | data source |
| [intersight_power_policy.power_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/power_policy) | data source |
| [intersight_resourcepool_pool.resource_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/resourcepool_pool) | data source |
| [intersight_server_profile_template.server_profile_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/server_profile_template) | data source |
| [intersight_smtp_policy.smtp_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/smtp_policy) | data source |
| [intersight_snmp_policy.snmp_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/snmp_policy) | data source |
| [intersight_sol_policy.serial_over_lan_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/sol_policy) | data source |
| [intersight_ssh_policy.ssh_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/ssh_policy) | data source |
| [intersight_storage_drive_security_policy.drive_security_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/storage_drive_security_policy) | data source |
| [intersight_storage_storage_policy.storage_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/storage_storage_policy) | data source |
| [intersight_syslog_policy.syslog_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/syslog_policy) | data source |
| [intersight_thermal_policy.thermal_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/thermal_policy) | data source |
| [intersight_uuidpool_pool.uuid_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/uuidpool_pool) | data source |
| [intersight_vmedia_policy.virtual_media_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vmedia_policy) | data source |
| [intersight_vnic_eth_adapter_policy.ethernet_adapter_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_eth_adapter_policy) | data source |
| [intersight_vnic_eth_network_policy.ethernet_network_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_eth_network_policy) | data source |
| [intersight_vnic_eth_qos_policy.ethernet_qos_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_eth_qos_policy) | data source |
| [intersight_vnic_fc_adapter_policy.fibre_channel_adapter_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_fc_adapter_policy) | data source |
| [intersight_vnic_fc_network_policy.fibre_channel_network_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_fc_network_policy) | data source |
| [intersight_vnic_fc_qos_policy.fibre_channel_qos_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_fc_qos_policy) | data source |
| [intersight_vnic_iscsi_adapter_policy.iscsi_adapter_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_iscsi_adapter_policy) | data source |
| [intersight_vnic_iscsi_boot_policy.iscsi_boot_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_iscsi_boot_policy) | data source |
| [intersight_vnic_iscsi_static_target_policy.iscsi_static_target_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_iscsi_static_target_policy) | data source |
| [intersight_vnic_lan_connectivity_policy.lan_connectivity_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_lan_connectivity_policy) | data source |
| [intersight_vnic_san_connectivity_policy.san_connectivity_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_san_connectivity_policy) | data source |
| [intersight_vnic_vhba_template.vhba_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_vhba_template) | data source |
| [intersight_vnic_vnic_template.vnic_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/vnic_vnic_template) | data source |

## Modules

No modules.
<!-- END_TF_DOCS -->