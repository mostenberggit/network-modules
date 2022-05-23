variable "dx_gw_name" {
    description = "Direct Connect Gateway name."
}

variable "dx_asn" {
    description = "Direct Connect Gateway ASN"
}

variable "tgw_id" {
    description = "List of transit gateway IDs to associate with Direct Connect Gateway."
}

variable "allowed_prefixes" {
    description = "Allowed prefixes to advertise over Direct Connect."
}