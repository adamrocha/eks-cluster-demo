#!/usr/bin/env bash

aws s3api create-bucket \
  --bucket terraform-state-bucket-2727 \
  --region us-east-1
