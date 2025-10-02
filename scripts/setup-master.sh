#!/bin/bash
set -e

# === Master Node Setup ===
hostnamectl set-hostname k8s-master

# Update /etc/hosts
cat > /etc/hosts <<EOF
192.168.1.100 k8s-master
192.168.1.101 k8s-worker1
192.168.1.102 k8s-worker2
EOF

# Common setup (same as workers)
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release vim git containerd

# Kubernetes install
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Init cluster
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

kubeadm init --pod-network-cidr=192.168.0.0/16

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml

echo "=== Master setup terminé ==="
