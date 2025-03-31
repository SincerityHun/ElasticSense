output "configure_kubectl" {
    description = "Configure kubectl: set the kubeconfig context to the EKS cluster"
    value = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}" 
}

output "cluster_endpoint" {
    description = "The endpoint for the EKS Kubernetes"
    value = module.eks.cluster_endpoint
}

output "cluster_name" {
    description = "The name of the EKS cluster"
    value = var.cluster_name
}