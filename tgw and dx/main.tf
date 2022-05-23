terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    #   version = "~> 3.0"
    }
  }
}

provider "aws" {
    region = "us-west-2"

}

provider "aws" {
    region = "us-east-1"
    alias = "secondary"
}

data "aws_caller_identity" "primary" {}

data "aws_caller_identity" "secondary" {
    provider = aws.secondary
}

locals {
    vpc_cidr = "10.1.0.0/19"
    azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
    subnets = [for cidr_block in cidrsubnets(local.vpc_cidr, 1, 2, 5, 7) : cidrsubnets(cidr_block, 2, 2, 2)]
}

################################################################################
# Data Sources
################################################################################
data "aws_region" "secondary" {
    provider = aws.secondary
}

data "aws_ec2_transit_gateway" "this" {
    count = length(module.transit_gateway) > 0 ? 1 : 0
    depends_on = [module.transit_gateway]
    # filter {
    #     name   = "tag:Name"
    #     values = ["production"]
    # }
    filter {
        name  = "state"
        values = ["available"]
    }
}

data "aws_ec2_transit_gateway_route_table" "this" {
    count = length(module.transit_gateway) > 0 && var.tgw_rt_name != "cnc" ? 1 : 0
    depends_on = [module.transit_gateway]
    filter {
        name   = "tag:Name"
        values = [format("%s-%s-route-table", var.name, var.tgw_rt_name)]
    }
}

data "aws_ec2_transit_gateway_route_table" "cnc" {
    count = length(module.transit_gateway) > 0 && length(var.tgw_rt_name) > 0 ? 1 : 0
    depends_on = [module.transit_gateway]
    filter {
        name   = "tag:Name"
        values = [format("%s-cnc-route-table", var.name)]
    }
}

################################################################################
# Modules
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.subnets[0]
  public_subnets  = local.subnets[2]
  database_subnets = local.subnets[1]
  intra_subnet_suffix = "tgw"
  intra_subnets = local.subnets[3]

  enable_nat_gateway = false

  tags = var.tags
}

module "transit_gateway" {
    source = "./transit_gateway"
    name = "production"
    tgw_route_tables = toset(["cnc", "prod", "stg", "sbx"])
    tags = var.tags
}

module "transit_gateway_secondary" {
    source = "./transit_gateway"
    name = "production"
    tgw_route_tables = toset(["cnc", "prod", "stg", "sbx"])
    tags = var.tags
    providers = {
        aws = aws.secondary
    }
}


################################################################################
# Transit Gateway Inter-region Peering
################################################################################


resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  count = length(module.transit_gateway) > 0 && length(module.transit_gateway_secondary) > 0 ? 1 : 0
  peer_account_id         = data.aws_caller_identity.secondary.account_id
  peer_region             = data.aws_region.secondary.name
  peer_transit_gateway_id = module.transit_gateway_secondary.tgw_id
  transit_gateway_id      = module.transit_gateway.tgw_id

  tags = var.tags
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "this" {
  count = length(module.transit_gateway) > 0 && length(module.transit_gateway_secondary) > 0 ? 1 : 0
  provider = aws.secondary
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.this[0].id
  tags = var.tags
}

################################################################################
# Transit Gateway attachment
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
#   provider = aws.network
  count                 = length(module.transit_gateway) > 0 && length(module.vpc) > 0 ? 1 : 0
  subnet_ids            = module.vpc.intra_subnets
  transit_gateway_id    = data.aws_ec2_transit_gateway.this[0].id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  vpc_id                = module.vpc.vpc_id
  tags = merge({"Name" = format("%s", var.name)}, var.tags,)
}

# resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "this" {
#   count = length(module.transit_gateway) > 0 && length(module.vpc) > 0 ? 1 : 0
#   transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.this[0].id 
#   transit_gateway_default_route_table_association = false
#   transit_gateway_default_route_table_propagation = false
#   tags = merge({"Name" = format("%s", var.name)}, var.tags,)
# }


################################################################################
# Transit Gateway Route Table Routes
################################################################################

resource "aws_ec2_transit_gateway_route" "this" {
  for_each = toset(flatten([module.transit_gateway.tgw_cnc_rt_id, module.transit_gateway.tgw_sbx_rt_id, module.transit_gateway.tgw_prod_rt_id, module.transit_gateway.tgw_stg_rt_id]))
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = each.value
}

################################################################################
# Transit Gateway Route table association and propagation
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "cnc" {
  count = length(var.tgw_rt_name) > 0 ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.cnc[0].id
}

resource "aws_ec2_transit_gateway_route_table_association" "cnc" {
  count = var.tgw_rt_name == "cnc" ?  1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.cnc[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  count = var.tgw_rt_name != "cnc" ?  1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.this[0].id
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count = var.tgw_rt_name != "cnc" ?  1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.this[0].id
}