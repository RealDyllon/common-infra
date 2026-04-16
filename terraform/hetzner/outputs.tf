output "k3s_endpoint" {
  description = "Server endpoint used by kubectl/kubeconfig."
  value       = var.server_ip
}

output "kubeconfig_remote_path" {
  description = "Remote kubeconfig path on host."
  value       = "/etc/rancher/k3s/k3s.yaml"
}

output "admin_username" {
  description = "Admin username used for SSH bootstrap."
  value       = var.admin_username
}
