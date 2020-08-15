#!/bin/bash
kubectl apply -f manifests/pv-claim.yaml
kubectl apply -f manifests/pv-deploy.yaml
#kubectl scale deploy/pv-deploy --replicas=3
