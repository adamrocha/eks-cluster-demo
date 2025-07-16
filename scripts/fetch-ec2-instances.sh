#!/usr/bin/env bash

aws ec2 describe-instances \
  --query "Reservations[].Instances[].{ID:InstanceId, Name:Tags[?Key=='Name']|[0].Value, PrivateIP:PrivateIpAddress, PublicIP:PublicIpAddress, State:State.Name, AZ:Placement.AvailabilityZone, Type:InstanceType}" \
  --filters Name=instance-state-name,Values=running \
  --output table
