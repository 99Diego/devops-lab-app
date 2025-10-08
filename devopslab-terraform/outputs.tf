output "cluster_name" {
  description = "Nombre del clúster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del clúster"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group del clúster"
  value       = module.eks.cluster_security_group_id
}

