variable "yaml_directories" {
  description = "List of paths to YAML directories."
  type        = list(string)
  default     = []
}

variable "yaml_files" {
  description = "List of paths to YAML files."
  type        = list(string)
  default     = []
}

variable "model" {
  description = "As an alternative to YAML files, a native Terraform data structure can be provided."
  type        = map(any)
  default     = {}
}

variable "write_default_values_file" {
  description = "Write all default values to a YAML file. Value is a path pointing to the file to be created."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Workspace scoping — category enable/disable flags
# All default to false (opt-in). Set to true in workspace tfvars to manage
# the corresponding resource category.
# ---------------------------------------------------------------------------

variable "manage_intersight_policies" {
  description = "When true, manage all policy resources under intersight.organizations[].policies."
  type        = bool
  default     = false
}

variable "manage_intersight_pools" {
  description = "When true, manage all pool resources under intersight.organizations[].pools."
  type        = bool
  default     = false
}

variable "manage_intersight_templates" {
  description = "When true, manage all template resources (server, domain, chassis)."
  type        = bool
  default     = false
}

variable "manage_intersight_profiles" {
  description = "When true, manage all profile resources (domain and chassis profiles)."
  type        = bool
  default     = false
}

variable "manage_servers" {
  description = "When true, manage server provisioning resources under servers[]."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Workspace scoping — object-group inclusion lists
# Empty list on both name list and tag list = include all objects.
# Name list and tag list are ORed. Multiple tag entries are ANDed.
# Tags are specified as "key=value" strings.
# ---------------------------------------------------------------------------

variable "managed_intersight_organizations" {
  description = "List of organization names to include. Empty = include all."
  type        = list(string)
  default     = []
}

variable "managed_intersight_organization_tags" {
  description = "Tag filters for org scoping. Use \"key=value\" for KeyValue tags or a bare path (e.g. \"datacenter/madrid\") for PathTag filters. PathTag filters match the exact path and any descendant (prefix match). All listed filters must match — AND semantics. Empty = include all."
  type        = list(string)
  default     = []
}

variable "managed_intersight_domains" {
  description = "List of domain profile names to include within filtered orgs. Empty = include all."
  type        = list(string)
  default     = []
}

variable "managed_intersight_domain_tags" {
  description = "Tag filters for domain profile scoping. Use \"key=value\" for KeyValue tags or a bare path (e.g. \"datacenter/madrid\") for PathTag filters. PathTag filters match the exact path and any descendant (prefix match). All listed filters must match — AND semantics. Empty = include all."
  type        = list(string)
  default     = []
}

variable "managed_intersight_chassis" {
  description = "List of chassis profile names to include within filtered orgs. Empty = include all."
  type        = list(string)
  default     = []
}

variable "managed_intersight_chassis_tags" {
  description = "Tag filters for chassis profile scoping. Use \"key=value\" for KeyValue tags or a bare path (e.g. \"datacenter/madrid\") for PathTag filters. PathTag filters match the exact path and any descendant (prefix match). All listed filters must match — AND semantics. Empty = include all."
  type        = list(string)
  default     = []
}

variable "managed_servers" {
  description = "List of server names to include. Empty = include all."
  type        = list(string)
  default     = []
}

variable "managed_server_tags" {
  description = "Tag filters for server scoping. Use \"key=value\" for KeyValue tags or a bare path (e.g. \"datacenter/madrid\") for PathTag filters. PathTag filters match the exact path and any descendant (prefix match). All listed filters must match — AND semantics. Empty = include all."
  type        = list(string)
  default     = []
}

