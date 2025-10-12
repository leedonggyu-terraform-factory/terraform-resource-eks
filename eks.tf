module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                   = var.cluster_attr.cluster_name
  cluster_version                = try(var.cluster_attr.cluster_version, "1.33") ## 2025.10.12
  cluster_endpoint_public_access = try(var.cluster_attr.cluster_endpoint_public_access, true)

  cluster_addons                           = try(var.cluster_attr.cluster_addons, {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  })

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  authentication_mode                      = "API"

  eks_managed_node_group_defaults = try(var.cluster_attr.eks_managed_node_group_defaults, {})
  eks_managed_node_groups         = try(var.cluster_attr.eks_managed_node_groups, {})
  cluster_compute_config          = try(var.cluster_attr.cluster_compute_config, {})

  vpc_id                   = try(var.cluster_attr.vpc_id, "")
  subnet_ids               = try(var.cluster_attr.private_subnet_ids, [])
  control_plane_subnet_ids = try(var.cluster_attr.private_subnet_ids, [])

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

module "blueprints" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = var.cluster_attr.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = var.cluster_attr.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  observability_tag = null

  // 실제 생성되진 않고 IAM 권한만 준비
  create_kubernetes_resources = false

  enable_cert_manager                 = var.addons.enable_cert_manager
  enable_aws_efs_csi_driver           = var.addons.enable_aws_efs_csi_driver
  enable_aws_cloudwatch_metrics       = var.addons.enable_aws_cloudwatch_metrics
  enable_external_dns                 = var.addons.enable_external_dns
  enable_external_secrets             = var.addons.enable_external_secrets
  enable_aws_load_balancer_controller = var.addons.enable_aws_load_balancer_controller
  enable_aws_for_fluentbit            = var.addons.enable_aws_for_fluentbit
  enable_karpenter                    = var.addons.enable_karpenter
  enable_metrics_server               = var.addons.enable_metrics_server
  enable_argo_rollouts                = var.addons.enable_argo_rollouts
  enable_cluster_autoscaler           = var.addons.enable_cluster_autoscaler
  external_dns_route53_zone_arns      = var.addons.external_dns_route53_zone_arns

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }

  cert_manager = var.addons.enable_cert_manager ? {
    role_name = "${var.cluster_attr.cluster_name}-cert-manager-role"
  } : {}

  aws_efs_csi_driver = var.addons.enable_aws_efs_csi_driver ? {
    role_name = "${var.cluster_attr.cluster_name}-efs-csi-driver-role"
  } : {}

  aws_cloudwatch_metrics = var.addons.enable_aws_cloudwatch_metrics ? {
    role_name = "${var.cluster_attr.cluster_name}-cloudwatch-metrics-role"
  } : {}

  external_dns = var.addons.enable_external_dns ? {
    role_name = "${var.cluster_attr.cluster_name}-external-dns-role"
  } : {}

  external_secrets = var.addons.enable_external_secrets ? {
    role_name = "${var.cluster_attr.cluster_name}-external-secrets-role"
  } : {}

  aws_load_balancer_controller = var.addons.enable_aws_load_balancer_controller ? {
    role_name = "${var.cluster_attr.cluster_name}-lb-controller-role"
  } : {}

  aws_for_fluentbit = var.addons.enable_aws_for_fluentbit ? {
    role_name = "${var.cluster_attr.cluster_name}-aws-for-fluentbit-role"
  } : {}

  karpenter = var.addons.enable_karpenter ? {
    role_name            = "${var.cluster_attr.cluster_name}-karpenter-role"
    role_name_use_prefix = false
  } : {}

  karpenter_node = var.addons.enable_karpenter ? {
    role_name             = "${var.cluster_attr.cluster_name}-karpenter-node-group-role"
    instance_profile_name = "${var.cluster_attr.cluster_name}-karpenter-node-group"
    role_name_use_prefix  = false
  } : {}

  karpenter_sqs = var.addons.enable_karpenter ? {
    queue_name = "${var.cluster_attr.cluster_name}-karpenter-sqs"
  } : {}

  metrics_server = var.addons.enable_metrics_server ? {
    role_name = "${var.cluster_attr.cluster_name}-metrics-server-role"
  } : {}

  argo_rollouts = var.addons.enable_argo_rollouts ? {
    role_name = "${var.cluster_attr.cluster_name}-argo-rollouts-role"
  } : {}

  cluster_autoscaler = var.addons.enable_cluster_autoscaler ? {
    role_name = "${var.cluster_attr.cluster_name}-cluster-autoscaler-role"
  } : {}

}

module "ebs_csi_driver_irsa" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version  = "~> 5.20"

  role_name_prefix = "${each.key}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = each.value.cluster_tags
}