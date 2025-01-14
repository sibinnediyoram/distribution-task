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

# Set the namespace for Vikunja
NAMESPACE="vikunja-app"

# Function to get pod status
get_pod_status() {
    echo "Fetching pod status in namespace $NAMESPACE..."
    kubectl get pods -n "$NAMESPACE" -o wide
    check_command "Pod status retrieval"
}

# Function to get service status
get_service_status() {
    echo "Fetching service status in namespace $NAMESPACE..."
    kubectl get services -n "$NAMESPACE"
    check_command "Service status retrieval"
}

# Function to get logs for a specific pod
get_pod_logs() {
    echo "Fetching logs for Vikunja pods..."
    PODS=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
    for POD in $PODS; do
        echo "Logs for pod: $POD"
        kubectl logs "$POD" -n "$NAMESPACE" --tail=30 
        echo "-----------------------------------"
    done
}

# Function to check health of the application
check_health() {
    echo "Checking health of Vikunja services..."
    kubectl get pods -n "$NAMESPACE" -l app=vikunja-frontend -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -q "false"
    if [[ $? -eq 0 ]]; then
        echo "One or more frontend pods are not healthy."
    else
        echo "All frontend pods are healthy."
    fi

    kubectl get pods -n "$NAMESPACE" -l app=vikunja-backend -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -q "false"
    if [[ $? -eq 0 ]]; then
        echo "One or more backend pods are not healthy."
    else
        echo "All backend pods are healthy."
    fi

    kubectl get pods -n "$NAMESPACE" -l app=vikunja-db -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -q "false"
    if [[ $? -eq 0 ]]; then
        echo "Database pod is not healthy."
    else
        echo "Database pod is healthy."
    fi
}

# Main script execution
echo "Starting monitoring and troubleshooting for Vikunja application..."

get_pod_status
get_service_status
get_pod_logs
check_health

echo "Monitoring and troubleshooting completed."