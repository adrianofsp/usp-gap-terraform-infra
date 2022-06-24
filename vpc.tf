module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "1.1.0"

  namespace                                 = var.namespace
  stage                                     = var.stage
  name                                      = "vpc"
  cidr_block                                = var.vpc_cidr_block[terraform.workspace]
  internet_gateway_enabled                  = true
  assign_generated_ipv6_cidr_block          = false
  ipv6_egress_only_internet_gateway_enabled = false
  dns_hostnames_enabled                     = true
  dns_support_enabled                       = true

  context = module.this.context
}

module "dynamic-subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.0.2"

  namespace                               = var.namespace
  stage                                   = var.stage
  name                                    = "subnet"
  availability_zones                      = slice(sort(data.aws_availability_zones.available.names), 0, var.zone_numbers)
  vpc_id                                  = module.vpc.vpc_id
  igw_id                                  = [module.vpc.igw_id]
  ipv4_enabled                            = true
  ipv4_private_instance_hostnames_enabled = true
  ipv4_public_instance_hostnames_enabled  = true
  ipv4_cidr_block                         = [module.vpc.vpc_cidr_block]
  ipv6_enabled                            = false
  nat_gateway_enabled                     = false
  nat_instance_enabled                    = false
  aws_route_create_timeout                = "5m"
  aws_route_delete_timeout                = "10m"

  context = module.this.context
}