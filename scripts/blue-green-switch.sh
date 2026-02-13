#!/usr/bin/env bash
#
# Blue/Green Deployment Switch Script
# This script switches traffic between blue and green deployments
#

set -euo pipefail

NAMESPACE="${NAMESPACE:-hello-world-ns}"
SERVICE_NAME="hello-world-service"
SERVICE_FILE="manifests/blue-green/hello-world-service.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo -e "${BLUE}Usage:${NC} $0 [blue|green|status|rollback]"
    echo ""
    echo "Commands:"
    echo "  blue      - Switch traffic to blue deployment"
    echo "  green     - Switch traffic to green deployment"
    echo "  status    - Show current active deployment"
    echo "  rollback  - Rollback to previous deployment"
    echo ""
    exit 1
}

# Get current active version
get_current_version() {
    kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" \
        -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "unknown"
}

# Get deployment status
get_deployment_status() {
    local version=$1
    local deployment_name="hello-world-${version}"
    
    if ! kubectl get deployment "$deployment_name" -n "$NAMESPACE" &>/dev/null; then
        echo "NOT_FOUND"
        return
    fi
    
    local ready
    ready=$(kubectl get deployment "$deployment_name" -n "$NAMESPACE" \
        -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired
    desired=$(kubectl get deployment "$deployment_name" -n "$NAMESPACE" \
        -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [[ "$ready" == "$desired" ]] && [[ "$ready" != "0" ]]; then
        echo "READY"
    else
        echo "NOT_READY ($ready/$desired)"
    fi
}

# Show status
show_status() {
    local current
    current=$(get_current_version)
    local blue_status
    blue_status=$(get_deployment_status "blue")
    local green_status
    green_status=$(get_deployment_status "green")
    
    echo -e "\n${BLUE}=== Blue/Green Deployment Status ===${NC}\n"
    echo -e "Current Active Version: ${GREEN}${current}${NC}"
    echo ""
    echo -e "Blue Deployment:  ${blue_status}"
    echo -e "Green Deployment: ${green_status}"
    echo ""
    
    # Show pod information
    echo -e "${BLUE}=== Pod Status ===${NC}\n"
    kubectl get pods -n "$NAMESPACE" -l app=hello-world \
        --sort-by=.metadata.labels.version -o wide 2>/dev/null || true
}

# Switch to version
switch_to_version() {
    local target_version=$1
    local current_version
    current_version=$(get_current_version)
    
    echo -e "\n${BLUE}=== Blue/Green Deployment Switch ===${NC}\n"
    echo -e "Current version: ${current_version}"
    echo -e "Target version:  ${target_version}\n"
    
    # Check if target deployment exists and is ready
    local deployment_status
    deployment_status=$(get_deployment_status "$target_version")
    if [[ "$deployment_status" == "NOT_FOUND" ]]; then
        echo -e "${RED}Error: Deployment hello-world-${target_version} not found${NC}"
        exit 1
    fi
    
    if [[ "$deployment_status" != "READY" ]]; then
        echo -e "${YELLOW}Warning: Target deployment is not fully ready: ${deployment_status}${NC}"
        read -p "Do you want to continue? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
            echo "Aborted"
            exit 1
        fi
    fi
    
    if [[ "$current_version" == "$target_version" ]]; then
        echo -e "${YELLOW}Already on ${target_version} version${NC}"
        return 0
    fi
    
    # Confirm switch
    echo -e "${YELLOW}This will switch traffic from ${current_version} to ${target_version}${NC}"
    read -p "Continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        echo "Aborted"
        exit 1
    fi
    
    # Perform the switch
    echo -e "\n${BLUE}Switching traffic to ${target_version}...${NC}"
    
    kubectl patch service "$SERVICE_NAME" -n "$NAMESPACE" \
        -p "{\"spec\":{\"selector\":{\"version\":\"${target_version}\"}}}" \
        --type=merge
    
    kubectl annotate service "$SERVICE_NAME" -n "$NAMESPACE" \
        "blue-green/active-version=${target_version}" \
        "blue-green/switched-at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        "blue-green/previous-version=${current_version}" \
        --overwrite
    
    echo -e "${GREEN}✓ Successfully switched to ${target_version}${NC}\n"
    
    # Wait a moment and verify
    sleep 2
    local new_version
    new_version=$(get_current_version)
    if [[ "$new_version" == "$target_version" ]]; then
        echo -e "${GREEN}✓ Verification successful: Service is now routing to ${target_version}${NC}"
    else
        echo -e "${RED}✗ Verification failed: Service is routing to ${new_version}${NC}"
        exit 1
    fi
    
    echo -e "\n${BLUE}Service endpoints:${NC}"
    kubectl get service "$SERVICE_NAME" -n "$NAMESPACE"
}

# Rollback to previous version
rollback() {
    local current_version
    current_version=$(get_current_version)
    local previous_version
    previous_version=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" \
        -o jsonpath='{.metadata.annotations.blue-green/previous-version}' 2>/dev/null || echo "")
    
    if [[ -z "$previous_version" ]] || [[ "$previous_version" == "null" ]]; then
        echo -e "${RED}Error: No previous version found to rollback to${NC}"
        exit 1
    fi
    
    echo -e "\n${YELLOW}Rolling back from ${current_version} to ${previous_version}${NC}"
    switch_to_version "$previous_version"
}

# Main script logic
case "${1:-}" in
    blue)
        switch_to_version "blue"
        ;;
    green)
        switch_to_version "green"
        ;;
    status)
        show_status
        ;;
    rollback)
        rollback
        ;;
    *)
        usage
        ;;
esac
