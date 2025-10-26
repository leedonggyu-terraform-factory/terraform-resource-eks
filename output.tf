output "eks" {
  value = module.eks
}

output "blueprints" {
  value = module.blueprints
}

output "cluster_name" {
  value = var.cluster_attr.cluster_name
}

output "environment" {
  value = var.cluster_attr.environment
}