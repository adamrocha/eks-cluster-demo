#!/bin/bash

# Script to clean up failed Prometheus Helm release and redeploy
# Usage: ./scripts/cleanup-prometheus.sh

set -e

NAMESPACE="monitoring-ns"
RELEASE_NAME="prometheus"

echo "=========================================="
echo "Prometheus Cleanup and Redeployment Script"
echo "=========================================="
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: kubectl is not configured or cluster is not accessible"
    echo "Run: ./scripts/update-kubeconfig.sh"
    exit 1
fi

# Step 1: Remove failed Helm release
echo "Step 1: Removing failed Helm release..."
if helm list -n "$NAMESPACE" 2>/dev/null | grep -q "$RELEASE_NAME"; then
    echo "  → Uninstalling Helm release: $RELEASE_NAME"
    helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" --wait --timeout 5m || true
    echo "  ✓ Helm release removed"
else
    echo "  → No Helm release found (already removed)"
fi
echo ""

# Step 2: Clean up namespace resources
echo "Step 2: Cleaning up namespace resources..."
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "  → Checking for stuck resources in namespace: $NAMESPACE"
    
    # Delete all pods forcefully if stuck
    STUCK_PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running 2>/dev/null | tail -n +2 | wc -l)
    if [ "$STUCK_PODS" -gt 0 ]; then
        echo "  → Found $STUCK_PODS stuck pods, force deleting..."
        kubectl delete pods --all -n "$NAMESPACE" --force --grace-period=0 2>/dev/null || true
    fi
    
    # Delete PVCs if they exist
    if kubectl get pvc -n "$NAMESPACE" &> /dev/null | grep -q prometheus; then
        echo "  → Deleting Prometheus PVCs..."
        kubectl delete pvc -n "$NAMESPACE" -l app.kubernetes.io/name=prometheus --force --grace-period=0 2>/dev/null || true
    fi
    
    # Wait a moment for resources to cleanup
    sleep 5
    
    # Check if namespace is empty, if so delete it
    RESOURCE_COUNT=$(kubectl get all -n "$NAMESPACE" 2>/dev/null | tail -n +2 | wc -l)
    if [ "$RESOURCE_COUNT" -eq 0 ]; then
        echo "  → Namespace is empty, deleting it..."
        kubectl delete namespace "$NAMESPACE" --force --grace-period=0 2>/dev/null || true
        sleep 5
    else
        echo "  → Namespace still has resources, keeping it"
    fi
    
    echo "  ✓ Cleanup completed"
else
    echo "  → Namespace does not exist (already removed)"
fi
echo ""

# Step 3: Check cluster capacity
echo "Step 3: Checking cluster capacity..."
echo "  → Node resources:"
kubectl top nodes 2>/dev/null || echo "  ⚠ Metrics server not available, skipping resource check"
echo "  → Pod capacity:"
kubectl get nodes -o custom-columns=NAME:.metadata.name,ALLOCATABLE:.status.allocatable.pods,CAPACITY:.status.capacity.pods
echo "  → Current pods:"
CURRENT_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l | xargs)
echo "    Total running: $CURRENT_PODS"
echo ""

# Step 4: Reapply Terraform
echo "Step 4: Redeploying Prometheus via Terraform..."
cd "$(dirname "$0")/.."

if [ ! -d "terraform" ]; then
    echo "❌ Error: terraform directory not found"
    exit 1
fi

cd terraform

echo "  → Running terraform init..."
terraform init -upgrade > /dev/null 2>&1

echo "  → Running terraform apply for Prometheus..."
echo ""
echo "⏳ This may take up to 15 minutes. Please wait..."
echo ""

if terraform apply -target=helm_release.prometheus -auto-approve; then
    echo ""
    echo "=========================================="
    echo "✓ Deployment completed!"
    echo "=========================================="
    echo ""
    
    # Wait for pods to be ready
    echo "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n "$NAMESPACE" --timeout=60s 2>/dev/null || true
    
    echo ""
    echo "Current status:"
    kubectl get pods -n "$NAMESPACE"
    echo ""
    
    echo "Helm release status:"
    helm list -n "$NAMESPACE"
    echo ""
    
    echo "Access Grafana:"
    echo "  kubectl port-forward -n $NAMESPACE svc/prometheus-grafana 3000:80"
    echo ""
    echo "Get Grafana password:"
    echo "  kubectl get secret -n $NAMESPACE prometheus-grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode && echo"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ Deployment failed!"
    echo "=========================================="
    echo ""
    echo "Check pod status for errors:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl describe pod -n $NAMESPACE <pod-name>"
    echo ""
    exit 1
fi
