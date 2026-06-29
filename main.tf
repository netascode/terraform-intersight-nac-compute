locals {
  compute    = try(local.model.compute, {})
  intersight = try(local.compute.intersight, {})
}

provider "intersight" {
  endpoint = "https://intersight.com"
}

