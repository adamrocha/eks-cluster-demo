provider "aws" {
  shared_credentials_files = ["$HOME/.aws/credentials"]
  shared_config_files      = ["$HOME/.aws/config"]
  profile                  = "prom_infradmin"
  region                   = "us-east-1"
}