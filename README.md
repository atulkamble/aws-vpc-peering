# AWS VPC Peering Project

Hands-on AWS VPC peering between two non-overlapping VPCs in the **same AWS Region**, deployed using Terraform.

## Architecture

```text
Administrator (SSH via public IP; restricted to admin_cidr)
                     |
                  Internet
                     |
                  IGW-A
                     |
VPC-A: 10.0.0.0/16   |        Peering (pcx)       VPC-B: 10.1.0.0/16
+----------------------------+                  +----------------------------+
| Public subnet 10.0.1.0/24  |                  | Private subnet 10.1.1.0/24 |
| VM1 Bastion (public IP)    |<--- private ---> | VM2 EC2 (private IP only)  |
| RT: 0.0.0.0/0 -> IGW       |                  | RT: 10.0.0.0/16 -> pcx     |
| RT: 10.1.0.0/16 -> pcx     |                  | No IGW/NAT default route   |
+----------------------------+                  +----------------------------+
```

**Goal:** SSH to VM1 using its public IP, then test ping/SSH from VM1 to VM2 using VM2's **private IP** over the VPC peering connection.

## Prerequisites

- AWS account, AWS CLI, Terraform >= 1.5, and SSH.
- IAM permissions to provision EC2, VPC networking, security groups, and an EC2 key pair.
- Region `us-east-1` and AZ `us-east-1a` (edit `terraform/variables.tf` if required).
- Two non-overlapping VPC CIDRs: `10.0.0.0/16` and `10.1.0.0/16`.
- A unique EC2 `key_name` for this lab.
- Your own public IPv4 address as `admin_cidr` with `/32` (do not permit `0.0.0.0/0`).

## Deploy

```bash
git clone https://github.com/atulkamble/aws-vpc-peering.git
cd aws-vpc-peering/terraform
aws sts get-caller-identity
terraform init
terraform fmt -check
terraform validate

# Replace with YOUR current public IPv4 /32, not a placeholder:
terraform plan -var='admin_cidr=YOUR_PUBLIC_IPV4/32'
terraform apply -var='admin_cidr=YOUR_PUBLIC_IPV4/32'
```

Terraform provisions VPC-A, VPC-B, subnets, one IGW (A only), subnet route tables, a same-account/same-Region peering connection, restrictive security groups, and two Amazon Linux 2023 EC2 instances. **VM2 has no public IP.**

> The generated `key.pem` and Terraform state contain sensitive private-key material. They must never be committed, uploaded, or shared. For production prefer SSM Session Manager / EC2 Instance Connect Endpoint and externally managed keys.

## Verify AWS resources

```bash
terraform output
aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids "$(terraform output -raw peering_connection_id)" --query 'VpcPeeringConnections[*].Status.Code'
aws ec2 describe-route-tables --route-table-ids "$(terraform output -raw route_table_a_id)" "$(terraform output -raw route_table_b_id)" --query 'RouteTables[*].Routes[*].{Destination:DestinationCidrBlock,Gateway:GatewayId,Peering:VpcPeeringConnectionId,State:State}' --output json
```

Expected peering status: `active`. VPC-A must route `10.1.0.0/16` through peering; VPC-B must route `10.0.0.0/16` through peering. VPC-B has no `0.0.0.0/0` route.

## Connectivity tests

Use the local key file and **ProxyJump** so no private key is copied onto VM1.

```bash
cd terraform                 # Only if currently at the repository root
chmod 400 key.pem
VM1_PUBLIC=$(terraform output -raw vm1_public_ip)
VM2_PRIVATE=$(terraform output -raw vm2_private_ip)

# Test ICMP from VM1 to private VM2:
ssh -i key.pem -o IdentitiesOnly=yes "ec2-user@$VM1_PUBLIC" "ping -c 3 $VM2_PRIVATE"

# SSH to VM2 through public VM1, using the key only on your laptop:
ssh -i key.pem -o IdentitiesOnly=yes -o 'ProxyCommand=ssh -i key.pem -o IdentitiesOnly=yes -W %h:%p ec2-user@'"${VM1_PUBLIC}" "ec2-user@$VM2_PRIVATE"
```

You can also use `ssh -i key.pem -J ec2-user@"$VM1_PUBLIC" ec2-user@"$VM2_PRIVATE"` when your SSH agent offers the correct key to both hosts. Connectivity requires the SG rules and NACLs to permit traffic, and OS firewalls/services must allow the test. For private-to-private ping, the default NACL permits return traffic.

Traffic path: `Laptop -> IGW-A -> VM1 (public IP) -> VPC-A route table -> pcx -> VPC-B route table -> VM2 (private IP)`. The VM1→VM2 hop does **not** pass through the Internet Gateway.

## Cleanup

```bash
cd terraform                 # Only if currently at the repository root
terraform destroy -var='admin_cidr=YOUR_PUBLIC_IPV4/32'
```

Do not manually delete resources before `terraform destroy`, or Terraform state may become inconsistent. Verify resource removal in AWS. EC2 and public IPv4 usage can incur costs.

## Learning points

- VPC CIDRs must not overlap.
- Peering becomes usable only after acceptance (`auto_accept = true` in this same-account/same-Region lab), route entries on both sides, and appropriate SG/NACL rules.
- VPC peering is **not transitive** and does not support edge-to-edge routing through a peer's IGW or NAT gateway.
- VPC peering is supported across AWS Regions and accounts, with additional acceptance/configuration steps.
- Public IP addresses are not necessary for traffic over peering.
- For background, see [Requirements](requirements.md), [VPC Notes](vpc.md), and [Historical connectivity test](terraform/connectivity-test-results.md). Historical results are **not** validation of the updated deployment.

## Author

[Atul Kamble](https://github.com/atulkamble)
