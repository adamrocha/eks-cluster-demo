S3_BUCKET=terraform-state-bucket-2727
AWS_REGION=us-east-1
TF_DIR=terraform

.PHONY: default init-bucket check-aws clean

default: check-aws init-bucket

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

clean: check-aws
	@echo "⚠️  WARNING: This will delete the S3 bucket: $(S3_BUCKET)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		echo "🔄 Emptying bucket..."; \
		aws s3 rm s3://$(S3_BUCKET) --recursive || true; \
		echo "❌ Deleting bucket..."; \
		aws s3api delete-bucket --bucket $(S3_BUCKET) --region $(AWS_REGION); \
		echo "✅ Bucket $(S3_BUCKET) deleted."; \
	else \
		echo "❎ Aborted."; \
	fi
