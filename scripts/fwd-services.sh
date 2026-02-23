#!/usr/bin/env bash
# This script sets up port forwarding for various services in the Kubernetes cluster. It forwards the Vault service, Prometheus node exporter, Grafana, and Prometheus server to local ports for easy access.

set -euo pipefail

kubectl port-forward -n vault-ns svc/vault 8200:8200 >/tmp/vault-pf.log 2>&1 &
kubectl port-forward -n monitoring-ns svc/prometheus-prometheus-node-exporter 9100:9100 >/tmp/exporter-pf.log 2>&1 &
kubectl port-forward -n monitoring-ns svc/prometheus-grafana 3000:80 >/tmp/grafana-pf.log 2>&1 &
kubectl port-forward -n monitoring-ns svc/prometheus-kube-prometheus-prometheus 9090:9090 >/tmp/prometheus-pf.log 2>&1 &
# kubectl port-forward -n monitoring-ns svc/prometheus-cloudwatch-exporter 9106:9106 >/tmp/cloudwatch-pf.log 2>&1 &
