resource "null_resource" "eks_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_attr.cluster_name} --region ap-northeast-2"
  }

  depends_on = [module.eks]
}

////////////////////////////////////////////////////// hub cluster //////////////////////////////////////////////////////
module "gitops-bridge" {
    source = "gitops-bridge-dev/gitops-bridge/helm"   

    count = var.cluster_attr.hub ? 1 : 0

    // initial gitops-bridge
    // hub cluster에만 적용
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
          {
            for addon, bool in var.addons:
              addon => bool if addon != "external_dns_route53_zone_arns"
          },
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

  count = var.cluster_attr.hub ? 1 : 0

  role_name = "${var.cluster_attr.cluster_name}-argocd-hub-role"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["argocd:*"]
    }
  }

  role_policy_arns = {
    ArgoCD_EKS_Policy = aws_iam_policy.irsa_policy[0].arn
  }

  tags = {
    Name = "${var.cluster_attr.cluster_name}-argocd-hub-role"
  }

  depends_on = [null_resource.eks_kubeconfig]
}

resource "aws_iam_policy" "irsa_policy" {
  count = var.cluster_attr.hub ? 1 : 0

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

////////////////////////////////////////////////////// spoke cluster //////////////////////////////////////////////////////
resource "kubernetes_secret" "spoke_cluster_secret" {
  count = var.cluster_attr.hub ? 0 : 1
  
  metadata {
    name = "${var.cluster_attr.cluster_name}-cluster"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      "argocd.argoproj.io/spoke" = "true"
    }
  }

  data = {
    name = var.cluster_attr.cluster_name
    server = module.eks.cluster_endpoint
    config = jsonencode({
      awsAuthConfig = {
        clusterName = var.cluster_attr.cluster_name
        roleArn = module.argocd_irsa[0].iam_role_arn
      }
    })
  }
}