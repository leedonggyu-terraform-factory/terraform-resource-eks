resource "null_resource" "eks_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_attr.cluster_name} --region ap-northeast-2"
  }

  depends_on = [module.eks, null_resource.eks_kubeconfig]
}

////////////////////////////////////////////////////// hub cluster //////////////////////////////////////////////////////
module "gitops-bridge" {
  count = var.cluster_attr.info.type == "hub" ? 1 : 0

  source = "gitops-bridge-dev/gitops-bridge/helm"
  // initial gitops-bridge
  // hub cluster에만 적용
  create = var.cluster_attr.info.create

  cluster = {
    cluster_name = var.cluster_attr.cluster_name
    environment  = try(var.cluster_attr.environment, "common")
    metadata = merge({
      addons_repo_url      = var.gitops_bridge_attr.addons_repo_url
      addons_repo_basepath = var.gitops_bridge_attr.addons_repo_basepath
      addons_repo_path     = var.gitops_bridge_attr.addons_repo_path
      addons_repo_revision = try(var.gitops_bridge_attr.addons_repo_revision, "main")
      kubernetes_version   = var.cluster_attr.cluster_version
    }, var.gitops_bridge_metadata),
    addons = merge(
      {
        for addon, bool in var.addons :
        addon => bool if addon != "external_dns_route53_zone_arns"
      },
    )
  }

  apps = {
    addons = templatefile("${path.module}/apps.yaml", {
      cluster_name = var.cluster_attr.cluster_name
      environment  = try(var.cluster_attr.environment, "common")
    })
  }

  depends_on = [null_resource.eks_kubeconfig]
}

###############################################################
####### hub cluster에만 구성
###############################################################
module "argocd_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  count = var.cluster_attr.info.type == "hub" ? 1 : 0

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
}

resource "aws_iam_policy" "irsa_policy" {
  count = var.cluster_attr.info.type == "hub" ? 1 : 0

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
}

# resource "kubernetes_manifest" "argo_app_project" {
#   count = var.cluster_attr.info.type == "hub" && var.cluster_attr.info.create ? 1 : 0

#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "AppProject"

#     metadata = {
#       name      = var.cluster_attr.environment == "prd" ? "${var.cluster_attr.cluster_name}" : "${var.cluster_attr.cluster_name}-${var.cluster_attr.environment}"
#       namespace = "argocd"
#     }

#     spec = {
#       description = "Project for ${var.cluster_attr.cluster_name}-${var.cluster_attr.environment} cluster"

#       # Git 저장소 허용 목록
#       sourceRepos = [
#         "${var.gitops_bridge_attr.addons_repo_url}.git",
#         "public.ecr.aws",
#         "*" # 필요에 따라 모든 저장소 허용 또는 제한
#       ]

#       # 배포 대상 허용 목록
#       destinations = [
#         {
#           namespace = "*"
#           server    = "*"
#         }
#       ]

#       # 클러스터 레벨 리소스 허용 목록
#       clusterResourceWhitelist = [
#         {
#           group = "*"
#           kind  = "*"
#         }
#       ]

#       # 네임스페이스 레벨 리소스 허용 목록
#       namespaceResourceWhitelist = [
#         {
#           group = "*"
#           kind  = "*"
#         }
#       ]

#       # RBAC 설정 (선택사항)
#       roles = [
#         {
#           name = "admin"
#           policies = [
#             "p, proj:${var.cluster_attr.cluster_name}-${var.cluster_attr.environment}:admin, applications, *, ${var.cluster_attr.cluster_name}-${var.cluster_attr.environment}/*, allow",
#             "p, proj:${var.cluster_attr.cluster_name}-${var.cluster_attr.environment}:admin, repositories, *, *, allow",
#           ]
#           groups = [
#             "argocd-admins"
#           ]
#         },
#         {
#           name = "readonly"
#           policies = [
#             "p, proj:${var.cluster_attr.cluster_name}-${var.cluster_attr.environment}:readonly, applications, get, ${var.cluster_attr.cluster_name}-${var.cluster_attr.environment}/*, allow",
#           ]
#           groups = [
#             "argocd-readonly"
#           ]
#         }
#       ]

#       # Sync 옵션 설정
#       syncWindows = [
#         {
#           kind         = "allow"
#           schedule     = "* * * * *"
#           duration     = "24h"
#           applications = ["*"]
#           manualSync   = true
#         }
#       ]
#     }
#   }

#   depends_on = [module.gitops-bridge, module.eks, null_resource.eks_kubeconfig]
# }