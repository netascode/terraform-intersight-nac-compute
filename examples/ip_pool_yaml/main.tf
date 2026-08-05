module "ip_pool" {
  source  = "netascode/nac-compute/compute"
  version = ">= 0.1.0"

  yaml_files = ["ip_pool.yaml"]
}
