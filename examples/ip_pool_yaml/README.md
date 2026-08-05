<!-- BEGIN_TF_DOCS -->
# IP Pool Example
To run this example you need to execute:
```bash
$ terraform init
$ terraform plan
$ terraform apply
```
Note that this example will create resources. Resources can be destroyed with `terraform destroy`.

This example assumes an Intersight organization named `default` already exists.

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
```
<!-- END_TF_DOCS -->