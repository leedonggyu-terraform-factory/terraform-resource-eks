variable "cluster_attr" {

  type = object({
    hub = bool
    cluster_name = string
    environment = string
    cluster_version = string
    cluster_endpoint_public_access = bool
    cluster_addons = map(any)
    enable_cluster_creator_admin_permissions = bool
    eks_managed_node_group_defaults = any
    eks_managed_node_groups = any
    cluster_compute_config = map(any)
    vpc_id = string
    worker_subnet_ids = list(string)
    control_plane_subnet_ids = list(string)
    cluster_tags = map(any)
    cloudwatch_log_group_retention_in_days = number
    create_node_security_group = bool
  })
  
  default = {
    hub = false
    cluster_name = ""
    environment = ""
    cluster_version = ""
    cluster_endpoint_public_access = true
    cluster_addons = {}
    enable_cluster_creator_admin_permissions = true
    
    eks_managed_node_group_defaults = {}
    eks_managed_node_groups = {}
    cluster_compute_config = {}

    vpc_id = ""
    worker_subnet_ids = []
    control_plane_subnet_ids = []

    cluster_tags = {}

    cloudwatch_log_group_retention_in_days = 0
    create_node_security_group = true
  }
}

variable "gitops_bridge_attr" {

  type = object({
    addons_repo_url = string
    addons_repo_basepath = string
    addons_repo_path = string
    addons_repo_revision = string
  })

  default = {
    addons_repo_url = ""
    addons_repo_basepath = ""
    addons_repo_path = ""
    addons_repo_revision = ""
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

  default = {
    enable_cert_manager = false
    enable_aws_efs_csi_driver = false
    enable_aws_cloudwatch_metrics = false
    enable_external_dns = false
    enable_external_secrets = false
    enable_aws_load_balancer_controller = false
    enable_aws_for_fluentbit = false
    enable_karpenter = false
    enable_metrics_server = false
    enable_argo_rollouts = false
    enable_cluster_autoscaler = false
    external_dns_route53_zone_arns = []
  }
}

variable "access_entries_user" {
  type = any

  default = {
    "AmazonEKSClusterAdminPolicy" : []
  }

}

variable "access_entries_role" {
  type = any

  default = {
    "EC2_LINUX" : []
  }
}