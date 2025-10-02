# Installation de Kubernetes (Debian 12)

## 1. Préparation système

🖥️ **Sur toutes les VM (master + workers)** :

```bash
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release vim git containerd
```

## 2. Installation de Kubernetes

🖥️ **Sur toutes les VM (master + workers)** :

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

## 3. Initialisation du cluster

👑 **Sur le master uniquement** :

```bash
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

kubeadm init --pod-network-cidr=192.168.0.0/16
```

Configurer kubectl (master uniquement) :

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

## 4. Installation du réseau CNI (Calico)

👑 **Sur le master uniquement** :

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
```

## 5. Ajout des workers

⚙️ **Sur chaque worker** :

Exécuter la commande join donnée par le master :

```bash
kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

(Si besoin, régénérer le token sur le master : `kubeadm token create --print-join-command`).
