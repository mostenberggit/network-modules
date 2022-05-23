terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    #   version = "~> 3.0"
      # configuration_aliases = [ aws.secondary ]
    }
  }
}

resource "aws_dx_gateway" "this" {
  name            = var.dx_gw_name
  amazon_side_asn = var.dx_asn
}

resource "aws_dx_gateway_association" "this" {
  for_each = var.tgw_id
  dx_gateway_id         = aws_dx_gateway.this.id
  associated_gateway_id = each.value

  allow_prefixes = var.allowed_prefixes
}