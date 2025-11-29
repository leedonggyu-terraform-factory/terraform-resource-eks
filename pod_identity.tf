resource "null_resource" "kubectl" {

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ap-northeast-2 --name ${module.eks.cluster_name}"
  }

  depends_on = [module.eks, module.blueprints]
}

##################################################################
#### Service Account (if not create)
##################################################################
resource "kubernetes_service_account" "pod_identity_sa" {

  for_each = {
    for sa_name, config in var.pod_identity :
    sa_name => {
      sa_name : sa_name,
      namespace : config.namespace
    } if config.create_sa
  }

  metadata {
    name      = each.value.sa_name
    namespace = each.value.namespace
  }

  depends_on = [null_resource.kubectl]
}

##################################################################
#### Pod Identity
##################################################################
resource "aws_iam_role" "pod_identity_role" {
  for_each = var.pod_identity

  name = "${each.key}-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

# 권한 추가 (예: S3 접근)
resource "aws_iam_policy" "pod_identity_policy" {
  for_each = var.pod_identity

  name   = aws_iam_role.pod_identity_role[each.key].name
  path   = "/"
  policy = each.value.policy
}

resource "aws_iam_role_policy_attachment" "pod_identity_policy_attachment" {
  for_each = var.pod_identity

  role       = aws_iam_role.pod_identity_role[each.key].name
  policy_arn = aws_iam_policy.pod_identity_policy[each.key].arn
}

# Pod Identity Association
resource "aws_eks_pod_identity_association" "app" {
  for_each = var.pod_identity

  cluster_name    = module.eks.cluster_name
  namespace       = each.value.namespace
  service_account = each.key
  role_arn        = aws_iam_role.pod_identity_role[each.key].arn

  depends_on = [module.eks, module.blueprints]
}
