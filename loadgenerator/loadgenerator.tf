resource "kubernetes_deployment" "load-generator" {
  metadata {
    name = "load-generator"
    labels = {
      App = "load-generator"
    }
  }

  spec {
    replicas = 4
    selector {
      match_labels = {
        App = "load-generator"
      }
    }
    template {
      metadata {
        labels = {
          App = "load-generator"
        }
      }
      spec {
        container {
          image           = var.image-url
          name            = "load-generator"
		  image_pull_policy = "Always"
          env {
		    name  = "cluster"
		    value = var.cluster-name
			}
        }
      }
    }
  }
}