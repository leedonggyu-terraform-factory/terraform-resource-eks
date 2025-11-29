variable "cluster_attr" {

  type = object({
    info = object({
      type              = string // hub or spoke
      oidc_provider_arn = string // if hub, not used
    })
    cluster_name                             = string
    environment                              = string
    cluster_version                          = string
    cluster_endpoint_public_access           = bool
    cluster_addons                           = map(any)
    enable_cluster_creator_admin_permissions = bool
    eks_managed_node_group_defaults          = any
    eks_managed_node_groups                  = any
    cluster_compute_config                   = map(any)
    vpc_id                                   = string
    worker_subnet_ids                        = list(string)
    control_plane_subnet_ids                 = list(string)
    cluster_tags                             = map(any)
    cloudwatch_log_group_retention_in_days   = number
    create_node_security_group               = bool
  })

  default = {
    info = {
      type              = "spoke"
      oidc_provider_arn = ""
    }
    cluster_name                             = ""
    environment                              = ""
    cluster_version                          = ""
    cluster_endpoint_public_access           = true
    cluster_addons                           = {}
    enable_cluster_creator_admin_permissions = true

    eks_managed_node_group_defaults = {}
    eks_managed_node_groups         = {}
    cluster_compute_config          = {}

    vpc_id                   = ""
    worker_subnet_ids        = []
    control_plane_subnet_ids = []

    cluster_tags = {}

    cloudwatch_log_group_retention_in_days = 0
    create_node_security_group             = true
  }
}

variable "gitops_bridge_attr" {

  type = object({
    addons_repo_url      = string
    addons_repo_basepath = string
    addons_repo_path     = string
    addons_repo_revision = string
  })

  default = {
    addons_repo_url      = ""
    addons_repo_basepath = ""
    addons_repo_path     = ""
    addons_repo_revision = ""
  }
}

variable "metadata" {
  type        = any
  description = "argocd 에 필요한 metadata 정보"
  default     = {}
}

variable "addons" {

  description = "실제 Addons 들은 Blueprints / ArgoCD ApplicationSet 에서 구성합니다"

  type = any
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

variable "pod_identity" {
  type    = any
  default = {}

  #   default = {
  #     "[SA_NAME]" : {
  #       "create_sa" : boolean
  #       "namespace" : string
  #       "[POLCY_NAME]" : json
  #     }
  #   }
}
