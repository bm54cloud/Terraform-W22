#List of available availability zones in given region
output "list_of_az" {
  value = data.aws_availability_zones.available-azs[*].names
}

#List of public subnet IDs
output "public_subnet_id" {
  value = data.aws_subnets.public[*].ids
}

#List of private subnet IDs
output "private_subnet_id" {
  value = data.aws_subnets.private[*].ids
}

# #IPv4 address of public instances
# output "public-IP" {
#   value = aws_instance.web-server.*.public_ips
#   # value = "${join(",", aws_instance.web-server.*.public_ip)}"
# }

#DB instance address
output "db-address" {
    value = aws_db_instance.mysql.address
}

# output "alb_dns_name" {
#   value = aws_lb.web-server-alb.dns_name
# }