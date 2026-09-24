locals {
  compute    = try(local.model.compute, {})
  intersight = try(local.compute.intersight, {})
}
