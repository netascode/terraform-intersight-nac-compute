<!-- BEGIN_TF_DOCS -->
# Terraform Compute Network-as-Code Module

A Terraform module to configure Compute (Intersight and UCS).

This module is part of the Cisco [*Network-as-Code*](https://netascode.cisco.com) project. Its goal is to allow users to instantiate network fabrics in minutes using an easy to use, opinionated data model. It takes away the complexity of having to deal with references, dependencies or loops. By completely separating data (defining variables) from logic (infrastructure declaration), it allows the user to focus on describing the intended configuration while using a set of maintained and tested Terraform Modules without the need to understand the low-level object model. More information can be found here: https://netascode.cisco.com.

## Usage

This module supports an inventory driven approach, where a complete compute configuration or parts of it are either modeled in one or more YAML files or natively using Terraform variables.

The full data model documentation is available here: https://netascode.cisco.com/docs/data_models/compute/overview/ 

## Examplest

To be added

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_intersight"></a> [intersight](#requirement\_intersight) | >= 1.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.3.0 |
| <a name="requirement_utils"></a> [utils](#requirement\_utils) | =2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_model"></a> [model](#input\_model) | As an alternative to YAML files, a native Terraform data structure can be provided. | `map(any)` | `{}` | no |
| <a name="input_write_default_values_file"></a> [write\_default\_values\_file](#input\_write\_default\_values\_file) | Write all default values to a YAML file. Value is a path pointing to the file to be created. | `string` | `""` | no |
| <a name="input_yaml_directories"></a> [yaml\_directories](#input\_yaml\_directories) | List of paths to YAML directories. | `list(string)` | `[]` | no |
| <a name="input_yaml_files"></a> [yaml\_files](#input\_yaml\_files) | List of paths to YAML files. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_default_values"></a> [default\_values](#output\_default\_values) | All default values. |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_intersight"></a> [intersight](#provider\_intersight) | 1.0.78 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.9.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [intersight_bios_policy.bios_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/bios_policy) | resource |
| [intersight_boot_precision_policy.boot_precision_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/boot_precision_policy) | resource |
| [intersight_fabric_eth_network_group_policy.ethernet_network_group_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/fabric_eth_network_group_policy) | resource |
| [intersight_ippool_pool.ip_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/ippool_pool) | resource |
| [intersight_macpool_pool.mac_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/macpool_pool) | resource |
| [intersight_server_profile_template.server_profile_template](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/server_profile_template) | resource |
| [intersight_uuidpool_pool.uuid_pool](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/uuidpool_pool) | resource |
| [intersight_vnic_eth_adapter_policy.ethernet_adapter_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_eth_adapter_policy) | resource |
| [intersight_vnic_eth_if.vnic_eth_if](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_eth_if) | resource |
| [intersight_vnic_eth_network_policy.ethernet_network_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_eth_network_policy) | resource |
| [intersight_vnic_eth_qos_policy.ethernet_qos_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_eth_qos_policy) | resource |
| [intersight_vnic_lan_connectivity_policy.lan_connectivity_policy](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/resources/vnic_lan_connectivity_policy) | resource |
| [local_sensitive_file.defaults](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [terraform_data.validation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [intersight_organization_organization.organizations](https://registry.terraform.io/providers/CiscoDevNet/intersight/latest/docs/data-sources/organization_organization) | data source |

## Modules

No modules.
<!-- END_TF_DOCS -->