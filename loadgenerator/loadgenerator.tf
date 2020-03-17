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
          image = "893655109199.dkr.ecr.us-east-2.amazonaws.com/test:loadgenerator"
          name  = "load-generator"
        }
      }
    }
  }
}