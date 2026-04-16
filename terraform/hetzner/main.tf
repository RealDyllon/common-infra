resource "null_resource" "install_k3s" {
  triggers = {
    server_ip       = var.server_ip
    admin_username  = var.admin_username
    k3s_version     = var.k3s_version
    k3s_token_hash  = sha256(var.k3s_token)
    disable_traefik = tostring(var.disable_traefik)
    kubeconfig_mode = var.kubeconfig_mode
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.admin_username
    private_key = file(pathexpand(var.admin_private_key_path))
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/install-k3s.sh"
    destination = "/tmp/install-k3s.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-k3s.sh",
      "sudo K3S_VERSION='${var.k3s_version}' K3S_TOKEN='${var.k3s_token}' KUBECONFIG_MODE='${var.kubeconfig_mode}' DISABLE_TRAEFIK='${var.disable_traefik}' /tmp/install-k3s.sh"
    ]
  }
}
