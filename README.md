**AWS VPC Peering Connection project** with CLI commands, use case, and verification steps. This project helps connect two VPCs so resources in one VPC can communicate with resources in the other using private IPs.

---

## ✅ **Project Title:**

**Create and Configure VPC Peering between Two VPCs Using AWS CLI**

---

```
aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem
chmod 400 my-key.pem
```

// copy files 
```
scp -i my-key.pem -r /Users/atul/Downloads/AWS-VPC-Peering-Project ec2-user@204.236.200.28:/home/ec2-user/
```

## 🎯 **Objective:**

To create a secure VPC peering connection between two different VPCs in the same AWS region and route traffic privately between their EC2 instances.

---

## 🧩 **Use Case:**

* **VPC-A**: Application server
* **VPC-B**: Database server
* Goal: Allow the app server in VPC-A to access the database in VPC-B over private IPs.

---

## 🏗️ **Step-by-Step Setup Using AWS CLI**

### 1️⃣ Create Two VPCs

```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications \
"ResourceType=vpc,Tags=[{Key=Name,Value=VPC-A}]"

aws ec2 create-vpc --cidr-block 10.1.0.0/16 --tag-specifications \
"ResourceType=vpc,Tags=[{Key=Name,Value=VPC-B}]"
```

### 2️⃣ Note the VPC IDs

```bash
aws ec2 describe-vpcs --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock}"
```

### 3️⃣ Create Subnets in Both VPCs

```bash
aws ec2 create-subnet --vpc-id <vpc-a-id> --cidr-block 10.0.1.0/24
aws ec2 create-subnet --vpc-id <vpc-b-id> --cidr-block 10.1.1.0/24
```

### 4️⃣ Create VPC Peering Connection

```bash
aws ec2 create-vpc-peering-connection --vpc-id <vpc-a-id> \
--peer-vpc-id <vpc-b-id> --tag-specifications \
"ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=VPC-A-B-Peering}]"
```

### 5️⃣ Accept the Peering Connection

```bash
aws ec2 describe-vpc-peering-connections

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id <peering-connection-id>
```

### 6️⃣ Update Route Tables (One for Each VPC)

```bash
# Get route table IDs
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-a-id>
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-b-id>

# Add routes
aws ec2 create-route --route-table-id <route-table-a-id> \
--destination-cidr-block 10.1.0.0/16 --vpc-peering-connection-id <peering-connection-id>

aws ec2 create-route --route-table-id <route-table-b-id> \
--destination-cidr-block 10.0.0.0/16 --vpc-peering-connection-id <peering-connection-id>
```

---

## 🚀 **Test Connectivity**

### Deploy EC2 Instances in Both VPCs:

```bash
aws ec2 run-instances --image-id ami-0c02fb55956c7d316 \
--count 1 --instance-type t2.micro --key-name mykey \
--security-group-ids <sg-id> --subnet-id <subnet-id>
```

### Add SG Rules to Allow ICMP or SSH:

```bash
aws ec2 authorize-security-group-ingress \
--group-id <sg-id> --protocol icmp --port -1 --cidr 10.0.0.0/8
```

### From one EC2, ping the other EC2’s private IP:

```bash
ping <private-ip-of-peer-ec2>
```

---

## 🧼 **Clean Up**

```bash
aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id <id>
aws ec2 delete-vpc --vpc-id <vpc-a-id>
aws ec2 delete-vpc --vpc-id <vpc-b-id>
```

---

## 📌 Diagram (Textual)

```
+----------------+      Peering      +----------------+
|     VPC-A      | <---------------> |     VPC-B      |
| 10.0.0.0/16    |                   | 10.1.0.0/16    |
|   EC2-A        |                   |   EC2-B        |
+----------------+                   +----------------+
```
# steps to perform
```

VPC Peering Connection 

1) Create VPC A | 10.0.0.0/16
2) Create VPC B | 10.1.0.0/32
3) Create Peering Connection 
4) Accept Peering Connection
5) Edit Route Table A 
Add B details and Peering Connection ID
6) Edit Route Table B 
Add A details and Peering Connection ID
5) Launch instance A to VPC A (Public Subnet with internet gateway) | SG - 22
6) Launch instance B to VPC B (Private Subnet) | SG 22
7) Connect instance A - SSH 
ping 
ssh -i mykey userB@private-ip
8) Suceesful Connection

9) Deletion
delete instances
delete peering connection 
delete vpc 

touch mykey.pem
chmod 400 mykey.pem

ssh -i mykey.pem ec2-user@10.1.0.10


```
---
