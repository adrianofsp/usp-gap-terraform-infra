output "az" {
  description = "Output the zone_ids available on current region"
  value       = slice(sort(data.aws_availability_zones.available.names), 0, var.zone_numbers)
}

output "name" {
  value = module.dynamic-subnets
}
