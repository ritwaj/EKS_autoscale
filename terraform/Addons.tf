data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

resource "null_resource" "kubectl_init" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name test"
  }
  depends_on = [aws_eks_node_group.worker-group]
}


resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "stable/metrics-server"
  namespace  = "kube-system"
  depends_on = [null_resource.kubectl_init]
}

resource "helm_release" "dashboard" {
  name       = "dashboard"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "stable/kubernetes-dashboard"
  namespace  = "kube-system"
  depends_on = [helm_release.metrics-server]
}

resource "kubernetes_service_account" "dashboard-sa" {
  metadata {
    name = "eks-admin"
    namespace = "kube-system"
  }
  depends_on = [null_resource.kubectl_init]
}

resource "kubernetes_cluster_role_binding" "dashboard_crb" {
  metadata {
    name = "eks-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "eks-admin"
    namespace = "kube-system"
  }
  depends_on = [kubernetes_cluster_role_binding.dashboard_crb]
}

resource "helm_release" "cluster-autoscaler" {
  name       = "cluster-autoscaler"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "stable/cluster-autoscaler"
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = "test"
  }

set {
    name  = "cloudProvider"
    value = "aws"
  }

 set {
    name  = "awsRegion"
    value = "us-east-1"
  }

 set {
    name  = "rbac.create"
    value = "true"
  }

  depends_on = [helm_release.metrics-server]
}