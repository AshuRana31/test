project_name = "project-xyz"
client_name  = "example-client"
region       = "ap-southeast-2"

vpc_cidr             = "10.2.0.0/20"
availability_zones   = ["ap-southeast-2a", "ap-southeast-2b"]
vpc_naming_convention = "${client}-${env}-${region}"

subnet_types     = ["public", "private"]
subnets_per_type = 2

requires_internet_gateway = true
enable_nat_gateway       = true
enable_vpc_flow_logs     = true
enable_vpc_peering      = false
custom_dhcp_options     = false

dhcp_domain_name         = "prod.example.internal"
dhcp_domain_name_servers = ["AmazonProvidedDNS"]

peer_vpc_id   = ""
peer_vpc_cidr = ""