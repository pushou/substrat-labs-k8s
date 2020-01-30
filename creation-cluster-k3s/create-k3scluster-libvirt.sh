#!/bin/bash
export PATH=/snap/bin:/usr/local/bin:/usr/local/sbin:$PATH
#export SSH_KEYS="~/.ssh/id_rsa"
export SSH_KEYS="/var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa"

if ! [ -x "$(command -v multipass)" ]; then
  echo 'install multipass' >&2
  sudo apt update
  sudo apt install snapd
  sudo snap install multipass --beta --classic
  sudo multipass set local.driver=libvirt
fi


if [ $(multipass get local.driver) != 'libvirt' ]; then
    sudo multipass set local.driver=libvirt
fi

if ! [ -x "$(command -v k3s)" ]; then
  echo 'install k3s' >&2
  curl -sfL https://get.k3s.io | sh -
fi
if ! [ -x "$(command -v k3sup)" ]; then
  echo 'install k3sup' >&2
  curl -sLS https://get.k3sup.dev | sudo sh
fi

multipass launch bionic -n master -c 2 -m 4G --disk 10G --cloud-init cloud-config.yaml
for node in node{1..3}; do echo "create node $node"; multipass launch bionic --disk 10G -n $node --cloud-init cloud-config.yaml; done


ipadr=$(multipass list|grep node|awk '{print $3}')
ipmaster=$(multipass list|grep master|awk '{print $3}')

sudo k3sup install --user ubuntu  --ip  $ipmaster --ssh-key  $SSH_KEYS
for ipnode in $(echo $ipadr) ; do sudo k3sup join --user ubuntu  --ip  $ipnode --server-ip  $ipmaster --ssh-key $SSH_KEYS  ; done
multipass exec master -- sudo chmod 644 /etc/rancher/k3s/k3s.yaml

export KUBECONFIG="./kubeconfig"         
kubectl get node -o wide
