output "tgw_id" {
    value = aws_ec2_transit_gateway.this.id
}

output "tgw_arn" {
    value = aws_ec2_transit_gateway.this.arn
}

output "tgw_cidr" {
    value = aws_ec2_transit_gateway.this.transit_gateway_cidr_blocks
}

output "tgw_asn" {
    value = aws_ec2_transit_gateway.this.amazon_side_asn
}

# output "tgw_rt_ids" {
#     value = aws_ec2_transit_gateway_route_table.this[*].*.id
# }

output "tgw_rt_ids" {
    value = [aws_ec2_transit_gateway_route_table.this[*].stg.id, aws_ec2_transit_gateway_route_table.this[*].cnc.id, aws_ec2_transit_gateway_route_table.this[*].prod.id, aws_ec2_transit_gateway_route_table.this[*].sbx.id] 
}

output "tgw_cnc_rt_id" {
    value = aws_ec2_transit_gateway_route_table.this[*].cnc.id
}

output "tgw_cnc_rt_arn" {
    value = aws_ec2_transit_gateway_route_table.this[*].cnc.arn
}

output "tgw_prod_rt_id" {
    value = aws_ec2_transit_gateway_route_table.this[*].prod.id
}

output "tgw_prod_rt_arn" {
    value = aws_ec2_transit_gateway_route_table.this[*].prod.arn
}

output "tgw_stg_rt_id" {
    value = aws_ec2_transit_gateway_route_table.this[*].stg.id
}

output "tgw_stg_rt_arn" {
    value = aws_ec2_transit_gateway_route_table.this[*].stg.arn
}

output "tgw_sbx_rt_id" {
    value =  aws_ec2_transit_gateway_route_table.this[*].sbx.id
}

output "tgw_sbx_rt_arn" {
    value = aws_ec2_transit_gateway_route_table.this[*].sbx.arn
}
