helm install monhaproxycontroller haproxytech/kubernetes-ingress \
--set controller.kind=DaemonSet \
--set controller.daemonset.useHostPort=true \
--set-string "controller.config.ssl-redirect=false" \
--set controller.service.type=LoadBalancer
