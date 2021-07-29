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
          cipherSuites = [
            "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
            "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
            "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
            "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
            "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
            "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
          ]
          [[entryPoints.https.tls.certificates]]
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