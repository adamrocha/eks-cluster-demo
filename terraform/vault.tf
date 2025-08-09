resource "helm_release" "vault" {
  name       = "vault"
  namespace  = "vault-ns"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.28.0"

  create_namespace = true

  set {
    name  = "server.dev.enabled"
    value = "true"
  }
}

resource "null_resource" "vault_port_forward" {
  depends_on = [helm_release.vault]

  provisioner "local-exec" {
    command = <<EOT
      echo "Starting Vault port-forward..."
      kubectl port-forward svc/vault -n vault-ns 8200:8200 >/tmp/vault-pf.log 2>&1 &
      echo "Vault UI should be available at http://localhost:8200/ui"
      echo "To stop port-forward, kill the background process:"
      echo "  pkill -f 'kubectl port-forward svc/vault -n vault-ns 8200:8200'"
    EOT
    # Keep this running during apply, or run detached (this is a simple fire-and-forget)
  }
}


# resource "null_resource" "wait_for_vault" {
#   depends_on = [helm_release.vault]

#   provisioner "local-exec" {
#     command = <<EOT
#       echo "Waiting for Vault to be ready..."
#       kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=180s
#     EOT
#   }
# }

# resource "null_resource" "vault_init" {
#   depends_on = [null_resource.wait_for_vault]

#   provisioner "local-exec" {
#     command = <<EOT
#       kubectl exec -n vault-ns vault-0 -- vault operator init -key-shares=1 -key-threshold=1 \
#       > vault_init.txt
#       VAULT_UNSEAL_KEY=$(grep 'Unseal Key 1:' vault_init.txt | awk '{print $4}')
#       VAULT_ROOT_TOKEN=$(grep 'Initial Root Token:' vault_init.txt | awk '{print $4}')
#       kubectl exec -n vault-ns vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
#       echo $VAULT_ROOT_TOKEN > ~/.vault-token
#     EOT
#   }
# }

# resource "null_resource" "vault_store_kubeconfig" {
#   depends_on = [null_resource.vault_init]

#   provisioner "local-exec" {
#     command = <<EOT
#       export VAULT_ADDR=http://$(kubectl get svc vault -n vault-ns -o jsonpath='{.spec.clusterIP}'):8200
#       export VAULT_ROOT_TOKEN=$(cat ~/.vault-token)
#       aws eks update-kubeconfig --name ${aws_eks_cluster.eks.name} --region ${var.region} --dry-run \
#         | vault kv put secret/kubeconfig value=-
#     EOT
#   }
# }

# resource "null_resource" "vault_retrieve_kubeconfig" {
#   depends_on = [null_resource.vault_store_kubeconfig]

#   provisioner "local-exec" {
#     command = <<EOT
#       echo "Starting Vault port-forward for retrieval..."
#       kubectl port-forward svc/vault -n vault-ns 8200:8200 >/tmp/vault-pf.log 2>&1 &
#       PF_PID=$!

#       # Wait for the port to be ready
#       for i in {1..10}; do
#         nc -z localhost 8200 && break
#         sleep 2
#       done

#       export VAULT_ADDR=http://127.0.0.1:8200
#       export VAULT_ROOT_TOKEN=$(cat ~/.vault-token)

#       echo "Retrieving kubeconfig from Vault..."
#       vault kv get -field=value secret/kubeconfig > ~/.kube/config

#       echo "Stopping port-forward..."
#       kill $PF_PID
#     EOT
#   }
# }

