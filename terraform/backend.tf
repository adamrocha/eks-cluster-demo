# terraform {
#   backend "s3" {
#     bucket = "terraform-state-bucket-1337-8647"
#     key    = "eks/terraform.tfstate"
#     region = "us-east-1"
#     //dynamodb_table = "terraform-locks"
#     encrypt = true
#   }
# }
