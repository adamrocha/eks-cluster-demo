#!/usr/bin/env bash

# shellcheck disable=SC2046
aws ec2 start-instances \
    --instance-ids $(aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)