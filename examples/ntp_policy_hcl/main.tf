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
