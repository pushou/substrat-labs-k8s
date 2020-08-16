#!/bin/bash
shopt -s expand_aliases
alias k='kubectl'
k apply -f $(pwd)/calico.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calicoctl.yaml
kubectl exec -ti -n kube-system calicoctl -- /calicoctl get profiles -o wide
alias calicoctl="kubectl exec -ti -n kube-system calicoctl -- /calicoctl"
#kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true
