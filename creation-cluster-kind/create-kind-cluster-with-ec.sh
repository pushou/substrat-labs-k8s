export KUBECONFIG=""
kind delete cluster --name tp1k8s
echo "creation du cluster kind avec la feature-gate ephemeral-container" 
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
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        authorization-mode: "AlwaysAllow"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 1936
    hostPort: 1936
    protocol: TCP
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

EOF
sleep 5

echo  "switching sur le cluster kind.."
kubectl cluster-info --context kind-tp1k8s
