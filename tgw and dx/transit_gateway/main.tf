terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    #   version = "~> 3.0"
      # configuration_aliases = [ aws.secondary ]
    }
  }
}

data "aws_organizations_organization" "this" {}

resource "aws_ec2_transit_gateway" "this" {
  amazon_side_asn = var.tgw_asn
  default_route_table_association = var.default_rt_assc
  default_route_table_propagation = var.default_rt_prop
  description = var.name
  dns_support = var.tgw_dns_support
  tags = merge({"Name" = format("%s", var.name)}, var.tags,)
  transit_gateway_cidr_blocks = length(var.tgw_cidr) > 0 ? var.tgw_cidr : null
  vpn_ecmp_support = var.vpn_ecmp_support

}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each = var.tgw_route_tables
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = merge({"Name" = format("%s-%s-route-table", var.name, each.value)},var.tags,)

}

resource "aws_ram_resource_share" "this" {
  name                      = "transit_gateway"
  allow_external_principals = false

  tags = merge({"Name" = format("%s-transit-gateway", var.name)}, var.tags,)
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}