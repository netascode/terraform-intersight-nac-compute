module "ntp_policy" {
  source  = "netascode/nac-compute/intersight"
  version = ">= 0.2.0"

  manage_intersight_policies = true

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
