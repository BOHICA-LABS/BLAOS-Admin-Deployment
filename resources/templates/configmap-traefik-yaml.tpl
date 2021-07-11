apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik
  namespace: kube-system
  labels:
    app: traefik
    app.kubernetes.io/managed-by: Helm
    chart: traefik-1.81.0
    heritage: Helm
    release: traefik
  annotations:
    meta.helm.sh/release-name: traefik
    meta.helm.sh/release-namespace: kube-system
data:
  traefik.toml: |
    # traefik.toml
    logLevel = "info"
    defaultEntryPoints = ["http","https"]
    [entryPoints]
      [entryPoints.http]
      address = ":80"
      compress = true
        [entryPoints.http.redirect]
        entryPoint = "https"
      [entryPoints.https]
      address = ":443"
      compress = true
        [entryPoints.https.tls]
          minVersion = "VersionTLS12"
          [[entryPoints.https.tls.certificates]]
          CertFile = "/ssl/tls.crt"
          KeyFile = "/ssl/tls.key"
      [entryPoints.prometheus]
      address = ":9100"
    [ping]
    entryPoint = "http"
    [kubernetes]
      [kubernetes.ingressEndpoint]
      publishedService = "kube-system/traefik"
    [traefikLog]
      format = "json"
    [api]
      dashboard = true
    [metrics]
      [metrics.prometheus]
        entryPoint = "prometheus"