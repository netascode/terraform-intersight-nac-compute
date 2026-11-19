module "ip_pool" {
  source  = "netascode/nac-compute/intersight"
  version = ">= 0.2.0"

  manage_intersight_pools = true

  yaml_files = ["ip_pool.yaml"]
}
