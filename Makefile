export AWS_PAGER :=
SHELL := /bin/bash
S3_BUCKET=terraform-state-bucket-2727
DYNAMO_TABLE=terraform-locks
AWS_REGION=us-east-1
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(pass aws/dev/aws_account_id)}"
TF_DIR=terraform

.PHONY: check-aws help

.DEFAULT_GOAL := help

help:
	@echo "📚 EKS Cluster Demo - Available Commands"
	@echo ""
	@echo "🔧 Terraform Commands:"
	@echo "  make tf-bootstrap        - Initialize and validate Terraform"
	@echo "  make tf-bucket           - Create S3 bucket for state"
	@echo "  make tf-locks            - Create DynamoDB table for locks"
	@echo "  make tf-init             - Initialize Terraform"
	@echo "  make tf-validate         - Validate Terraform configuration"
	@echo "  make tf-plan             - Preview infrastructure changes"
	@echo "  make tf-apply            - Apply infrastructure changes"
	@echo "  make tf-destroy          - Destroy all infrastructure"
	@echo "  make tf-destroy-clean    - Delete K8s resources, LBs, SGs, then destroy"
	@echo "  make tf-output           - Display Terraform outputs"
	@echo "  make tf-state            - List Terraform state"
	@echo ""
	@echo "☸️  Kubernetes Manifest Commands:"
	@echo "  make k8s-validate        - Validate manifests (client-side)"
	@echo "  make k8s-validate-server - Validate against cluster (server-side)"
	@echo "  make k8s-apply           - Deploy all manifests"
	@echo "  make k8s-status          - Check deployment status"
	@echo "  make k8s-logs            - View application logs"
	@echo "  make k8s-shell           - Open shell in running container"
	@echo "  make k8s-describe        - Describe deployment"
	@echo "  make k8s-restart         - Restart deployment"
	@echo "  make k8s-delete          - Delete all manifests"
	@echo ""
	@echo "🎨 Kustomize Commands:"
	@echo "  make k8s-kustomize-validate - Validate kustomize config"
	@echo "  make k8s-kustomize-apply    - Deploy with kustomize"
	@echo "  make k8s-kustomize-diff     - Preview changes"
	@echo "  make k8s-kustomize-delete   - Delete resources"
	@echo ""
	@echo "🛠️  Utility Commands:"
	@echo "  make install-tools       - Install required tools"
	@echo "  make check-aws           - Verify AWS credentials"
	@echo "  make help                - Show this help message"
	@echo ""

check-aws:
	@echo "🔍 Checking AWS credentials..."
	@if ! aws sts get-caller-identity > /dev/null 2>&1; then \
		echo "⚠️  AWS CLI not authenticated. Running aws configure..."; \
		aws configure; \
	else \
		echo "✅ AWS credentials valid."; \
	fi

install-tools:
	@echo "🚀 Running install-tools script..."
	@/bin/bash ./scripts/install-tools.sh

tf-bootstrap: tf-bucket tf-format tf-init tf-validate tf-plan
	@echo "🔄 Running Terraform bootstrap..."
	@echo "✅ Terraform tasks completed successfully."
	@echo "🚀 To apply changes, run 'make tf-apply'."

tf-bucket: check-aws
	@echo "🔍 Checking S3 bucket: $(S3_BUCKET)"
	@if aws s3api head-bucket --bucket "$(S3_BUCKET)" --region "$(AWS_REGION)" > /dev/null 2>&1; then \
		echo "✅ Bucket $(S3_BUCKET) already exists."; \
		exit 0; \
	else \
		echo "🚀 Creating bucket $(S3_BUCKET)..."; \
		if [ "$(AWS_REGION)" = "us-east-1" ]; then \
			aws s3api create-bucket --bucket "$(S3_BUCKET)" --region "$(AWS_REGION)"; \
		else \
			aws s3api create-bucket --bucket "$(S3_BUCKET)" --region "$(AWS_REGION)" \
				--create-bucket-configuration LocationConstraint="$(AWS_REGION)"; \
		fi; \
		echo "🛡️  Enabling versioning on bucket $(S3_BUCKET)..."; \
		aws s3api put-bucket-versioning \
			--bucket "$(S3_BUCKET)" \
			--versioning-configuration Status=Enabled \
			--region "$(AWS_REGION)"; \
		echo "🔐 Enabling server-side encryption on bucket $(S3_BUCKET)..."; \
		aws s3api put-bucket-encryption \
			--bucket "$(S3_BUCKET)" \
			--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
			--region "$(AWS_REGION)"; \
		echo "✅ Bucket $(S3_BUCKET) created with versioning and encryption."; \
	fi

tf-locks: check-aws
	@echo "🔍 Checking DynamoDB table: $(DYNAMO_TABLE)"
	@if aws dynamodb describe-table --table-name "$(DYNAMO_TABLE)" --region "$(AWS_REGION)" > /dev/null 2>&1; then \
		echo "✅ Table $(DYNAMO_TABLE) already exists."; \
	else \
		echo "🚀 Creating table $(DYNAMO_TABLE)..."; \
		aws dynamodb create-table \
			--table-name "$(DYNAMO_TABLE)" \
			--attribute-definitions AttributeName=LockID,AttributeType=S \
			--key-schema AttributeName=LockID,KeyType=HASH \
			--billing-mode PAY_PER_REQUEST \
			--region "$(AWS_REGION)"; \
		echo "✅ DynamoDB table $(DYNAMO_TABLE) created."; \
	fi

tf-clean-lock: check-aws
	@echo "🧹 Cleaning up stale Terraform lock..."
	aws s3 cp s3://$(S3_BUCKET)/envs/dev/terraform.tfstate ./terraform.tfstate.backup || echo "No state backup found."
	aws dynamodb delete-item \
		--table-name $(DYNAMO_TABLE) \
		--key '{"LockID": {"S": "envs/dev/terraform.tfstate"}}'
	@echo "✅ Cleanup complete. Terraform can recreate the lock and state."



tf-format:
	terraform -chdir=$(TF_DIR) fmt
	@echo "✅ Terraform files formatted."

tf-init:
	terraform -chdir=$(TF_DIR) init
	@echo "✅ Terraform initialized."

tf-validate:
	terraform -chdir=$(TF_DIR) validate
	@echo "✅ Terraform configuration validated."

tf-plan:
	terraform -chdir=$(TF_DIR) plan
	@echo "✅ Terraform plan completed."

tf-apply:
	terraform -chdir=$(TF_DIR) apply
	@echo "✅ Terraform resources deployed."

tf-destroy: k8s-delete
	terraform -chdir=$(TF_DIR) destroy 
	@echo "✅ Terraform resources destroyed."

# tf-destroy-clean: k8s-delete
# 	@echo "🧹 Cleaning up Load Balancers and Security Groups..."
# 	@./scripts/cleanup_lb.sh hello-world-ns || true
# 	@sleep 5
# 	@./scripts/cleanup_sg.sh || true
# 	@echo "🚀 Running Terraform destroy..."
# 	cd $(TF_DIR) && terraform destroy
# 	@echo "✅ Terraform resources destroyed with cleanup."

tf-output:
	terraform -chdir=$(TF_DIR) output
	@echo "✅ Terraform outputs displayed."
	@echo "🔍 To view specific output, run 'terraform output <output_name>'."

tf-state:
	terraform -chdir=$(TF_DIR) state list
	@echo "✅ Terraform state listed."
	@echo "🔍 To view specific resource, run 'terraform state show <resource_name>'."

tf-delete-ecr-repo:
	@echo "⚠️  Deleting ECR repository: hello-world-demo"
	@aws ecr delete-repository --repository-name hello-world-demo --region $(AWS_REGION) --force
	@echo "✅ ECR repository 'hello-world-demo' deleted."

# make nuke : Interactive (default)
# make nuke DRY_RUN=1 : Dry run (show what would be deleted, don’t delete)
# make nuke FORCE=1 : Non-interactive force delete (useful in CI/CD)
# make nuke FORCE=1 DRY_RUN=1 : Non-interactive dry run in CI

nuke_tf_bucket: check-aws
	@if [ "$(FORCE)" = "1" ]; then \
		confirm="y"; \
	else \
		echo "⚠️  WARNING: This will delete the S3 bucket: $(S3_BUCKET)"; \
		read -p "Are you sure? (y/N): " confirm; \
	fi; \
	if [ "$$confirm" = "y" ]; then \
		set -euo pipefail; \
		echo "🔄 Scanning bucket for versioned objects..."; \
		while true; do \
			output=$$(aws s3api list-object-versions --bucket $(S3_BUCKET) --output json); \
			delete_json=$$(echo "$$output" | jq '[.Versions[]?, .DeleteMarkers[]?] | map({Key: .Key, VersionId: .VersionId})'); \
			count=$$(echo "$$delete_json" | jq 'length'); \
			if [ "$$count" -eq 0 ]; then \
				break; \
			fi; \
			echo "   found $$count objects..."; \
			for start in $$(seq 0 1000 $$count); do \
				batch=$$(echo "$$delete_json" | jq -c ".[$$start:$$start+1000]"); \
				batch_count=$$(echo "$$batch" | jq 'length'); \
				if [ "$$batch_count" -gt 0 ]; then \
					if [ "$(DRY_RUN)" = "1" ]; then \
						echo "   [DRY RUN] would delete $$batch_count objects:"; \
						echo "$$batch" | jq -r '.[].Key + " (" + .VersionId + ")"'; \
					else \
						echo "   deleting $$batch_count objects..."; \
						echo "$$batch" | jq '{Objects: ., Quiet: false}' | \
							aws s3api delete-objects --bucket $(S3_BUCKET) --delete file:///dev/stdin >/dev/null; \
					fi; \
				fi; \
			done; \
			[ "$(DRY_RUN)" = "1" ] && break; \
		done; \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "❎ DRY RUN complete. Bucket NOT deleted."; \
		else \
			echo "❌ Deleting bucket..."; \
			aws s3api delete-bucket --bucket $(S3_BUCKET) --region $(AWS_REGION); \
			echo "✅ Bucket $(S3_BUCKET) deleted."; \
		fi; \
	else \
		echo "❎ Aborted."; \
	fi

# Kubernetes Manifest Deployment Targets
k8s-validate:
	@echo "🔍 Validating Kubernetes manifests..."
	@echo "--- Validating namespace ---"
	kubectl apply --dry-run=client -f manifests/hello-world-ns.yaml
	@echo "--- Validating deployment ---"
	kubectl apply --dry-run=client -f manifests/hello-world-deployment.yaml
	@echo "--- Validating service ---"
	kubectl apply --dry-run=client -f manifests/hello-world-service.yaml
	@echo "✅ All manifests are valid."

k8s-validate-server:
	@echo "🔍 Validating manifests against cluster (server-side)..."
	@echo "--- Validating namespace ---"
	kubectl apply --dry-run=server -f manifests/hello-world-ns.yaml
	@echo "--- Validating deployment ---"
	kubectl apply --dry-run=server -f manifests/hello-world-deployment.yaml
	@echo "--- Validating service ---"
	kubectl apply --dry-run=server -f manifests/hello-world-service.yaml
	@echo "✅ All manifests are valid against cluster."

k8s-apply-ns:
	@echo "🚀 Creating namespace..."
	kubectl apply -f manifests/hello-world-ns.yaml
	@echo "✅ Namespace created."

k8s-apply: k8s-apply-ns
	@echo "🚀 Deploying Kubernetes manifests..."
	kubectl apply -f manifests/hello-world-deployment.yaml
	kubectl apply -f manifests/hello-world-service.yaml
	@echo "✅ Kubernetes resources deployed."

k8s-delete:
	@echo "⚠️  WARNING: This will delete all Kubernetes resources."
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🗑️  Deleting Kubernetes manifests..."; \
		kubectl delete -f manifests/hello-world-service.yaml --ignore-not-found=true; \
		kubectl delete -f manifests/hello-world-deployment.yaml --ignore-not-found=true; \
		kubectl delete -f manifests/hello-world-ns.yaml --ignore-not-found=true; \
		echo "⏳ Waiting for resources to be fully deleted..."; \
		sleep 30; \
		echo "✅ Kubernetes resources deleted."; \
	else \
		echo "❎ Deletion cancelled."; \
	fi

k8s-undo:
	@echo "🔄 Undoing last applied Kubernetes manifests..."
	kubectl rollout undo deployment/hello-world -n hello-world-ns
	@echo "✅ Undo complete."

k8s-status:
	@echo "📊 Checking Kubernetes deployment status..."
	@echo "--- Namespace ---"
	kubectl get namespace hello-world-ns 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "--- Deployments ---"
	kubectl get deployments -n hello-world-ns 2>/dev/null || echo "No deployments found"
	@echo ""
	@echo "--- Pods ---"
	kubectl get pods -n hello-world-ns 2>/dev/null || echo "No pods found"
	@echo ""
	@echo "--- Services ---"
	kubectl get services -n hello-world-ns 2>/dev/null || echo "No services found"
	@echo ""
	@echo "--- LoadBalancer URL ---"
	@kubectl get service hello-world-service -n hello-world-ns -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null && echo "" || echo "LoadBalancer not ready yet"

k8s-logs:
	@echo "📜 Fetching logs from hello-world deployment..."
	kubectl logs -n hello-world-ns -l app=hello-world --tail=100

k8s-shell:
	@echo "🐚 Opening shell in hello-world container..."
	@POD=$$(kubectl get pod -n hello-world-ns -l app=hello-world -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
		echo "❌ No running pods found in hello-world-ns"; \
		exit 1; \
	fi; \
	echo "📦 Connecting to pod: $$POD"; \
	kubectl exec -it -n hello-world-ns $$POD -- sh

k8s-events:
	@echo "📜 Fetching events from hello-world namespace..."
	kubectl get events -n hello-world-ns --sort-by='.metadata.creationTimestamp'

k8s-describe:
	@echo "🔍 Describing hello-world deployment..."
	kubectl describe deployment hello-world -n hello-world-ns

k8s-restart:
	@echo "🔄 Restarting hello-world deployment..."
	kubectl rollout restart deployment/hello-world -n hello-world-ns
	@echo "✅ Deployment restarted."

# Kustomize-based deployment (alternative to direct kubectl apply)
k8s-kustomize-validate:
	@echo "🔍 Validating Kustomize configuration..."
	kubectl apply --dry-run=client -k manifests/
	@echo "✅ Kustomize configuration is valid."

k8s-kustomize-apply:
	@echo "🚀 Deploying with Kustomize..."
	kubectl apply -k manifests/
	@echo "✅ Kubernetes resources deployed via Kustomize."

k8s-kustomize-delete:
	@echo "🗑️  Deleting with Kustomize..."
	kubectl delete -k manifests/ --ignore-not-found=true
	@echo "✅ Kubernetes resources deleted via Kustomize."

k8s-kustomize-diff:
	@echo "🔍 Showing diff with Kustomize..."
	kubectl diff -k manifests/ || true
