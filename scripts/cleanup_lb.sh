#!/bin/bash
export AWS_PAGER=""

set -e

NAMESPACE=$1
REGION="us-east-1"
VPC_NAME="eks-vpc"

echo "⚠️ Cleaning up Kubernetes services..."
# kubectl patch svc prometheus-prometheus -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge || true
# kubectl patch svc prometheus-grafana -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge || true
kubectl patch svc hello-world-service -n hello-world-ns -p '{"metadata":{"finalizers":null}}' --type=merge || true
# kubectl delete svc --all -n "$NAMESPACE" --ignore-not-found || true

echo "⏱️ Sleeping for 10 seconds to ensure services are deleted..."
sleep 10

echo "🧨 Deleting Prometheus Helm release..."
helm uninstall prometheus -n monitoring-ns || true

echo "🔍 Locating VPC with tag Name=$VPC_NAME in region $REGION..."
VPC_ID=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query "Vpcs[0].VpcId" \
  --output text)

if [[ "$VPC_ID" == "None" || -z "$VPC_ID" ]]; then
  echo "❌ VPC named '$VPC_NAME' not found in region '$REGION'. Exiting."
  exit 1
fi

echo "✅ Found VPC: $VPC_ID"

### ALB / NLB
echo "🧨 Deleting ALB/NLBs in VPC: $VPC_ID"
aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" \
  --output text | \
xargs -r -n 1 aws elbv2 delete-load-balancer --region "$REGION" --load-balancer-arn

### Classic ELB
echo "🧨 Deleting Classic ELBs in VPC: $VPC_ID"
aws elb describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" \
  --output text | \
xargs -r -n 1 aws elb delete-load-balancer --region "$REGION" --load-balancer-name

echo "✅ All scoped Load Balancers have been deleted from VPC '$VPC_NAME' ($VPC_ID)."
