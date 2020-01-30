#!/bin/bash
export PATH=/snap/bin:/usr/local/bin:/usr/local/sbin:$PATH


if ! [ -x "$(command -v multipass)" ]; then
  echo 'install multipass' >&2
  sudo apt update
  sudo apt install snapd
  sudo snap install multipass --edge --classic
fi

if [ $(multipass get local.driver) != 'qemu' ]; then
    sudo multipass set local.driver=qemu
fi

multipass stop --all
multipass delete --all
multipass purge

if ! [ -x "$(command -v k3s)" ]; then
  echo 'install k3s' >&2
  curl -sfL https://get.k3s.io | sh -
fi
if ! [ -x "$(command -v k3sup)" ]; then
  echo 'install k3sup' >&2
  curl -sLS https://get.k3sup.dev | sudo sh
fi

multipass launch bionic -n master -c 2 
for node in node{1..3}; do  echo "create node $node"; multipass launch bionic -n $node  ; done

ipadr=$(multipass list|grep node|awk '{print $3}')
ipmaster=$(multipass list|grep master|awk '{print $3}')

sudo k3sup install --user ubuntu  --ip  $ipmaster --ssh-key  /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa
for ipadr in $ipadr ; do sudo k3sup join --user ubuntu  --ip  $ipadr --server-ip  $ipmaster --ssh-key /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa  ; done
multipass exec master -- sudo chmod 644 /etc/rancher/k3s/k3s.yaml

sudo chmod 755 ./kubeconfig
export KUBECONFIG="./kubeconfig"         

kubectl get node -o wide

