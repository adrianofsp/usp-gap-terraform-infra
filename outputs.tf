output "az" {
  description = "Output the zone_ids available on current region"
  value       = slice(sort(data.aws_availability_zones.available.names), 0, var.zone_numbers)
}

output "name" {
  value = module.dynamic-subnets
}

# output "container_definition" {
#   value = module.container_definition.json_map_object
# }