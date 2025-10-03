# Metrics Server

Ce document décrit l'installation et la configuration du **Metrics Server** dans un cluster Kubernetes.

Le Metrics Server permet de collecter les métriques de ressources (CPU, mémoire) des **nœuds** et des **pods**, ce qui est utilisé par `kubectl top` ou pour l’auto-scaling horizontal.

---

## Fichiers YAML

### 1. Deployment Metrics Server (édité)

```yaml
# metrics-server-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      containers:
      - name: metrics-server
        image: registry.k8s.io/metrics-server/metrics-server:v0.8.0
        imagePullPolicy: IfNotPresent
        args:
        - --cert-dir=/tmp
        - --secure-port=10250
        - --kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP
        - --kubelet-use-node-status-port
        - --kubelet-insecure-tls
        - --metric-resolution=15s
        ports:
        - containerPort: 10250
          name: https
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
          timeoutSeconds: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
          timeoutSeconds: 1
          failureThreshold: 3
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      volumes:
      - name: tmp-dir
        emptyDir: {}
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      restartPolicy: Always
      dnsPolicy: ClusterFirst
      terminationGracePeriodSeconds: 30
```

### 2. ServiceAccount et Service Metrics Server

```yaml
# metrics-server.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups: [""]
  resources: ["pods", "nodes", "nodes/stats", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods", "nodes"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["nodes/stats"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      containers:
      - name: metrics-server
        image: k8s.gcr.io/metrics-server/metrics-server:v0.5.2
        imagePullPolicy: IfNotPresent
        args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP
        - --metric-resolution=15s
        ports:
        - containerPort: 4443
          name: main-port
          protocol: TCP
      restartPolicy: Always
      dnsPolicy: ClusterFirst
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    k8s-app: metrics-server
  ports:
  - port: 443
    targetPort: 4443
```

---

## Commandes et explications

1. **Appliquer le YAML du Metrics Server**

```bash
kubectl apply -f metrics-server.yaml
```

> Crée le service account, le clusterrole, le clusterrolebinding, le service et le déploiement Metrics Server.

2. **Éditer le déploiement pour ajouter des options**

```bash
KUBE_EDITOR="nano" kubectl edit deployment metrics-server -n kube-system
```

> Permet de modifier les arguments du conteneur (ex : `--kubelet-insecure-tls`, `--kubelet-preferred-address-types`).

3. **Redémarrer le déploiement pour prendre en compte les changements**

```bash
kubectl rollout restart deployment metrics-server -n kube-system
```

4. **Vérifier que le pod est en cours d’exécution**

```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

5. **Vérifier que l’API metrics-server est enregistrée**

```bash
kubectl get apiservice | grep metrics
```

6. **Tester la récupération des métriques**

```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

7. **Créer un clusterrolebinding supplémentaire si nécessaire**

```bash
kubectl create clusterrolebinding metrics-server-auth \
  --clusterrole=system:metrics-server \
  --serviceaccount=kube-system:metrics-server \
  --dry-run=client -o yaml | kubectl apply -f -
```

8. **Supprimer et recréer un clusterrolebinding pour éviter les erreurs**

```bash
kubectl delete clusterrolebinding metrics-server:system:auth-delegator
kubectl create clusterrolebinding metrics-server:system:auth-delegator \
  --clusterrole=system:auth-delegator \
  --serviceaccount=kube-system:metrics-server
```

---

Avec ce guide, vous pouvez installer et configurer Metrics Server sur un cluster Kubernetes à partir de zéro.
