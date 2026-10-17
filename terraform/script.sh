#!/usr/bin/env bash
set -euo pipefail
if [[ -z "${ADMIN_CIDR:-}" ]]; then
  echo "Set ADMIN_CIDR to your public IPv4 address with /32 first."
  echo "Example: export ADMIN_CIDR=YOUR_PUBLIC_IPV4/32"
  exit 1
fi
terraform init
terraform fmt -check
terraform validate
terraform plan -var="admin_cidr=$ADMIN_CIDR"
terraform apply -var="admin_cidr=$ADMIN_CIDR"
