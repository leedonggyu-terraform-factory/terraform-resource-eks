/////////////////////////////////// User
// AmazonEKSClusterAdminPolicy
resource "aws_eks_access_entry" "user_access_entry" {
    for_each = {
        for i, arn in var.acess_entries_user.AmazonEKSClusterAdminPolicy:
        arn => arn
    }

    cluster_name = var.cluster_attr.cluster_name
    principal_arn = each.key
    kubernetes_groups = []
    type = "STANDARD"
}

resource "aws_eks_access_policy_association" "user_access_policy_association" {
    for_each = {
        for i, arn in var.acess_entries_user.AmazonEKSClusterAdminPolicy:
        arn => arn
    }

  cluster_name = var.cluster_attr.cluster_name
  principal_arn = each.key
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}


/////////////////////////////////// Service
// EC_LINUX
resource "aws_eks_access_entry" "service_node_access_entry" {
    for_each = {
        for i, arn in var.acess_entries_role.EC2_LINUX:
        arn => arn
    }

    cluster_name = var.cluster_attr.cluster_name
    principal_arn = each.key
    type = "EC2_LINUX" 
}

resource "aws_eks_access_entry" "karpenter_node_access_entry" {
    cluster_name = var.cluster_attr.cluster_name
    principal_arn = module.eks.blueprints["management"].karpenter.node_iam_role_arn # Node Role!
    type = "EC2_LINUX" 
}