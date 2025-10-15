export AWS_PAGER :=
SHELL := /bin/bash
S3_BUCKET=terraform-state-bucket-2727
DYNAMO_TABLE=terraform-locks
AWS_REGION=us-east-1
TF_DIR=terraform

.PHONY: check-aws

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
	cd $(TF_DIR) && terraform fmt
	@echo "✅ Terraform files formatted."

tf-init:
	cd $(TF_DIR) && terraform init
	@echo "✅ Terraform initialized."

tf-validate:
	cd $(TF_DIR) && terraform validate
	@echo "✅ Terraform configuration validated."

tf-plan:
	cd $(TF_DIR) && terraform plan
	@echo "✅ Terraform plan completed."

tf-apply:
	cd $(TF_DIR) && terraform apply
	@echo "✅ Terraform resources deployed."

tf-destroy:
	cd $(TF_DIR) && terraform destroy
	@echo "✅ Terraform resources destroyed."

tf-output:
	cd $(TF_DIR) && terraform output
	@echo "✅ Terraform outputs displayed."
	@echo "🔍 To view specific output, run 'terraform output <output_name>'."

tf-state:
	cd $(TF_DIR) && terraform state list
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
