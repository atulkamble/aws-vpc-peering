# AWS VPC (Virtual Private Cloud)
---

# 1. What is VPC?

**VPC (Virtual Private Cloud)** is a logically isolated virtual network inside AWS where you can launch and manage AWS resources securely.

Think of a VPC as:

```text
AWS Cloud
    |
    +---- Your Private Network (VPC)
                |
                +---- EC2
                +---- RDS
                +---- ELB
                +---- Lambda
```

---

# 2. Important Definitions

| Term   | Full Form                      | Purpose                              |
| ------ | ------------------------------ | ------------------------------------ |
| VPC    | Virtual Private Cloud          | Private network in AWS               |
| Subnet | Sub Network                    | Smaller network inside VPC           |
| IGW    | Internet Gateway               | Internet access for VPC              |
| NAT    | Network Address Translation    | Outbound internet for private subnet |
| RT     | Route Table                    | Routing rules                        |
| SG     | Security Group                 | Instance-level firewall              |
| NACL   | Network ACL                    | Subnet-level firewall                |
| VPN    | Virtual Private Network        | Secure connection to on-premises     |
| CIDR   | Classless Inter-Domain Routing | IP range notation                    |

---

# 3. VPC Architecture

```text
                  Internet
                      |
                Internet Gateway
                      |
       --------------------------------
       |                              |
 Public Subnet                 Private Subnet
 10.0.1.0/24                   10.0.2.0/24
       |                              |
     EC2                         Database
       |                              |
       ---------- NAT Gateway --------
```

---

# 4. Types of IP Support

## IPv4 Only

Most common deployment.

```text
10.0.0.0/16
```

Example:

```text
10.0.1.0/24
10.0.2.0/24
```

---

## IPv6 Only

```text
2600:1f10:41e8:2a00::/56
```

Used for modern internet workloads.

---

## Dual Stack

Supports both IPv4 and IPv6.

```text
IPv4 : 10.0.0.0/16
IPv6 : 2600:1f10:41e8:2a00::/56
```

---

# 5. CIDR Concepts

## What is CIDR?

CIDR defines network size.

Example:

```text
10.0.0.0/16
```

Meaning:

```text
Network bits = 16
Host bits    = 16
```

---

## Common CIDR Sizes

| CIDR | Total IPs |
| ---- | --------- |
| /16  | 65,536    |
| /20  | 4,096     |
| /24  | 256       |
| /26  | 64        |
| /27  | 32        |
| /28  | 16        |

---

# 6. AWS Reserved IPs

AWS reserves 5 IPs in every subnet.

Example:

```text
10.0.1.0/24
```

Reserved:

```text
10.0.1.0
10.0.1.1
10.0.1.2
10.0.1.3
10.0.1.255
```

Usable:

```text
251 IPs
```

---

# 7. Default VPC

AWS automatically creates a default VPC.

Example:

```text
vpc-09683ff71eaaac232
```

Characteristics:

✅ Internet Gateway attached

✅ Public subnets available

✅ Route table configured

✅ Auto assign public IP

---

# 8. Default Subnets

Example:

```text
subnet-0f135e475d49526d6
172.31.80.0/20

subnet-08e90dc974d3fc8b1
172.31.64.0/20
```

Default VPC CIDR:

```text
172.31.0.0/16
```

---

# 9. Route Tables

## What is Route Table?

A Route Table contains routing rules.

Example:

```text
Destination        Target

172.31.0.0/16      local
0.0.0.0/0          igw
```

Meaning:

```text
Local traffic -> Local
Internet traffic -> IGW
```

---

# 10. Security Groups vs NACL

| Feature     | Security Group | NACL   |
| ----------- | -------------- | ------ |
| Level       | Instance       | Subnet |
| Stateful    | Yes            | No     |
| Allow Rules | Yes            | Yes    |
| Deny Rules  | No             | Yes    |

---

# 11. Internet Gateway (IGW)

Provides internet connectivity.

```text
EC2
 |
VPC
 |
IGW
 |
Internet
```

---

# 12. NAT Gateway

Used when private servers need internet access.

Example:

```text
Private EC2
     |
     NAT
     |
Internet
```

Use Cases:

* Yum Update
* Apt Update
* Download packages

Without exposing servers publicly.

---

# 13. Public vs Private Subnet

| Public              | Private       |
| ------------------- | ------------- |
| Has Route to IGW    | No IGW Route  |
| Public IP           | No Public IP  |
| Internet Accessible | Internal Only |

---

# 14. AWS CloudShell

Browser-based terminal.

Benefits:

✅ AWS CLI preinstalled

✅ No installation needed

✅ Uses logged-in AWS credentials

Launch:

```text
AWS Console
→ CloudShell
```

---

# 15. AWS CLI Basics

Check version:

```bash
aws --version
```

Check identity:

```bash
aws sts get-caller-identity
```

List VPCs:

```bash
aws ec2 describe-vpcs
```

List subnets:

```bash
aws ec2 describe-subnets
```

---

# 16. Create VPC

```bash
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications ResourceType=vpc,Tags=[{Key=Name,Value=MyVpc}]
```

---

# 17. Create Dedicated VPC

```bash
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --instance-tenancy dedicated
```

Dedicated means:

```text
Dedicated Hardware
Higher Cost
Compliance Requirements
```

---

# 18. Create IPv6 VPC

```bash
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --amazon-provided-ipv6-cidr-block
```

---

# 19. Create IPv4 Subnet

```bash
aws ec2 create-subnet \
--vpc-id vpc-id \
--cidr-block 10.0.1.0/24 \
--availability-zone us-east-1a
```

---

# 20. Create Dual Stack Subnet

```bash
aws ec2 create-subnet \
--vpc-id vpc-id \
--cidr-block 10.0.1.0/24 \
--ipv6-cidr-block ipv6-range \
--availability-zone us-east-1a
```

---

# 21. Create IPv6 Only Subnet

```bash
aws ec2 create-subnet \
--vpc-id vpc-id \
--ipv6-native \
--ipv6-cidr-block ipv6-range
```

---

# 22. Complete VPC Creation Flow

```text
Create VPC
     |
Create Subnets
     |
Create Internet Gateway
     |
Attach IGW
     |
Create Route Table
     |
Create Route
     |
Associate Route Table
     |
Launch EC2
```

---

# 23. VPC Connectivity Diagram

```text
                Internet
                     |
               Internet Gateway
                     |
             Public Route Table
                     |
      ---------------------------------
      |                               |
 Public Subnet                 Private Subnet
 10.0.1.0/24                   10.0.2.0/24
      |                               |
   Web EC2                        App EC2
                                      |
                                NAT Gateway
                                      |
                                  Internet
```

---

# 24. Private IP Communication Practice

## Scenario

Two EC2 instances in same VPC.

```text
Server1
172.31.80.x

Server2
172.31.72.28
```

Copy PEM file to Server1.

---

## Create Key File

```bash
touch key.pem
nano key.pem
```

Paste private key.

---

## Set Permissions

```bash
chmod 400 key.pem
```

---

## SSH to Second Server

```bash
ssh -i key.pem ec2-user@172.31.72.28
```

Example:

```bash
ssh -i key.pem ec2-user@172.31.72.28
```

---

# 25. Important Interview Questions

### What is VPC?

A logically isolated virtual network in AWS.

---

### Difference between Public and Private Subnet?

Public subnet has route to IGW.

Private subnet uses NAT Gateway.

---

### Why use NAT Gateway?

Allows private resources to access internet without exposing them publicly.

---

### Difference between SG and NACL?

Security Group is Stateful.

NACL is Stateless.

---

### How many IPs are available in /24 subnet?

256 total IPs.

251 usable in AWS.

---

### Can EC2 communicate using private IP?

Yes, if Security Groups and Route Tables allow traffic.

---

# 26. Commands to Remember

```bash
aws ec2 describe-vpcs
aws ec2 describe-subnets
aws ec2 describe-route-tables
aws ec2 describe-internet-gateways

aws ec2 create-vpc
aws ec2 create-subnet
aws ec2 create-route-table
aws ec2 create-route

aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway

aws ec2 create-nat-gateway
```

---

# Learning Sequence

```text
1. Networking Basics
2. CIDR & IP Addressing
3. VPC
4. Subnets
5. Route Tables
6. Internet Gateway
7. Security Groups
8. NACL
9. NAT Gateway
10. VPC Peering
11. Transit Gateway
12. VPN
13. Direct Connect
14. AWS CLI Practice
15. Terraform VPC Deployment
```
