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
