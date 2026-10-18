# Peering Connection 

# AWS VPC Peering – Verified Practical Steps

### Step 1: Create Two VPCs

```
VPC A: 10.0.0.0/16
VPC B: 10.1.0.0/16
```

### Step 2: Create Subnets

```
VPC A: Public Subnet
VPC B: Private Subnet
```

### Step 3: Launch EC2 Instances

```
VPC A: webserver (Public IP)
VPC B: dbserver (Private IP)

AMI: Amazon Linux 2023
Key Pair: mykey.pem
```

### Step 4: Configure Security Groups

```
Webserver SG:
SSH (22)     → Your Public IP/32
All ICMP     → 10.1.0.0/16

DBserver SG:
SSH (22)     → 10.0.0.0/16
All ICMP     → 10.0.0.0/16
```

Keep outbound traffic allowed for the lab.

### Step 5: Create Internet Gateway

```
Create IGW → Attach to VPC A
```

### Step 6: Create VPC Peering Connection

```
VPC → Peering Connections → Create

Requester: VPC A
Accepter: VPC B

Accept Peering Request
Verify Status: Active
```

### Step 7: Configure Route Tables

```
RouteTableA (VPC A):
10.0.0.0/16 → local
10.1.0.0/16 → Peering Connection
0.0.0.0/0   → Internet Gateway

RouteTableB (VPC B):
10.1.0.0/16 → local
10.0.0.0/16 → Peering Connection
```

### Step 8: Associate Subnets

```
RouteTableA:
subnet-00d96f94151b62f43

RouteTableB:
subnet-0c62fa06068a9b07b
```

Verify each subnet belongs to its respective VPC.

### Step 9: Connect to Webserver

```
chmod 400 mykey.pem
ssh -i mykey.pem ec2-user@<WEB_PUBLIC_IP>
```

### Step 10: Test VPC Peering

From the webserver:

```
ping -c 4 <DB_PRIVATE_IP>
nc -vz <DB_PRIVATE_IP> 22
```

### Step 11: Connect to DB Server

From your laptop, using the webserver as a jump host:

```
ssh -i mykey.pem -J ec2-user@<WEB_PUBLIC_IP> ec2-user@<DB_PRIVATE_IP>
```

This assumes the same public key is authorized on both instances and SSH forwarding is permitted.

### Step 12: Verify Connectivity

On the DB server:

```
hostname
hostname -I
```

## Points to Remember

1. VPC CIDR blocks must not overlap.
2. VPC Peering must be `Active`.
3. Route tables must contain routes to the opposite VPC.
4. Security Groups and Network ACLs must allow traffic.
5. VPC Peering uses private IP addresses.
6. DB server does not need a public IP.
7. VPC Peering does not require NAT Gateway.
8. VPC Peering is non-transitive.
9. No Internet Gateway is required for peered VPC traffic; VPC A's IGW is only for public SSH access.
10. Allow SSH from your own public IP rather than `0.0.0.0/0`.

Traffic Flow:

```
Laptop
   |
   | SSH (Public IP)
   v
Internet Gateway (VPC A)
   |
   v
Webserver (10.0.x.x)
   |
   | Private IP Traffic
   v
VPC Peering Connection
   |
   v
DBserver (10.1.x.x)
```

Crosscheck result: The proposed configuration is technically valid for a basic AWS VPC Peering lab. Actual subnet IDs, routes, security groups, NACLs, and instance connectivity still need verification in your AWS account.
