resource "kubernetes_manifest" "app_project" {

    manifest = {
        apiVersion = "argoproj.io/v1alpha1"
        kind = "AppProject"
        metadata = {
            name = "${var.cluster_attr.cluster_name}-${var.cluster_attr.environment}-workspace"
            namespace = "argocd"
            labels = {
                environment = var.cluster_attr.environment
                managedBy = "terraform"
            }
        }
        spec = {
            description = "${var.cluster_attr.cluster_name}-${var.cluster_attr.environment} workspace"

            ## Git 허용 여부
            sourceRepos = ["*"]

            ## 클러스터, 네임스페이스 허용
            destinations = [
                {
                    service = "*"
                    namespace = "*"
                }
            ]

            ## 클러스터 리소스 허용
            clusterResourceWhitelist = [
                {
                    group = "*"
                    kind = "*"
                }
            ]

            # 네임스페이스 리소스 허용
            namespaceResourceWhitelist = [
                {
                    group = "*"
                    kind = "*"
                }
            ]
        }
    }
}
