# wordpress-k3s

A kubectl YAML to deploy Wordpress on Kubernetes

## Post-Installation

You can tune the prod or dev Kustomize Overlay with :
- wordpress-deployment.yaml : to match your storage driver (in my example I use a NFS driver),
- wordpress-ingressroute.yaml : to match your FQDN.

## Installation 

```bash
git clone https://github.com/kyzdev/wordpress-k3s
cd wordpress-k3s
kubectl apply -k overlays/<env>
```
## Uninstallation

```bash
kubectl delete namespace <env>-wordpress
```

## Credits

https://www.grottedubarbu.fr/wordpress-kubernetes-traefik/