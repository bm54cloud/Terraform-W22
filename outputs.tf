output "list_of_az" {
  value = data.aws_availability_zones.available-azs[*].names
}

output "public_subnet_id" {
    value = data.aws_subnets.public[*].ids
}

output "private_subnet_id" {
    value = data.aws_subnets.private[*].ids
}
# output "alb_dns_name" {
#   value = aws_lb.web-server-alb.dns_name
# }