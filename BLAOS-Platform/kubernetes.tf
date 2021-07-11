provider "kubernetes-alpha" {
  config_path = var.k3s_config_path // path to kubeconfig
}

provider "kubectl" {
  config_path    = var.k3s_config_path // path to kubeconfig
  insecure       = true
  config_context = "default"
}

# Add Worker Label
resource "null_resource" "label" {
  count = data.terraform_remote_state.platform.outputs.cluster_worker_count
  triggers = {
    hostname = lower(data.terraform_remote_state.platform.outputs.cluster_worker_host_names[count.index])
    config   = var.k3s_config_path
  }

  provisioner "local-exec" {
    command     = "kubectl --kubeconfig ${self.triggers.config} label nodes ${self.triggers.hostname} kubernetes.io/role=worker"
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl --kubeconfig ${self.triggers.config} label --overwrite nodes ${self.triggers.hostname} kubernetes.io/role-"
    interpreter = ["PowerShell", "-Command"]
  }
}

# Delete Local Path storageclass
resource "null_resource" "local_path" {
  depends_on = [
    helm_release.longhorn

  ]

  triggers = {
    config = var.k3s_config_path
  }

  provisioner "local-exec" {
    command     = "kubectl --kubeconfig ${self.triggers.config} delete storageclass local-path"
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl --kubeconfig ${self.triggers.config} apply -f ./../resources/templates/local_path-storageclass-yaml.tpl"
    interpreter = ["PowerShell", "-Command"]
  }
}

# Creates secrets 
resource "kubernetes_manifest" "secret_ca_key_pair" {
  depends_on = [
    local_file.ca_cert,
    local_file.ca_key,
    helm_release.cert_manager

  ]
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "tls.crt" = base64encode(tls_self_signed_cert.ca.cert_pem)
      "tls.key" = base64encode(tls_private_key.ca.private_key_pem)
    }
    "kind" = "Secret"
    "metadata" = {
      "name"      = "ca-key-pair"
      "namespace" = "cert-manager"
    }
    "type" = "kubernetes.io/tls"
  }
}

# Generate Config
data "template_file" "ca_clusterissuer" {
  template = file("${path.module}/../resources/templates/ca-clusterissuer-yaml.tpl")
}

resource "kubectl_manifest" "ca_clusterissuer" {
  depends_on = [
    kubernetes_manifest.secret_ca_key_pair,
    helm_release.cert_manager,
    time_sleep.cert_manager,
  ]
  yaml_body = data.template_file.ca_clusterissuer.rendered
}

# Replace configmap for traefik
data "template_file" "configmap_traefik_replace" {
  template = file("${path.module}/../resources/templates/configmap-traefik-yaml.tpl")
}

# Replace configmap traefik rollback
data "template_file" "configmap_traefik_replace_rollback" {
  template = file("${path.module}/../resources/templates/configmap-trafik-rollback-yaml.tpl")
}

resource "local_file" "configmap_traefik_replace" {
  content         = data.template_file.configmap_traefik_replace.rendered
  filename        = "${path.module}/artifacts/configs/configmap-traefik.yaml"
  file_permission = "0644"
}

resource "local_file" "configmap_traefik_replace_rollback" {
  content         = data.template_file.configmap_traefik_replace_rollback.rendered
  filename        = "${path.module}/artifacts/configs/configmap-trafik-rollback.yaml"
  file_permission = "0644"
}

# Addjust ingress controller configmap
resource "null_resource" "configmap_traefik_replace" {
  depends_on = [
    local_file.configmap_traefik_replace_rollback,
    local_file.configmap_traefik_replace
  ]

  triggers = {
    config = var.k3s_config_path
  }

  provisioner "local-exec" {
    command     = "kubectl --kubeconfig ${self.triggers.config} replace -f ./artifacts/configs/configmap-traefik.yaml"
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl --kubeconfig ${self.triggers.config} replace -f ./artifacts/configs/configmap-trafik-rollback.yaml"
    interpreter = ["PowerShell", "-Command"]
  }
}

# Patch Load Balance for MLB
data "template_file" "service_traefik_patch" {
  template = file("${path.module}/../resources/templates/service-traefik-patch-yaml.tpl")
  vars = {
    tf_address = replace(var.address_pool, "//.*/", "")
  }
}

# Create Patch Load Balancer for MLB
data "template_file" "service_traefik_patch_rollback" {
  template = file("${path.module}/../resources/templates/service-traefik-patch-yaml.tpl")
  vars = {
    tf_address = ""
  }
}

resource "local_file" "service_traefik_patch" {
  content         = data.template_file.service_traefik_patch.rendered
  filename        = "${path.module}/artifacts/configs/service_traefik_patch.yaml"
  file_permission = "0644"
}

resource "local_file" "service_traefik_patch_rollback" {
  content         = data.template_file.service_traefik_patch_rollback.rendered
  filename        = "${path.module}/artifacts/configs/service_traefik_patch_rollback.yaml"
  file_permission = "0644"
}

# Set ingress loadbalancer IP
/* This needs to come after the configmap patch. This is because this will restart all the instances and they will then start with the new config */
resource "null_resource" "service_traefik_patch" {
  depends_on = [
    null_resource.configmap_traefik_replace,
    local_file.service_traefik_patch_rollback,
    local_file.service_traefik_patch
  ]

  triggers = {
    config = var.k3s_config_path
  }

  provisioner "local-exec" {
    command     = "kubectl --kubeconfig ${self.triggers.config} -n kube-system patch service traefik --patch (get-content -raw ./artifacts/configs/service_traefik_patch.yaml)"
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl --kubeconfig ${self.triggers.config} -n kube-system patch service traefik --patch (get-content -raw ./artifacts/configs/service_traefik_patch_rollback.yaml)"
    interpreter = ["PowerShell", "-Command"]
  }
}

# Replace Deployment

## Replace deployment for traefik
data "template_file" "deployment_traefik_replace" {
  template = file("${path.module}/../resources/templates/deployment-traefik-yaml.tpl")
  vars = {
    tf_replicacount = data.terraform_remote_state.platform.outputs.cluster_worker_count
  }
}

## Replace deployment traefik rollback
data "template_file" "deployment_traefik_replace_rollback" {
  template = file("${path.module}/../resources/templates/deployment-traefik-rollback-yaml.tpl")
}

## Create local deployment files
resource "local_file" "deployment_traefik_replace" {
  content         = data.template_file.deployment_traefik_replace.rendered
  filename        = "${path.module}/artifacts/configs/deployment-traefik.yaml"
  file_permission = "0644"
}

## Create local deployment files
resource "local_file" "deployment_traefik_replace_rollback" {
  content         = data.template_file.deployment_traefik_replace_rollback.rendered
  filename        = "${path.module}/artifacts/configs/deployment-traefik-rollback.yaml"
  file_permission = "0644"
}

## Let things settle in the cluster
resource "time_sleep" "traefik" {
  depends_on = [
    local_file.configmap_traefik_replace_rollback,
    local_file.configmap_traefik_replace,
    null_resource.service_traefik_patch,
  ]

  create_duration = "60s"
}

## Addjust ingress controller deploymeny
resource "null_resource" "deployment_traefik_replace" {
  depends_on = [
    time_sleep.traefik,
    local_file.deployment_traefik_replace,
    local_file.deployment_traefik_replace_rollback
  ]

  triggers = {
    config = var.k3s_config_path
  }

  provisioner "local-exec" {
    command     = "kubectl --kubeconfig ${self.triggers.config} replace -f ./artifacts/configs/deployment-traefik.yaml"
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "kubectl --kubeconfig ${self.triggers.config} replace -f ./artifacts/configs/deployment-traefik-rollback.yaml"
    interpreter = ["PowerShell", "-Command"]
  }
}