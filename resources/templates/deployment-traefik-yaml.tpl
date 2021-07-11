kind: Deployment
apiVersion: apps/v1
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
    deployment.kubernetes.io/revision: '1'
    meta.helm.sh/release-name: traefik
    meta.helm.sh/release-namespace: kube-system
spec:
  replicas: ${tf_replicacount}
  selector:
    matchLabels:
      app: traefik
      release: traefik
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: traefik
        chart: traefik-1.81.0
        heritage: Helm
        release: traefik
    spec:
      volumes:
        - name: config
          configMap:
            name: traefik
            defaultMode: 420
        - name: ssl
          secret:
            secretName: traefik-default-cert
            defaultMode: 420
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/role
                operator: In
                values:
                - worker
      containers:
        - name: traefik
          image: 'rancher/library-traefik:1.7.19'
          args:
            - '--configfile=/config/traefik.toml'
            - '--insecureSkipVerify=true'
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
            - name: httpn
              containerPort: 8880
              protocol: TCP
            - name: https
              containerPort: 443
              protocol: TCP
            - name: dash
              containerPort: 8080
              protocol: TCP
            - name: metrics
              containerPort: 9100
              protocol: TCP
          resources: {}
          volumeMounts:
            - name: config
              mountPath: /config
            - name: ssl
              mountPath: /ssl
          livenessProbe:
            httpGet:
              path: /ping
              port: http
              scheme: HTTP
            initialDelaySeconds: 10
            timeoutSeconds: 2
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ping
              port: http
              scheme: HTTP
            initialDelaySeconds: 10
            timeoutSeconds: 2
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 1
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent
      restartPolicy: Always
      terminationGracePeriodSeconds: 60
      dnsPolicy: ClusterFirst
      serviceAccountName: traefik
      serviceAccount: traefik
      securityContext: {}
      schedulerName: default-scheduler
      tolerations:
        - key: CriticalAddonsOnly
          operator: Exists
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
        - key: node-role.kubernetes.io/master
          operator: Exists
          effect: NoSchedule
      priorityClassName: system-cluster-critical
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
