###############################################################
####### spoke cluster에만 구성
####### IRSA 만 생성 후, 자체생성
###############################################################
module "spoke_argocd_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  count = var.cluster_attr.info.type == "spoke" && var.cluster_attr.info.create ? 1 : 0  # Hub가 아닐 때만 생성

  role_name = "${var.cluster_attr.cluster_name}-argocd-spoke-access"

  # Hub 클러스터의 OIDC Provider 사용
  oidc_providers = {
    hub = {
      provider_arn               = var.cluster_attr.info.oidc_provider_arn
      namespace_service_accounts = [
        "argocd:argocd-application-controller",
        "argocd:argocd-server"
      ]
    }
  }

  role_policy_arns = {
    eks_access = aws_iam_policy.spoke_eks_access[0].arn
  }

  tags = {
    Name        = "${var.cluster_attr.cluster_name}-argocd-spoke-access"
    Environment = var.cluster_attr.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_policy" "spoke_eks_access" {
  count = var.cluster_attr.info.type == "spoke" && var.cluster_attr.info.create ? 1 : 0

  name        = "${var.cluster_attr.cluster_name}-argocd-spoke-eks-access"
  description = "Policy for ArgoCD to access Spoke EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = module.eks.cluster_arn
      }
    ]
  })
}

resource "local_file" "spoke_secret_yaml" {
    count = var.cluster_attr.info.type == "spoke" && var.cluster_attr.info.create ? 1 : 0

    filename = "./${var.cluster_attr.cluster_name}-spoke-cluster.yaml"

    content = <<-EOT
        apiVersion: v1
        kind: Secret
        metadata:
            name: ${var.cluster_attr.cluster_name}-spoke-cluster
            namespace: argocd
            labels:
                argocd.argoproj.io/secret-type: cluster
                environment: ${var.cluster_attr.environment}
            annotations:
                addons_repo_url: "${var.gitops_bridge_attr.addons_repo_url}"
                addons_repo_basepath: "${var.gitops_bridge_attr.addons_repo_basepath}"
                addons_repo_path: "${var.gitops_bridge_attr.addons_repo_path}"
                addons_repo_revision: "${var.gitops_bridge_attr.addons_repo_revision}"
                vpc_id: "${var.gitops_bridge_metadata.vpc_id}"
        type: Opaque
        stringData:
            name: ${var.cluster_attr.cluster_name}
            server: ${module.eks.cluster_endpoint}
            config: |
                {
                "awsAuthConfig": {
                    "clusterName": "${var.cluster_attr.cluster_name}",
                    "roleArn": "${module.spoke_argocd_irsa[0].iam_role_arn}"
                },
                "tlsClientConfig": {
                    "insecure": false,
                    "caData": "${module.eks.cluster_certificate_authority_data}"
                    }
                }
    EOT
}