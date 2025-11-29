##################################################################
#### EKS Cluster 
##################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                   = var.cluster_attr.cluster_name
  cluster_version                = try(var.cluster_attr.cluster_version, "1.34") ## 2025.11.29
  cluster_endpoint_public_access = try(var.cluster_attr.cluster_endpoint_public_access, true)

  cluster_addons = try(var.cluster_attr.cluster_addons, {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  })

  enable_cluster_creator_admin_permissions = var.cluster_attr.enable_cluster_creator_admin_permissions
  authentication_mode                      = "API"

  eks_managed_node_group_defaults = try(var.cluster_attr.eks_managed_node_group_defaults, {})
  eks_managed_node_groups         = try(var.cluster_attr.eks_managed_node_groups, {})
  cluster_compute_config          = try(var.cluster_attr.cluster_compute_config, {})

  vpc_id                   = try(var.cluster_attr.vpc_id, "")
  subnet_ids               = try(var.cluster_attr.worker_subnet_ids, [])
  control_plane_subnet_ids = try(var.cluster_attr.control_plane_subnet_ids, [])

  cluster_tags = merge(
    var.cluster_attr.cluster_tags,
    {
      "Computing" : "EKS"
    }
  )

  # other modules
  # access_entries = each.value.access_entries
  cluster_security_group_additional_rules = {
    "default" = {
      description = "Allow default traffic"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      type        = "ingress"
    }
  }

  cloudwatch_log_group_retention_in_days = try(var.cluster_attr.cloudwatch_log_group_retention_in_days, 3)
  create_node_security_group             = try(var.cluster_attr.create_node_security_group, true)
  tags                                   = var.cluster_attr.cluster_tags
}

##################################################################
#### EKS Access Entires 
##################################################################
resource "aws_eks_access_entry" "user_access_entry" {
  for_each = {
    for i, arn in var.access_entries_user.AmazonEKSClusterAdminPolicy :
    arn => arn
  }

  cluster_name      = var.cluster_attr.cluster_name
  principal_arn     = each.key
  kubernetes_groups = []
  type              = "STANDARD"

  depends_on = [module.eks, module.blueprints]
}

resource "aws_eks_access_policy_association" "user_access_policy_association" {
  for_each = {
    for i, arn in var.access_entries_user.AmazonEKSClusterAdminPolicy :
    arn => arn
  }

  cluster_name  = var.cluster_attr.cluster_name
  principal_arn = each.key
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [module.eks, module.blueprints]
}

##################################################################
#### EKS Service Node Access Entries 
##################################################################
resource "aws_eks_access_entry" "service_node_access_entry" {
  for_each = {
    for i, arn in [module.blueprints.karpenter.node_iam_role_arn] :
    i => arn
  }

  cluster_name  = var.cluster_attr.cluster_name
  principal_arn = each.value
  type          = "EC2_LINUX"

  depends_on = [module.eks, module.blueprints]
}
