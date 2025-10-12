variable "cluster_attr" {

  type = object({
    cluster_name = string
    cluster_version = string
    cluster_endpoint_public_access = bool
    cluster_addons = map(any)
    enable_cluster_creator_admin_permissions = bool
    eks_managed_node_group_defaults = map(any)
    eks_managed_node_groups = map(any)
    cluster_compute_config = map(any)
    vpc_id = string
    private_subnet_ids = list(string)
    cluster_tags = map(any)
    cloudwatch_log_group_retention_in_days = number
    create_node_security_group = bool
  })
  
  default = {
    cluster_name = ""
    environment = ""
    cluster_version = ""
    cluster_endpoint_public_access = true
    cluster_addons = {}
    enable_cluster_creator_admin_permissions = ""
    
    eks_managed_node_group_defaults = {}
    eks_managed_node_groups = {}
    cluster_compute_config = {}

    vpc_id = ""
    private_subnet_ids = []

    cluster_tags = {}

    cloudwatch_log_group_retention_in_days = 0
    create_node_security_group = true
  }
}

variable "gitops_bridge_attr" {

  type = {
    addons_repo_url = string
    addons_repo_basepath = string
    addons_repo_path = string
    addons_repo_revision = string
  } 
}

variable "addons" {

  description = "실제 Addons 들은 GitOps Bridge 내에서 구성합니다"

  type = object({
    enable_cert_manager = bool
    enable_aws_efs_csi_driver = bool
    enable_aws_cloudwatch_metrics = bool
    enable_external_dns = bool
    enable_external_secrets = bool
    enable_aws_load_balancer_controller = bool
    enable_aws_for_fluentbit = bool
    enable_karpenter = bool
    enable_metrics_server = bool
    enable_argo_rollouts = bool
    enable_cluster_autoscaler = bool
    external_dns_route53_zone_arns = list(string)
  })

  default = {}
}