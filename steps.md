```
// VPC Peering

1. VPC A - 10.0.0.0/16
2. VPC B - 10.1.0.0/16
3. Launch webserver
SG -
ICMP - All ICMP - 10.1.0.0/16

4. Launch dbserver
SG -
ICMP - All ICMP - 10.0.0.0/16


5. Launch dbserver

6. Create Peering Connection
Requester - VPCA
Accepter - VPCB

7.
Create RouteTableA
Add Entry - Peering Connection - VPCB address

Create RouteTableB
Add Entry - Peering Connection - VPCA Address

8. Subnet Associate respective route-tables

VPCA - subnet-00d96f94151b62f43

VPCB - subnet-0c62fa06068a9b07b

9.

connect with webserver - public ssh username@public-ip-webserver

from webserver conenct to dbserver - ssh username@private-ip-dbserver
```
