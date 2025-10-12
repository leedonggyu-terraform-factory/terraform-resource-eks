<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_blueprints"></a> [blueprints](#module\_blueprints) | aws-ia/eks-blueprints-addons/aws | ~> 1.0 |
| <a name="module_ebs_csi_driver_irsa"></a> [ebs\_csi\_driver\_irsa](#module\_ebs\_csi\_driver\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.20 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 20.31 |
| <a name="module_gitops-bridge"></a> [gitops-bridge](#module\_gitops-bridge) | gitops-bridge-dev/gitops-bridge/helm | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.eks_kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addons"></a> [addons](#input\_addons) | 실제 Addons 들은 GitOps Bridge 내에서 구성합니다 | <pre>object({<br/>    enable_cert_manager = bool<br/>    enable_aws_efs_csi_driver = bool<br/>    enable_aws_cloudwatch_metrics = bool<br/>    enable_external_dns = bool<br/>    enable_external_secrets = bool<br/>    enable_aws_load_balancer_controller = bool<br/>    enable_aws_for_fluentbit = bool<br/>    enable_karpenter = bool<br/>    enable_metrics_server = bool<br/>    enable_argo_rollouts = bool<br/>    enable_cluster_autoscaler = bool<br/>    external_dns_route53_zone_arns = list(string)<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_attr"></a> [cluster\_attr](#input\_cluster\_attr) | n/a | <pre>object({<br/>    cluster_name = string<br/>    cluster_version = string<br/>    cluster_endpoint_public_access = bool<br/>    cluster_addons = map(any)<br/>    enable_cluster_creator_admin_permissions = bool<br/>    eks_managed_node_group_defaults = map(any)<br/>    eks_managed_node_groups = map(any)<br/>    cluster_compute_config = map(any)<br/>    vpc_id = string<br/>    private_subnet_ids = list(string)<br/>    cluster_tags = map(any)<br/>    cloudwatch_log_group_retention_in_days = number<br/>    create_node_security_group = bool<br/>  })</pre> | <pre>{<br/>  "cloudwatch_log_group_retention_in_days": 0,<br/>  "cluster_addons": {},<br/>  "cluster_compute_config": {},<br/>  "cluster_endpoint_public_access": true,<br/>  "cluster_name": "",<br/>  "cluster_tags": {},<br/>  "cluster_version": "",<br/>  "create_node_security_group": true,<br/>  "eks_managed_node_group_defaults": {},<br/>  "eks_managed_node_groups": {},<br/>  "enable_cluster_creator_admin_permissions": "",<br/>  "environment": "",<br/>  "private_subnet_ids": [],<br/>  "vpc_id": ""<br/>}</pre> | no |
| <a name="input_gitops_bridge_attr"></a> [gitops\_bridge\_attr](#input\_gitops\_bridge\_attr) | n/a | <pre>{<br/>    addons_repo_url = string<br/>    addons_repo_basepath = string<br/>    addons_repo_path = string<br/>    addons_repo_revision = string<br/>  }</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_blueprints"></a> [blueprints](#output\_blueprints) | n/a |
| <a name="output_eks"></a> [eks](#output\_eks) | n/a |
<!-- END_TF_DOCS -->