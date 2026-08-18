locals {
  # ---------------------------------------------------------------------------
  # Tag-match helper — evaluates whether an object's tags satisfy all filters.
  # filter_tags: list of "key=value" strings (all must match — AND semantics)
  # obj_tags:    list of {key, value} objects from the data model
  # Returns true when filter_tags is empty OR every filter tag is found in obj_tags.
  # ---------------------------------------------------------------------------
  _tag_filter_intersight_orgs = [
    for t in var.managed_intersight_organization_tags :
    { key = split("=", t)[0], value = split("=", t)[1] }
  ]
  _tag_filter_intersight_domains = [
    for t in var.managed_intersight_domain_tags :
    { key = split("=", t)[0], value = split("=", t)[1] }
  ]
  _tag_filter_intersight_chassis = [
    for t in var.managed_intersight_chassis_tags :
    { key = split("=", t)[0], value = split("=", t)[1] }
  ]
  _tag_filter_servers = [
    for t in var.managed_server_tags :
    { key = split("=", t)[0], value = split("=", t)[1] }
  ]

  # ---------------------------------------------------------------------------
  # filtered_intersight_organizations — orgs that pass the name/tag filters.
  # An org is included when:
  #   - both lists are empty (include all), OR
  #   - its name is in managed_intersight_organizations, OR
  #   - it carries ALL tags in managed_intersight_organization_tags
  # ---------------------------------------------------------------------------
  filtered_intersight_organizations = [
    for org in try(local.intersight.organizations, []) : org
    if(
      length(var.managed_intersight_organizations) == 0
      && length(var.managed_intersight_organization_tags) == 0
      ) || contains(var.managed_intersight_organizations, org.name
      ) || (
      length(local._tag_filter_intersight_orgs) > 0
      && alltrue([
        for tf in local._tag_filter_intersight_orgs :
        anytrue([for ot in try(org.tags, []) : ot.key == tf.key && ot.value == tf.value])
      ])
    )
  ]

  # ---------------------------------------------------------------------------
  # filtered_servers — servers that pass the name/tag filters.
  # ---------------------------------------------------------------------------
  filtered_servers = [
    for s in try(local.compute.servers, []) : s
    if(
      length(var.managed_servers) == 0
      && length(var.managed_server_tags) == 0
      ) || contains(var.managed_servers, s.name
      ) || (
      length(local._tag_filter_servers) > 0
      && alltrue([
        for tf in local._tag_filter_servers :
        anytrue([for st in try(s.tags, []) : st.key == tf.key && st.value == tf.value])
      ])
    )
  ]
}
