module "networking" {
  source = "../.."

  project_name = var.project_name
  client_name  = var.client_name
  environment  = "Development"
  region       = var.region

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  vpc_naming_convention = var.vpc_naming_convention

  subnet_types     = var.subnet_types
  subnets_per_type = var.subnets_per_type

  requires_internet_gateway = var.requires_internet_gateway
  enable_nat_gateway       = var.enable_nat_gateway
  enable_vpc_flow_logs     = var.enable_vpc_flow_logs
  enable_vpc_peering      = var.enable_vpc_peering
  custom_dhcp_options     = var.custom_dhcp_options

  dhcp_domain_name         = var.dhcp_domain_name
  dhcp_domain_name_servers = var.dhcp_domain_name_servers

  peer_vpc_id   = var.peer_vpc_id
  peer_vpc_cidr = var.peer_vpc_cidr
}