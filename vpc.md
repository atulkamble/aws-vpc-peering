VPC - Virtual Private Cloud

Default

Subnet - Part of Network

VPN - Virtual Private Network

// Routing Table - Rules - 

Networking Forwarding | Firewalls 

10.0.0.0/16

IPV6 Only
IPV4 Only
IPV4 and IPV6

CloudShell -
AWS CLI - 


# To create a VPC from AWS CLI
```
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specification ResourceType=vpc,Tags=[{Key=Name,Value=MyVpc}]
```

# To create a VPC with dedicated tenancy
```
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --instance-tenancy dedicated
```

# IPv4-only subnet – To create a subnet with a specific IPv4 CIDR block, use the following create-subnet command.
```
aws ec2 create-subnet --vpc-id vpc-08930ba0626a5e504 --cidr-block 10.0.1.0/20 --availability-zone us-east-1a --query Subnet.SubnetId --output text
```
# Dual stack subnet – If you created a dual stack VPC, you can use the --ipv6-cidr-block option to create a dual stack subnet, as shown in the following command.
```
aws ec2 create-subnet --vpc-id vpc-08930ba0626a5e504 --cidr-block 10.0.1.0/20 --ipv6-cidr-block 2600:1f10:41e8:2a00::/56 --availability-zone us-east-1a --query Subnet.SubnetId --output text
```
# IPv6-only subnet – If you created a dual stack VPC, you can use the --ipv6-native option to create an IPv6-only subnet, as shown in the following command.
```
aws ec2 create-subnet --vpc-id vpc-03e949e4cfcf7bdd5 --ipv6-native --ipv6-cidr-block 2600:1f10:41e8:2a00::/56 --availability-zone us-east-1a --query Subnet.SubnetId --output text
```

# To create a VPC with an IPv6 CIDR block
```
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --amazon-provided-ipv6-cidr-block
```

# To create a VPC with a CIDR from an IPAM pool
```
aws ec2 create-vpc \
    --ipv4-ipam-pool-id ipam-pool-0533048da7d823723 \
    --tag-specifications ResourceType=vpc,Tags='[{Key=Environment,Value="Preprod"},{Key=Owner,Value="Build Team"}]'
```
# To create a VPC plus VPC resources by using the AWS CLI
```
aws ec2 create-vpc --cidr-block 10.0.0.0/24 --query Vpc.VpcId --output text
```
# Alternatively, to create a dual stack VPC, add the --amazon-provided-ipv6-cidr-block option to add an Amazon-provided IPv6 CIDR block, as shown in the following example.
```
aws ec2 create-vpc --cidr-block 10.0.0.0/24 --amazon-provided-ipv6-cidr-block --query Vpc.VpcId --output text
```
# [Dual stack VPC] Get the IPv6 CIDR block that's associated with your VPC by using the following describe-vpcs command.
```
aws ec2 describe-vpcs --vpc-id vpc-1a2b3c4d5e6f1a2b3 --query Vpcs[].Ipv6CidrBlockAssociationSet[].Ipv6CidrBlock --output text
```

# public subnet for your web servers, or for a NAT gateway, do the following:
```
aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text
```
# Attach the internet gateway to your VPC by using the following attach-internet-gateway command. Use the internet gateway ID returned from the previous step.
```
aws ec2 attach-internet-gateway --vpc-id vpc-1a2b3c4d5e6f1a2b3 --internet-gateway-id igw-id
```
# Create a custom route table for your public subnet by using the following create-route-table command. The command returns the ID of the new route table.
```
aws ec2 create-route-table --vpc-id vpc-1a2b3c4d5e6f1a2b3 --query RouteTable.RouteTableId --output text
```
# Create a route in the route table that sends all IPv4 traffic to the internet gateway by using the following create-route command. Use the ID of the route table for the public subnet.
```
aws ec2 create-route --route-table-id rtb-id-public --destination-cidr-block 0.0.0.0/0 --gateway-id igw-id
```
# Associate the route table with the public subnet by using the following associate-route-table command. Use the ID of the route table for the public subnet and the ID of the public subnet.
```
aws ec2 associate-route-table --route-table-id rtb-id-public --subnet-id subnet-id-public-subnet
```
# Create the NAT gateway by using the following create-nat-gateway command. Use the allocation ID returned from the previous step.
```
aws ec2 create-nat-gateway --subnet-id subnet-id-private-subnet --allocation-id eipalloc-id
```
# (Optional) If you already created a route table for the private subnet in step 5, skip this step. Otherwise, use the following create-route-table command to create a route table for your private subnet. The command returns the ID of the new route table.
```
aws ec2 create-route-table --vpc-id vpc-1a2b3c4d5e6f1a2b3 --query RouteTable.RouteTableId --output text
```
# Create a route in the route table for the private subnet that sends all IPv4 traffic to the NAT gateway by using the following create-route command. Use the ID of the route table for the private subnet, which you created either in this step or in step 5.
```
aws ec2 create-route --route-table-id rtb-id-private --destination-cidr-block 0.0.0.0/0 --gateway-id nat-id
```
# (Optional) If you already associated a route table with the private subnet in step 5, skip this step. Otherwise, use the following associate-route-table command to associate the route table with the private subnet. Use the ID of the route table for the private subnet, which you created either in this step or in step 5.
```
aws ec2 associate-route-table --route-table-id rtb-id-
```

default vpc 
id - vpc-09683ff71eaaac232

subnet-0f135e475d49526d6 172.31.80.0/20
subnet-08e90dc974d3fc8b1 172.31.64.0/20

// copy instance private ip of 2nd instance

connect to 1st instance 

touch key.pem
nano key.pem 
chmod 400 key.pem 

ssh -i key.pem ec2-user@private-ip-of-2nd-instance

example: ssh -i key.pem ec2-user@172.31.72.28














