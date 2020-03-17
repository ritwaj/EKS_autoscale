resource "null_resource" "kubectl_init" {
  provisioner "local-exec" {
    command = "drain_node.bat"
  }
}