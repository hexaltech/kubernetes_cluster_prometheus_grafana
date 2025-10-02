#!/bin/bash
set -e

# === Worker Node Setup ===
HOSTNAME=$1

hostnamectl set-hostname $HOSTNAME

# Update /etc/hosts
cat > /etc/hosts <<EOF
192.168.1.100 k8s-master
192.168.1.101 k8s-worker1
192.168.1.102 k8s-worker2
EOF

# Common setup
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release vim git containerd

# Kubernetes install
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "=== Worker setup terminé ==="
echo "⚠️ N'oublie pas de lancer la commande join fournie par le master"
