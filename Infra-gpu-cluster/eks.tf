module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64_GPU"
    instance_types = ["g4dn.12xlarge"]

    attach_cluster_primary_security_group = true
    vpc_security_group_ids                = []
  }

  # EKS Node Group
  eks_managed_node_groups = {
    gpu_nodes = {
      name = "gpu-node-group"

      min_size     = 2
      max_size     = 2
      desired_size = 2

      instance_types = ["g4dn.12xlarge"] # Has 4 GPUs per instance
      capacity_type  = "ON_DEMAND"

      # Use the NVIDIA device plugin for Kubernetes via labels and taints
      labels = {
        "accelerator" = "nvidia-tesla"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    }
  }

  # AWS AUTH conf
  manage_aws_auth_configmap = true
}
