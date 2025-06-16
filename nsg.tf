resource "azurerm_network_security_rule" "predefined_rules" {
  count = var.use_for_each ? 0 : length(var.predefined_rules)

  name      = var.predefined_rules[count.index].name
  direction = element(var.rules[var.predefined_rules[count.index].name], 0)
  access    = element(var.rules[var.predefined_rules[count.index].name], 1)
  protocol  = element(var.rules[var.predefined_rules[count.index].name], 2)

  source_port_ranges      = split(",", tostring(element(var.rules[var.predefined_rules[count.index].name], 4)))
  destination_port_ranges = [element(var.rules[var.predefined_rules[count.index].name], 6)]

  priority    = lookup(var.predefined_rules[count.index], "priority", 4096 - length(var.predefined_rules) + count.index)
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
    source_port_range                          = optional(string)
    priority                                   = optional(number)
    source_application_security_group_ids      = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
  }))
  default = [
    {
      name                                       = "Rule1"
      source_port_range                          = "*"
      priority                                   = 100
      source_application_security_group_ids      = null
      destination_application_security_group_ids = null
    }
    # {
    #   name                                       = "Rule2"
    #   source_port_range                          = "*"
    #   priority                                   = 110
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule3"
    #   source_port_range                          = "*"
    #   priority                                   = 115
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule4"
    #   source_port_range                          = "*"
    #   priority                                   = 120
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule5"
    #   source_port_range                          = "*"
    #   priority                                   = 125
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule6"
    #   source_port_range                          = "*"
    #   priority                                   = 100
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule7"
    #   source_port_range                          = "*"
    #   priority                                   = 105
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule8"
    #   source_port_range                          = "*"
    #   priority                                   = 110
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule9"
    #   source_port_range                          = "*"
    #   priority                                   = 115
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule10"
    #   source_port_range                          = "*"
    #   priority                                   = 120
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule11"
    #   source_port_range                          = "*"
    #   priority                                   = 300
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # },
    # {
    #   name                                       = "Rule12"
    #   source_port_range                          = "*"
    #   priority                                   = 300
    #   source_application_security_group_ids      = null
    #   destination_application_security_group_ids = null
    # }

  ]
}

variable "rules" {
  description = "Map of rule names to [direction, access, protocol, unused, destination_port_range, description]"
  type        = map(list(string))
  default = {
    Rule1 = [
      "Inbound",                        # direction
      "Allow",                          # access
      "Tcp",                            # protocol
      "10.0.2.0/24,10.0.1.0/24",        # ✅ source_address_prefixes as a single comma-separated string
      "8080,22",                        # ✅ source_port_ranges
      "10.0.4.0/24",                    # destination_address_prefixes
      "25",                             # destination_port_range
      "Allow HTTP with custom settings" # description
    ]

    # Rule2  = ["Inbound", "Allow", "Tcp", "*", "443", "Allow HTTPS"]
    # Rule3  = ["Inbound", "Deny", "*", "*", "*", "Deny All"]
    # Rule4  = ["Inbound", "Allow", "Tcp", "*", "22", "Allow SSH"]
    # Rule5  = ["Inbound", "Allow", "Tcp", "*", "3389", "Allow RDP"]
    # Rule11 = ["Inbound", "Allow", "Tcp", "*", "1433", "Allow SQL"]


    # Rule6  = ["Outbound", "Allow", "Tcp", "*", "80", "Allow HTTP Out"]
    # Rule7  = ["Outbound", "Allow", "Tcp", "*", "443", "Allow HTTPS Out"]
    # Rule8  = ["Outbound", "Allow", "Udp", "*", "53", "Allow DNS Out"]
    # Rule9  = ["Outbound", "Allow", "Udp", "*", "123", "Allow NTP Out"]
    # Rule10 = ["Outbound", "Allow", "Tcp", "*", "1433", "Allow SQL Out"]
    # Rule12 = ["Outbound", "Deny", "*", "*", "*", "Deny All Out"]
  }
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

# variable "common_source_prefixes" {
#   description = "Common source address prefixes used in multiple rules"
#   type        = string
#   default     = "10.0.2.0/24,10.0.1.0/24"
# }

# variable "common_source_ports" {
#   description = "Common source ports"
#   type        = string
#   default     = "8080,22"
# }
