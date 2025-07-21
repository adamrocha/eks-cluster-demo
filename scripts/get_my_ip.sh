#!/usr/bin/env bash

IP=$(curl -s https://ifconfig.me)
jq -n --arg ip "$IP" '{ip: $ip}'
