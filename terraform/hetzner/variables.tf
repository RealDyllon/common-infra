variable "server_ip" {
  description = "Public IP or DNS name of the existing server where k3s will be installed."
  type        = string
}

variable "admin_username" {
  description = "SSH username used for bootstrap operations."
  type        = string
  default     = "ops"
}

variable "admin_private_key_path" {
  description = "Local path to SSH private key used by Terraform provisioners and make kubeconfig."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "k3s_version" {
  description = "Pinned k3s version to install."
  type        = string
  default     = "v1.31.5+k3s1"
}

variable "k3s_token" {
  description = "Shared secret token used by k3s server."
  type        = string
  sensitive   = true
}

variable "kubeconfig_mode" {
  description = "k3s kubeconfig file mode."
  type        = string
  default     = "0640"
}

variable "disable_traefik" {
  description = "Disable bundled Traefik deployment when true."
  type        = bool
  default     = true
}
