#!/bin/bash
shopt -s expand_aliases
alias k='kubectl'
helm install nginx-ingress stable/nginx-ingress --namespace kube-system --set defaultBackend.enabled=false
k apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
USER=longhorn; PASSWORD=longhorn; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
k -n longhorn-system create secret generic basic-auth --from-file=auth
k apply -f longhorn-ingress.yaml
k apply -f longhorn-service.yaml
#k apply -f  longhorn-example-mysql.yaml
k get pods --namespace longhorn-system
k get services  -n kube-system -l app=nginx-ingress -o wide
