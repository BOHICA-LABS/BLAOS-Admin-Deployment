apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-clusterissuer
spec:
  ca:
    secretName: ca-key-pair