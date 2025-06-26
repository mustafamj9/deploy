resource "azurerm_network_security_rule" "predefined_rules" {
  count = var.use_for_each ? 0 : length(var.predefined_rules)

  name      = var.predefined_rules[count.index].name
  direction = element(var.rules[var.predefined_rules[count.index].name], 0)
  access    = element(var.rules[var.predefined_rules[count.index].name], 1)
  protocol  = element(var.rules[var.predefined_rules[count.index].name], 2)

  # ✅ Precompute inline
  source_port_range = (
    trimspace(element(var.rules[var.predefined_rules[count.index].name], 4)) == "*"
    ? "*"
    : null
  )

  source_port_ranges = (
    trimspace(element(var.rules[var.predefined_rules[count.index].name], 4)) != "*"
    ? split(",", element(var.rules[var.predefined_rules[count.index].name], 4))
    : null
  )

  # ✅ Destination Port Handling
  destination_port_range = (
    trimspace(element(var.rules[var.predefined_rules[count.index].name], 6)) == "*"
    ? "*"
    : null
  )

  destination_port_ranges = (
    trimspace(element(var.rules[var.predefined_rules[count.index].name], 6)) != "*"
    ? split(",", element(var.rules[var.predefined_rules[count.index].name], 6))
    : null
  )

  priority    = local.rule_priority[count.index]
  description = element(var.rules[var.predefined_rules[count.index].name], 7)


  # ✅ Handle single source address prefix (e.g., "Any", "Internet", etc.)
  source_address_prefix = (
    var.predefined_rules[count.index].source_application_security_group_ids == null &&
    length(split(",", trimspace(element(var.rules[var.predefined_rules[count.index].name], 3)))) == 1
  ) ? trimspace(element(var.rules[var.predefined_rules[count.index].name], 3)) : null

  # ✅ Handle multiple source address prefixes
  source_address_prefixes = (
    var.predefined_rules[count.index].source_application_security_group_ids == null &&
    length(split(",", trimspace(element(var.rules[var.predefined_rules[count.index].name], 3)))) > 1
    ) ? [
    for p in split(",", element(var.rules[var.predefined_rules[count.index].name], 3)) :
    trimspace(p)
  ] : null


  destination_address_prefix = (
    var.predefined_rules[count.index].destination_application_security_group_ids == null &&
    length(split(",", trimspace(element(var.rules[var.predefined_rules[count.index].name], 5)))) == 1
  ) ? trimspace(element(var.rules[var.predefined_rules[count.index].name], 5)) : null

  destination_address_prefixes = (
    var.predefined_rules[count.index].destination_application_security_group_ids == null &&
    length(split(",", trimspace(element(var.rules[var.predefined_rules[count.index].name], 5)))) > 1
    ) ? [
    for p in split(",", element(var.rules[var.predefined_rules[count.index].name], 5)) :
    trimspace(p)
  ] : null

  source_application_security_group_ids = (
    contains(keys(var.predefined_rules[count.index]), "source_application_security_group_ids") && var.predefined_rules[count.index].source_application_security_group_ids != null
    ? var.predefined_rules[count.index].source_application_security_group_ids
    : local.default_asg_fields.source_application_security_group_ids
  )

  destination_application_security_group_ids = (
    contains(keys(var.predefined_rules[count.index]), "destination_application_security_group_ids") && var.predefined_rules[count.index].destination_application_security_group_ids != null
    ? var.predefined_rules[count.index].destination_application_security_group_ids
    : local.default_asg_fields.destination_application_security_group_ids
  )


  resource_group_name         = var.resource_group_name
  network_security_group_name = data.azurerm_network_security_group.sec_nsg.name

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
  type = list(object({
    name                                       = string
    priority                                   = optional(number)
    source_application_security_group_ids      = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
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

variable "inbound_base_priority" {
  description = "Base priority for inbound rules"
  type        = number
  default     = 100
}

variable "outbound_base_priority" {
  description = "Base priority for outbound rules"
  type        = number
  default     = 100
}

locals {
  rule_priority = [
    for idx, rule in var.predefined_rules :
    (
      contains(keys(rule), "priority") && rule.priority != null
      ? rule.priority
      : (
        element(var.rules[rule.name], 0) == "Inbound"
        ? var.inbound_base_priority + length([
          for j in slice(var.predefined_rules, 0, idx) :
          j if !(contains(keys(j), "priority") && j.priority != null) && element(var.rules[j.name], 0) == "Inbound"
        ])
        : var.outbound_base_priority + length([
          for j in slice(var.predefined_rules, 0, idx) :
          j if !(contains(keys(j), "priority") && j.priority != null) && element(var.rules[j.name], 0) == "Outbound"
        ])
      )
    )
  ]
}

locals {
  default_asg_fields = {
    source_application_security_group_ids      = null
    destination_application_security_group_ids = null
  }
}

base_priority = 100


predefined_rules = [
  { name = "Rule1-IN" },

  { name = "Rule2-IN" },

  {
    name = "Rule3-IN"
  }

  ,
  {
    name     = "Rule4-IN"
    priority = 4000

  },
  {
    name = "Rule1-OB"

  },
  {
    name = "Rule2-OB"

  },
  {
    name     = "Rule3-OB"
    priority = 3000

  },
  {
    name = "Rule4-OB"

  }
]

rules = {
  Rule1-IN = [
    "Inbound",                             # Direction: "Inbound" or "Outbound"
    "Allow",                               # Access: "Allow" or "Deny"
    "*",                                   # Source address prefixes (comma-separated) or * or service tag eg."VirtualNetwork"
    "*",                                   # Source address prefixes (comma-separated)
    "*",                                   # Source port range (can be "*", single port, or range)
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24", # Destination address prefixes (comma-separated) or * service tag eg."VirtualNetwork" 
    "3389",                                # Destination port range (e.g., "3389" for RDP)
    "Allow with custom settings"           # Description of the rule
  ],

  Rule2-IN = [
    "Inbound",                             # Direction: "Inbound" or "Outbound"
    "Allow",                               # Access: "Allow" or "Deny"
    "Tcp",                                 # Protocol: "Tcp", "Udp", or "*" for Any
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24", # Source address prefixes (comma-separated) or * or service tag eg."VirtualNetwork"
    "22,44,443,80",                        # Source port range (can be "*", single port, or range)
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24", # Destination address prefixes (comma-separated)
    "*",                                   # Destination address prefixes (comma-separated) or * service tag eg."VirtualNetwork" 
    "Allow with custom settings"           # Description of the rule
  ],
  Rule3-IN = [
    "Inbound",                             # Direction: "Inbound" or "Outbound"
    "Allow",                               # Access: "Allow" or "Deny"
    "Tcp",                                 # Protocol: "Tcp", "Udp", or "*" for Any
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24", # Source address prefixes (comma-separated) or * or service tag eg."VirtualNetwork"
    "88-99",                               # Source port range (can be "*", single port, or range)
    "*",                                   # Destination address prefixes (comma-separated) or * service tag eg."VirtualNetwork" 
    "3389,1433",                           # Destination port range (can be "*", single port, or range)
    "Allow with custom settings"           # Description of the rule
  ],
  Rule4-IN = [
    "Inbound",                          # Direction: "Inbound" or "Outbound"
    "Deny",                             # Access: "Allow" or "Deny"
    "*",                                # Protocol: "Tcp", "Udp", or "*" for Any
    "Internet",                         # Source address prefixes (comma-separated) or * or service tag eg."VirtualNetwork"
    "*",                                # Source port range (can be "*", single port, or range)
    "VirtualNetwork",                   # Destination address prefixes (comma-separated) or * service tag eg."VirtualNetwork" 
    "443",                              # Destination port range (can be "*", single port, or range)
    "Allow HTTPS from Internet to VNet" # Description of the rule
  ],
  Rule1-OB = [
    "Outbound",                            # Direction: "Inbound" or "Outbound"
    "Deny",                                # Access: "Allow" or "Deny"
    "Udp",                                 # Protocol: "Tcp", "Udp", or "*" for Any
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24", # Source address prefixes (comma-separated) or * or service tag eg."VirtualNetwork"
    "8080,22,443,3899",                    # Source port range (can be "*", single port, or range)
    "*",                                   # Destination address prefixes (comma-separated) or * service tag eg."VirtualNetwork" 
    "*",                                   # Destination port range (can be "*", single port, or range)
    "Allow HTTP custom settings"           # Description of the rule
  ],
  Rule2-OB = [
    "Outbound",                  # Direction: "Inbound" or "Outbound"
    "Allow",                     # Access: "Allow" or "Deny"
    "*",                         # Protocol: "Tcp", "Udp", or "*" for Any
    "AzureActiveDirectory",      # Source address prefixes (comma-separated) or * or service tag eg."VirtualNetwork"
    "8080,22,443,3899",          # Source port range (can be "*", single port, or range)
    "*",                         # Destination address prefixes (comma-separated) or * service tag eg."VirtualNetwork" 
    "22-8080",                   # Destination port range (can be "*", single port, or range)
    "Allow HTTP custom settings" # Description of the rule
  ],
  Rule3-OB = [
    "Outbound",                            # Direction: "Inbound" or "Outbound"
    "Allow",                               # Access: "Allow" or "Deny"
    "Tcp",                                 # Protocol: "Tcp", "Udp", or "*" for Any
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24", # Source address prefixes (comma-separated) or * or service tag eg."VirtualNetwork"
    "*",                                   # Source port range (can be "*", single port, or range)
    "AzureLoadBalancer",                   # Destination address prefixes (comma-separated) or * service tag eg."VirtualNetwork" 
    "22,8080",                             # Destination port range (can be "*", single port, or range)
    "Allow HTTP custom settings"           # Description of the rule
  ],
  Rule4-OB = [
    "Outbound",                            # Direction: "Inbound" or "Outbound"
    "Allow",                               # Access: "Allow" or "Deny"
    "Udp",                                 # Protocol: "Tcp", "Udp", or "*" for Any
    "AzureMonitor",                        # Source address prefixes (comma-separated) or * or service tag eg."VirtualNetwork"
    "88,44,99",                            # Source port range (can be "*", single port, or range)
    "10.0.2.0/24,10.0.1.0/24,10.0.4.0/24", # Destination address prefixes (comma-separated) or * service tag eg."VirtualNetwork" 
    "4",                                   # Destination port range (can be "*", single port, or range)
    "Allow HTTP custom settings"           # Description of the rule
  ]
}
