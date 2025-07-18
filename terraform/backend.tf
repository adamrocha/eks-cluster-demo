terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-2727"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
