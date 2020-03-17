resource "kubernetes_deployment" "test-deploy" {
  metadata {
    name = "${var.cluster-name}-deploy"
    labels = {
      App = "${var.cluster-name}-app"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        App = "${var.cluster-name}-app"
      }
    }
    template {
      metadata {
        labels = {
          App = "${var.cluster-name}-app"
        }
      }
      spec {
        container {
          image = var.image-url
          name  = "${var.cluster-name}-container"

          port {
            container_port = 80
          }

          resources {
            limits {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_cluster_role_binding.dashboard_crb]
}

resource "kubernetes_service" "test-svc" {
  metadata {
    name = "${var.cluster-name}-svc"
  }
  spec {
    selector = {
      App = kubernetes_deployment.test-deploy.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
  depends_on = [kubernetes_deployment.test-deploy]
}

resource "null_resource" "create_hpa" {
  provisioner "local-exec" {
    command = "kubectl autoscale deployment ${var.cluster-name}-deploy --cpu-percent=50 --min=1 --max=10"
  }
  depends_on = [kubernetes_deployment.test-deploy,helm_release.metrics-server]
}
#resource "kubernetes_horizontal_pod_autoscaler" "test-hpa" {
#  metadata {
#    name = "${var.cluster-name}-hpa"
#  }
#  spec {
#    max_replicas = 10
#    min_replicas = 1
#    scale_target_ref {
#      kind = "Deployment"
#      name = kubernetes_deployment.test-deploy.metadata[0].name
#    }
#    target_cpu_utilization_percentage = 50
#  }
#  depends_on = [kubernetes_deployment.test-deploy,helm_release.metrics-server]
#}

output "lb_ip" {
  value = kubernetes_service.test-svc.load_balancer_ingress[0].hostname
}