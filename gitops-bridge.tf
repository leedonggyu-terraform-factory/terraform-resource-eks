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

    depends_on = [module.eks,null_resource.eks_kubeconfig]
}