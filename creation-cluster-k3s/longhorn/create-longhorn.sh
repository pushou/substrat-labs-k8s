#!/bin/bash
shopt -s expand_aliases
alias k='kubectl'
k apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
USER=longhorn; PASSWORD=longhorn; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
k -n longhorn-system create secret generic basic-auth --from-file=auth
sleep 60
k apply -f $PWD/longhorn/longhorn-service.yaml
#k patch svc longhorn-frontend -n longhorn-system --patch "$(cat patch-longfrontend-service.yaml)"
k get pods --namespace longhorn-system
