<!-- BEGIN_TF_DOCS -->
# NTP Policy Example
To run this example you need to execute:
```bash
$ terraform init
$ terraform plan
$ terraform apply
```
Note that this example will create resources. Resources can be destroyed with `terraform destroy`.

This example assumes an Intersight organization named `default` already exists.

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
```
<!-- END_TF_DOCS -->