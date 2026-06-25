terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.52"
    }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "~> 3.0"
    # }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
    # http = {
    #   source  = "hashicorp/http"
    #   version = "~> 3.5"
    # }
    # null = {
    #   source  = "hashicorp/null"
    #   version = "~> 3.2"
    # }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.10"
    }
    # external = {
    #   source  = "hashicorp/external"
    #   version = "~> 2.3"
    # }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.3"
    }
  }
}