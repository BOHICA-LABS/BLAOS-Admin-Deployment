resource "tls_private_key" "ca" {
  algorithm   = var.private_key_algorithm
  rsa_bits    = var.private_key_rsa_bits
  ecdsa_curve = var.private_key_ecdsa_curve
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm         = tls_private_key.ca.algorithm
  private_key_pem       = tls_private_key.ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.ca_allowed_uses

  subject {
    common_name  = var.ca_common_name
    organization = var.organization_name
  }
}

resource "local_file" "ca_cert" {
  content  = tls_self_signed_cert.ca.cert_pem
  filename = format("${path.module}/artifacts/keys/%s-ca-rsa.crt", data.terraform_remote_state.platform.outputs.vsphere_vapp_name)
}

resource "local_file" "ca_key" {
  content  = tls_private_key.ca.private_key_pem
  filename = format("${path.module}/artifacts/keys/%s-ca-rsa.key", data.terraform_remote_state.platform.outputs.vsphere_vapp_name)
}