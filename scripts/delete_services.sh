#!/bin/bash

NAMESPACE=$1

echo "⚠️  Deleting LoadBalancer services in namespace: $NAMESPACE..."
kubectl delete svc --all -n "$NAMESPACE" --ignore-not-found

echo "✅  Services deleted."