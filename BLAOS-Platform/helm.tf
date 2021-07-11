provider "helm" {
  kubernetes {
    config_path = var.k3s_config_path
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [
    local_file.ca_cert,
    local_file.ca_key,
    #kubernetes_manifest.namespace_cert_manager,
  ]
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.3.1"
  namespace        = "cert-manager"
  wait             = true
  wait_for_jobs    = true
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# We need to wait a few to make sure the custom resources full register
resource "time_sleep" "cert_manager" {
  depends_on = [
    helm_release.cert_manager
  ]

  create_duration = "30s"
}

# Install Rancher
resource "helm_release" "rancher" {
  depends_on = [
    helm_release.cert_manager,
    time_sleep.cert_manager
  ]
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  version          = "2.5.8"
  namespace        = "cattle-system"
  wait             = true
  wait_for_jobs    = true
  create_namespace = true

  set {
    name  = "hostname"
    value = var.rancher_hostname
  }
}

# Generate Config for metallb
data "template_file" "metallb" {
  template = file("${path.module}/../resources/templates/metalLB-values-yaml.tpl")
  vars = {
    tf_address_pool      = var.address_pool
    tf_address_pool_name = var.address_pool_name
  }
}

# Install metal-LB
resource "helm_release" "metallb" {
  /*
  depends_on = [
    kubernetes_manifest.namespace_metallb-system,
  ]
  */
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  version          = "0.10.2"
  namespace        = "metallb-system"
  wait             = true
  wait_for_jobs    = true
  create_namespace = true

  values = [<<EOF
configInline:
  address-pools:
   - name: ${var.address_pool_name}
     protocol: layer2
     addresses:
     - ${var.address_pool}
EOF
  ]
}

# Install Longhorn
resource "helm_release" "longhorn" {
  /*
  depends_on = [
    kubernetes_manifest.namespace_metallb-system,
  ]
  */
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  version          = "1.1.1"
  namespace        = "longhorn-system"
  wait             = true
  wait_for_jobs    = true
  create_namespace = true

  set {
    name  = "persistence.defaultClass"
    value = true
  }

  set {
    name  = "persistence.defaultClassReplicaCount"
    value = 1
  }

}