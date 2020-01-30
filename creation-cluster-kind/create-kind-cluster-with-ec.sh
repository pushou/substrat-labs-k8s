export KUBECONFIG=""
echo "creation du cluster kind avec la feature-gate ephemeral-container" 
cat <<EOF | kind create cluster --config=-
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
- role: worker
- role: worker
- role: worker
EOF
sleep 5

echo  "switching sur le cluster kind.."
kubectl cluster-info --context kind-kind 
