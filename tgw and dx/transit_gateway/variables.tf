variable "tgw_asn" {
    description = "Amazon side ASN for Transit Gateway"
    default = "64512"
}

variable "default_rt_assc" {
    description = "Automatically associate default route table with attachments."
    default = "disable"
}

variable "tgw_route_tables" {
    description = "List of route transit gateway route table names"
    default = ["cnc", "prod", "stg", "sbx"]
}

variable "default_rt_prop" {
    description = "Automatically propagate default route table with attachments."
    default = "disable"
}

variable "name" {
    description = "Unique name used to identify resources related to this module."
    default = ""
}

variable "tgw_dns_support" {
    description = "Whether or not DNS support is enabled"
    default = "disable"
}

variable "tags" {}

variable "tgw_cidr" {
    description = "Transit Gateway CIDR"
    default = []
}

variable "vpn_ecmp_support" {
    description = "Whether or not VPN ECMP support is enabled"
    default = "disable"
}

variable "security_vpc_attachment_id" {
    description = "Transit Gateway attachment id for security VPC."
    default = ""
}