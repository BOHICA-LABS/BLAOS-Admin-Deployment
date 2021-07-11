output "cluster_master_count" {
  description = "Count of the masters deployed"
  value       = data.terraform_remote_state.platform.outputs.cluster_master_count
}

output "Load_Balancer_IP_Address" {
  description = "IP address"
  value       = replace(var.address_pool, "//.*/", "")
}

output "Rancher_URL" {
  description = "Rancher URL"
  value       = var.rancher_hostname
}

output "ca_cert" {
  value       = tls_self_signed_cert.ca.cert_pem
  description = "CA public certificate"
  sensitive   = true
}

output "ca_key" {
  value       = tls_self_signed_cert.ca.private_key_pem
  description = "CA private cetrficate"
  sensitive   = true
}