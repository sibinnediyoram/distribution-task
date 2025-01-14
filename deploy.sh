#!/bin/bash
# Function to check command success
check_command() {
    if [[ $? -ne 0 ]]; then
        echo "$1 failed"
        exit 1
    else
        echo "$1 completed successfully"
    fi
}

#create kind cluster
echo "Creating kind cluster..."
cat <<EOF | kind create cluster --name sibin-mini-cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
    - containerPort: 80
      hostPort: 80
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      protocol: TCP
EOF
check_command "Kind cluster creation"

# Deploy Ingress Controller
echo "Deploying Ingress Controller..."
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
check_command "Ingress controller deployment"

# Deploy Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
check_command "Metrics server deployment"

# Define an array of namespaces
NAMESPACES=("vikunja-app" "redis" "typesense" "monitoring")

# Create namespaces
echo "Creating namespaces..."
for NS in "${NAMESPACES[@]}"; do
    kubectl create ns "$NS"
done

echo "Namespaces created: ${NAMESPACES[*]}"

# Deploy applications using Helm
echo "Deploying applications..."
# Make sure that the local machine have helm installed
helm install redis redis -n redis
check_command "Redis deployment"

helm install typesense typesense -n typesense
check_command "Typesense deployment"

helm install vikunja-db vikunja-db -n vikunja-app
check_command "Vikunja DB deployment"

helm install vikunja-backend vikunja-backend -n vikunja-app
check_command "Vikunja backend deployment"

helm install vikunja-frontend vikunja-frontend -n vikunja-app
check_command "Vikunja frontend deployment"

helm install vikunja-prometheus prometheus -n monitoring
check_command "Prometheus deployment"

helm install vikunja-grafana grafana -n monitoring
check_command "Grafana deployment"

echo "All operations completed successfully!"
