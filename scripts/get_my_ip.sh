#!/usr/bin/env bash

IP=$(curl -s https://4.ident.me)
jq -n --arg ip "$IP" '{ip: $ip}'
