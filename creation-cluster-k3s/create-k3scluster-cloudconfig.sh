#!/bin/bash
export PATH=/snap/bin:/usr/local/bin:/usr/local/sbin:$PATH
export SSH_KEYS="/var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa"
export OPTIONS="--no-deploy traefik --flannel-backend=none --cluster-cidr=192.168.0.0/16"
export PURGE="$(pwd)/reset-multipass-vm.sh"
export METALLB="$(pwd)/metallb/create-metallb.sh"
export LONGHORN="$(pwd)/longhorn/create-longhorn.sh"
export CALICO="$(pwd)/calico/create-calico.sh"


if ! [ -x "$(command -v multipass)" ]; then
  echo 'install multipass' >&2
  sudo apt update
  sudo apt install snapd
  sudo snap install multipass --edge --classic
  sudo multipass set local.driver=libvirt
fi


if [ $(multipass get local.driver) != 'libvirt' ]; then
    sudo multipass set local.driver=libvirt
fi


echo "purge existing VM"
$PURGE

if ! [ -x "$(command -v k3s)" ]; then
  echo 'install k3s' >&2
  curl -sfL https://get.k3s.io | sh -
fi
if ! [ -x "$(command -v k3sup)" ]; then
  echo 'install k3sup' >&2
  curl -sLS https://get.k3sup.dev | sudo sh
fi


multipass launch focal -n master -c 2 -m 4G --disk 15G --cloud-init cloud-config.yaml 
for node in node{1..3}; do echo "create node $node"; multipass launch focal --disk 15G -c 2 -n $node --cloud-init cloud-config.yaml; done


ipadr=$(multipass list|grep node|awk '{print $3}')
ipmaster=$(multipass list|grep master|awk '{print $3}')
echo 'IP du master K8S'
echo $ipmaster
echo 'IP de  plane K8S'
echo $ipadr

sleep 30
sudo k3sup install --user ubuntu  --ip  $ipmaster --ssh-key $SSH_KEYS --k3s-extra-args "$OPTIONS"
for ipnode in $(echo $ipadr) ; do sudo k3sup join --user ubuntu  --ip  $ipnode --server-ip  $ipmaster --ssh-key $SSH_KEYS  ; done
sudo multipass exec master -- sudo chmod 644 /etc/rancher/k3s/k3s.yaml

export KUBECONFIG="$(pwd)/kubeconfig"         
kubectl config use-context default
echo "installation de calico"
$CALICO
echo "installation de metallb"
$METALLB
echo "installation de longhorn"
$LONGHORN
kubectl get node -o wide

