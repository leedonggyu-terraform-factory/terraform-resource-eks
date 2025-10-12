resource "null_resource" "eks_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_attr.cluster_name} --region ap-northeast-2"
  }

  depends_on = [module.eks]
}

module "gitops-bridge" {
    source = "gitops-bridge-dev/gitops-bridge/helm"   

    // initial gitops-bridge
    create = true

    cluster = {
        cluster_name = var.cluster_attr.cluster_name
        environment = try(var.cluster_attr.environment, "common")
        metadata = {
            addons_repo_url = var.gitops_bridge_attr.addons_repo_url
            addons_repo_basepath = var.gitops_bridge_attr.addons_repo_basepath
            addons_repo_path = var.gitops_bridge_attr.addons_repo_path
            addons_repo_revision = try(var.gitops_bridge_attr.addons_repo_revision, "main")
            kubernetes_version = var.cluster_attr.cluster_version
        },
        addons = merge(
            var.addons,
        )
    }

    apps = {
        addons = templatefile("${path.module}/apps.yaml", {
            cluster_name = var.cluster_attr.cluster_name
            environment = try(var.cluster_attr.environment, "common")
        })
    }

    depends_on = [null_resource.eks_kubeconfig]
}

module "argocd_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_attr.cluster_name}-argocd-hub-role"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["argocd:*"]
    }
  }

  role_policy_arns = {
    ArgoCD_EKS_Policy = aws_iam_policy.irsa_policy.arn
  }

  tags = {
    Name = "${var.cluster_attr.cluster_name}-argocd-hub-role"
  }

  depends_on = [null_resource.eks_kubeconfig]
}

resource "aws_iam_policy" "irsa_policy" {
  name        = "${var.cluster_attr.cluster_name}-argocd-irsa"
  description = "IRSA policy for ArgoCD"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Resource = "*"
      }
    ]
  })

  depends_on = [null_resource.eks_kubeconfig]
}