S3_BUCKET=terraform-state-bucket-2727
AWS_REGION=us-east-1
TF_DIR=terraform

.PHONY: default init-bucket check-aws clean

default: check-aws init-bucket

tf-run: tf-format tf-init tf-validate tf-plan
	@echo "✅ Terraform tasks completed successfully."
	@echo "🚀 To apply changes, run 'make tf-apply'."
	@echo "🔄 Running Terraform tasks..."

check-aws:
	@echo "🔍 Checking AWS credentials..."
	@if ! aws sts get-caller-identity > /dev/null 2>&1; then \
		echo "⚠️  AWS CLI not authenticated. Running aws configure..."; \
		aws configure; \
	else \
		echo "✅ AWS credentials valid."; \
	fi

init-bucket: check-aws
	@echo "🔍 Checking S3 bucket: $(S3_BUCKET)"
	@if aws s3api head-bucket --bucket "$(S3_BUCKET)" --region "$(AWS_REGION)" > /dev/null 2>&1; then \
		echo "✅ Bucket $(S3_BUCKET) already exists."; \
	else \
		echo "🚀 Creating bucket $(S3_BUCKET)..."; \
		if [ "$(AWS_REGION)" = "us-east-1" ]; then \
			aws s3api create-bucket --bucket "$(S3_BUCKET)" --region "$(AWS_REGION)"; \
		else \
			aws s3api create-bucket --bucket "$(S3_BUCKET)" --region "$(AWS_REGION)" \
				--create-bucket-configuration LocationConstraint="$(AWS_REGION)"; \
		fi; \
	fi

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

clean: check-aws
	@echo "⚠️  WARNING: This will delete the S3 bucket: $(S3_BUCKET)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🔄 Emptying bucket including versioned objects..."; \
		aws s3api list-object-versions --bucket $(S3_BUCKET) \
		--output json | jq -r '.Versions[]?, .DeleteMarkers[]? | [.Key, .VersionId] | @tsv' | \
		while IFS=$$'\t' read -r key version; do \
			aws s3api delete-object --bucket $(S3_BUCKET) --key "$$key" --version-id "$$version"; \
		done; \
		echo "❌ Deleting bucket..."; \
		aws s3api delete-bucket --bucket $(S3_BUCKET) --region $(AWS_REGION); \
		echo "✅ Bucket $(S3_BUCKET) deleted."; \
	else \
		echo "❎ Aborted."; \
	fi