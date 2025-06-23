resource "azurerm_network_security_rule" "predefined_rules" {
  count = var.use_for_each ? 0 : length(var.predefined_rules)

  name      = var.predefined_rules[count.index].name
  direction = element(var.rules[var.predefined_rules[count.index].name], 0)
  access    = element(var.rules[var.predefined_rules[count.index].name], 1)
  protocol  = element(var.rules[var.predefined_rules[count.index].name], 2)

  source_port_ranges      = split(",", tostring(element(var.rules[var.predefined_rules[count.index].name], 4)))
  destination_port_ranges = split(",", tostring(element(var.rules[var.predefined_rules[count.index].name], 6)))


  priority    = lookup(var.predefined_rules[count.index], "priority", var.base_priority + count.index)
  description = element(var.rules[var.predefined_rules[count.index].name], 7)

  # Source configuration
  source_application_security_group_ids = var.predefined_rules[count.index].source_application_security_group_ids
  source_address_prefixes = (
    var.predefined_rules[count.index].source_application_security_group_ids == null
    && length(split(",", element(var.rules[var.predefined_rules[count.index].name], 3))) > 0
  ) ? split(",", element(var.rules[var.predefined_rules[count.index].name], 3)) : null

  # Destination configuration
  destination_application_security_group_ids = var.predefined_rules[count.index].destination_application_security_group_ids
  destination_address_prefixes = (
    var.predefined_rules[count.index].destination_application_security_group_ids == null
    && length(split(",", element(var.rules[var.predefined_rules[count.index].name], 5))) > 0
  ) ? split(",", element(var.rules[var.predefined_rules[count.index].name], 5)) : null

  resource_group_name         = var.resource_group_name
  network_security_group_name = data.azurerm_network_security_group.sec_nsg.name
}

data "azurerm_network_security_group" "sec_nsg" {
  name                = var.nsg_name
  resource_group_name = var.resource_group_name
}

variable "nsg_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "ncr-test"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "resource_group-App-NP"
}

variable "use_for_each" {
  description = "Enable use of for_each instead of count"
  type        = bool
  default     = false
}

variable "predefined_rules" {
  description = "List of predefined security rules"
  type = list(object({
    name                                       = string
    source_application_security_group_ids      = list(string)
    destination_application_security_group_ids = list(string)
  }))
}

variable "rules" {
  description = "Map of rule names to [direction, access, protocol, source_address_prefixes, source_port_ranges, destination_address_prefixes, destination_port_range, description]"
  type        = map(list(string))
}


variable "source_address_prefix" {
  description = "Single source address prefix (used when prefixes is null)"
  type        = list(string)
  default     = ["*"]
}

variable "source_address_prefixes" {
  description = "List of source address prefixes"
  type        = list(string)
  default     = []
}

variable "destination_address_prefix" {
  description = "Single destination address prefix (used when prefixes is null)"
  type        = list(string)
  default     = ["*"]
}

variable "destination_address_prefixes" {
  description = "List of destination address prefixes"
  type        = list(string)
  default     = []
}

variable "base_priority" {
  description = "The starting value for security rule priority"
  type        = number

}

base_priority = 100


predefined_rules = [
  {
    name                                       = "Rule1-IN"
    source_application_security_group_ids      = null
    destination_application_security_group_ids = null
  },
  {
    name                                       = "Rule2-IN"
    source_application_security_group_ids      = null
    destination_application_security_group_ids = null
  },
  {
    name                                       = "Rule1-OB"
    source_application_security_group_ids      = null
    destination_application_security_group_ids = null
  },
  {
    name                                       = "Rule2-OB"
    source_application_security_group_ids      = null
    destination_application_security_group_ids = null
  }
]

rules = {
  Rule1-IN = [
    "Inbound",
    "Allow",
    "*",
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24",
    "8080,22,443,3899",
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24",
    "22,8080",
    "llow with custom settings"
  ],
  Rule2-IN = [
    "Inbound",
    "Allow",
    "*",
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24",
    "8080,22,443,3899",
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24",
    "22,8080",
    "Allow with custom settings"
  ],
  Rule1-OB = [
    "Outbound",
    "Allow",
    "*",
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24",
    "8080,22,443,3899",
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24",
    "22,8080",
    "Allow HTTP custom settings"
  ]

  Rule2-OB = [
    "Outbound",
    "Allow",
    "*",
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24",
    "8080,22,443,3899",
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24",
    "22,8080",
    "Allow HTTP custom settings"
  ]
}
