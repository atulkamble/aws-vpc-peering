# AWS VPC Peering Project

**Goal:** Connect a public EC2 instance in VPC-A to a private EC2 instance in VPC-B using VPC Peering and Terraform.

## Architecture

```mermaid
flowchart LR
    User["Laptop"] -->|"SSH"| IGW["Internet Gateway"]
    subgraph A["VPC-A: 10.0.0.0/16"]
        VM1["Public EC2 (VM1)<br/>10.0.1.0/24 subnet"]
    end
    subgraph B["VPC-B: 10.1.0.0/16"]
        VM2["Private EC2 (VM2)<br/>10.1.1.0/24 subnet"]
    end
    IGW --> VM1
    VM1 <-->|"Private IP traffic"| PCX["VPC Peering"]
    PCX <--> VM2
```

| Setting | VPC-A | VPC-B |
|---|---|---|
| CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| Subnet | `10.0.1.0/24` (public) | `10.1.1.0/24` (private) |
| EC2 | VM1, public IP | VM2, private IP only |
| Peering route | `10.1.0.0/16 → pcx` | `10.0.0.0/16 → pcx` |
| Internet route | `0.0.0.0/0 → IGW` | None |

## Prerequisites

AWS CLI configured, Terraform 1.5+, SSH, AWS permissions, and your public IPv4 address.

## Deploy

```bash
git clone https://github.com/atulkamble/aws-vpc-peering.git
cd aws-vpc-peering/terraform

aws sts get-caller-identity
terraform init
terraform fmt -check
terraform validate

export ADMIN_CIDR="YOUR_PUBLIC_IP/32"
terraform plan -var="admin_cidr=$ADMIN_CIDR"
terraform apply -var="admin_cidr=$ADMIN_CIDR"
```

Replace `YOUR_PUBLIC_IP` with your public IPv4 address.

## Verify

```bash
terraform output
aws ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids "$(terraform output -raw peering_connection_id)" \
  --query 'VpcPeeringConnections[*].Status.Code'
```

Expected peering status: `active`.

## Test Connectivity

```bash
chmod 400 key.pem
VM1_PUBLIC=$(terraform output -raw vm1_public_ip)
VM2_PRIVATE=$(terraform output -raw vm2_private_ip)

# SSH to public VM1
ssh -i key.pem ec2-user@"$VM1_PUBLIC"

# Ping VM2 through VM1 (run from laptop)
ssh -i key.pem ec2-user@"$VM1_PUBLIC" "ping -c 3 $VM2_PRIVATE"

# SSH to private VM2 through VM1 (run from laptop)
ssh -i key.pem -o IdentitiesOnly=yes \
  -o "ProxyCommand=ssh -i key.pem -o IdentitiesOnly=yes -W %h:%p ec2-user@$VM1_PUBLIC" \
  ec2-user@"$VM2_PRIVATE"
```

Exit the first SSH session before running the remaining commands on your laptop.

## Cleanup

```bash
terraform destroy -var="admin_cidr=$ADMIN_CIDR"
```

## Key Points

- VPC CIDRs must not overlap; peering must be active.
- Both route tables and security rules must allow private traffic.
- VPC peering is **not transitive**.
- VM2 has no direct internet access in this lab.
- **Security:** Do not commit `key.pem` or Terraform state; private keys are stored in state.
- **Costs:** EC2 and public IPv4 charges may apply.

**Source:** [Terraform files](terraform/) · [AWS VPC Peering documentation](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html)
