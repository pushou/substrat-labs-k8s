# create registry container unless it already exists
unset KUBECONFIG
ip_hote=$(hostname -I|awk  '{print $1}')
reg_name='kind-registry'
reg_port='5000'
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi
export KUBECONFIG=""
kind delete cluster --name tp1k8s
echo "creation du cluster kind avec la feature-gate ephemeral-container" 
# connect the registry to the cluster network
# (the network may already be connected)
docker network connect "kind" "${reg_name}" || true
cat <<EOF | kind create cluster --name tp1k8s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
kubeadmConfigPatches:
# enable EphemeralContainers feature gate
- |
  kind: ClusterConfiguration
  metadata:
    name: config
  apiServer:
    extraArgs:
      "feature-gates": "EphemeralContainers=true,CSIInlineVolume=true"
  scheduler:
    extraArgs:
      "feature-gates": "EphemeralContainers=true,CSIInlineVolume=true"
  controllerManager:
    extraArgs:
      "feature-gates": "EphemeralContainers=true,CSIInlineVolume=true"
- |
  kind: InitConfiguration
  metadata:
    name: config
  nodeRegistration:
    kubeletExtraArgs:
      "feature-gates": "EphemeralContainers=true,CSIInlineVolume=true"
- |
  kind: KubeletConfiguration
  featureGates:
    EphemeralContainers: true
    CSIInlineVolume: true
- |
  kind: KubeProxyConfiguration
  featureGates:
    EphemeralContainers: true
    CSIInlineVolume: true
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:${reg_port}"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true,run=haproxy-ingress"
        authorization-mode: "AlwaysAllow"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 1024
    hostPort: 1024
    protocol: TCP
  - containerPort: 30777
    hostPort: 9000
    protocol: TCP
  extraMounts:
  - hostPath: ./shared-storage
    containerPath: /var/local-path-provisioner
- role: worker
  extraPortMappings:
  - containerPort: 9200
    hostPort: 8001
    # optional: set the bind address on the host
    # 0.0.0.0 is the current default
    listenAddress: "127.0.0.0"
    # optional: set the protocol to one of TCP, UDP, SCTP.
    # TCP is the default
    protocol: TCP
- role: worker
  extraPortMappings:
  - containerPort: 9200
    hostPort: 8002
    # optional: set the bind address on the host
    # 0.0.0.0 is the current default
    listenAddress: "127.0.0.0"
    # optional: set the protocol to one of TCP, UDP, SCTP.
    # TCP is the default
    protocol: TCP
  extraMounts:
  - hostPath: ./shared-storage
    containerPath: /var/local-path-provisioner
- role: worker
  extraPortMappings:
  - containerPort: 9200
    hostPort: 8003
    # optional: set the bind address on the host
    # 0.0.0.0 is the current default
    listenAddress: "127.0.0.0"
    # optional: set the protocol to one of TCP, UDP, SCTP.
    # TCP is the default
    protocol: TCP
  extraMounts:
  - hostPath: ./shared-storage
    containerPath: /var/local-path-provisioner
    readOnly: False
networking:
  podSubnet: "10.244.0.0/16"
  apiServerPort: 6443
  apiServerAddress: ${ip_hote}
#  disableDefaultCNI: True
EOF
sleep 5

unset KUBECONFIG
echo  "switching sur le cluster kind.."
kubectl cluster-info --context kind-tp1k8s
kind get  kubeconfig --name  tp1k8s > kindkubeconfig
#kind --name tp1k8s export  kubeconfig > kindkubeconfig
echo  "installation du serveur de métriques"
kubectl apply -f components.yaml


# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo  "installation de nerdctl"


for cont in $(docker ps |grep -v registry|grep -i kindest|awk '{print $1}'|grep -v CONTAINER); do docker exec -it $cont  bash -c "apt update && apt -y install wget && cd /tmp && wget https://github.com/containerd/nerdctl/releases/download/v0.18.0/nerdctl-0.18.0-linux-amd64.tar.gz && tar xvfz nerdctl-0.18.0-linux-amd64.tar.gz && mv /tmp/nerdctl /usr/local/bin/nerdctl "; done  

export KUBECONFIG=$(pwd)/kubeconfig

#echo  "installation open-iscsi"
#for cont in $(docker ps -q); do docker exec -it $cont  bash -c "apt-get update && apt-get -y install open-iscsi"; done
