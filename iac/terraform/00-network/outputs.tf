output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "app_subnet_ids" {
  description = "List of application subnet IDs"
  value       = module.vpc.app_subnet_ids
}

output "data_subnet_ids" {
  description = "List of data subnet IDs"
  value       = module.vpc.data_subnet_ids
}

output "eks_pod_subnet_ids" {
  description = "List of EKS pod subnet IDs"
  value       = module.vpc.eks_pod_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "public_route_table_id" {
  description = "ID of public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.vpc.private_route_table_ids
}
