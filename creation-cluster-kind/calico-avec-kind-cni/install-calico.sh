#!/bin/bash
shopt -s expand_aliases
alias k='kubectl'
k apply -f $(pwd)/calico.yaml
#kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true
