# variable "access_key" {}

# variable "secret_key" {}

variable "tgw_id" {}

variable "tgw_route_table_security" {}

variable "tgw_route_table_network" {}

variable "tgw_enable" {
    default = true
}

variable "name" {
    default = "production"
}

variable "tgw_rt_name" {
    default = "stg"
}

variable "tags" {
    default = {
    Terraform = "true"
    Environment = "production"
  }
}