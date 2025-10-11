module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  for_each = var.items

  cluster_name                   = each.key
  cluster_version                = each.value.cluster_version
  cluster_endpoint_public_access = each.value.cluster_endpoint_public_access

  cluster_addons                           = each.value.cluster_addons
  enable_cluster_creator_admin_permissions = each.value.enable_cluster_creator_admin_permissions
  authentication_mode                      = "API"

  eks_managed_node_group_defaults = each.value.eks_managed_node_group_defaults
  eks_managed_node_groups         = each.value.eks_managed_node_groups
  cluster_compute_config          = each.value.cluster_compute_config

  vpc_id                   = each.value.vpc_id
  subnet_ids               = each.value.subnet_ids
  control_plane_subnet_ids = each.value.control_plane_subnet_ids

  cluster_tags = each.value.cluster_tags

  # other modules
  # access_entries = each.value.access_entries
  cluster_security_group_additional_rules = {
    "default" = {
      description = "Allow default traffic"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [try(each.value.default_ingress_cidr_block, "0.0.0.0/0")]
      type        = "ingress"
    }
  }

  cloudwatch_log_group_retention_in_days = each.value.cloudwatch_log_group_retention_in_days
  create_node_security_group             = each.value.create_node_security_group
  tags                                   = each.value.tags
}

module "blueprints" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  for_each = var.items

  cluster_name      = each.key
  cluster_endpoint  = module.eks[each.key].cluster_endpoint
  cluster_version   = each.value.cluster_version
  oidc_provider_arn = module.eks[each.key].oidc_provider_arn

  observability_tag = null

  // 실제 생성되진 않고 IAM 권한만 준비
  create_kubernetes_resources = false

  enable_cert_manager                 = true
  enable_aws_efs_csi_driver           = true
  enable_aws_cloudwatch_metrics       = true
  enable_external_dns                 = true
  enable_external_secrets             = true
  enable_aws_load_balancer_controller = true
  enable_aws_for_fluentbit            = true
  enable_karpenter                    = true
  enable_metrics_server               = true
  enable_argo_rollouts                = true
  enable_cluster_autoscaler           = false
  external_dns_route53_zone_arns      = each.value.blueprints_external_dns_route53_zone_arns

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa[each.key].iam_role_arn
    }
  }

  cert_manager = {
    role_name = "${each.key}-cert-manager-role"
  }
  aws_efs_csi_driver = {
    role_name = "${each.key}-efs-csi-driver-role"
  }
  aws_cloudwatch_metrics = {
    role_name = "${each.key}-cloudwatch-metrics-role"
  }
  external_dns = {
    role_name = "${each.key}-external-dns-role"
  }
  external_secrets = {
    role_name = "${each.key}-external-secrets-role"
  }
  aws_load_balancer_controller = {
    role_name = "${each.key}-lb-controller-role"
  }
  aws_for_fluentbit = {
    role_name = "${each.key}-aws-for-fluentbit-role"
  }
  karpenter = {
    role_name            = "${each.key}-karpenter-role"
    role_name_use_prefix = false
  }
  karpenter_node = {
    role_name             = "${each.key}-karpenter-node-group-role"
    instance_profile_name = "${each.key}-karpenter-node-group"
    role_name_use_prefix  = false
  }
  karpenter_sqs = {
    queue_name = "${each.key}-karpenter-sqs"
  }
  metrics_server = {
    role_name = "${each.key}-metrics-server-role"
  }
  argo_rollouts = {
    role_name = "${each.key}-argo-rollouts-role"
  }
  cluster_autoscaler = {
    role_name = "${each.key}-cluster-autoscaler-role"
  }

}

module "ebs_csi_driver_irsa" {
  for_each = var.items
  source   = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version  = "~> 5.20"

  role_name_prefix = "${each.key}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks[each.key].oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = each.value.cluster_tags
}