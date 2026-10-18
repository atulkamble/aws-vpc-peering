# AWS Cross-Account VPC Peering: Flask + MariaDB (Amazon Linux 2023)

Hands-on lab connecting a public Flask EC2 webserver in **AWS Account A** to a private MariaDB EC2 database server in **AWS Account B** over **VPC Peering**. Both instances use Amazon Linux 2023.

## Architecture

```text
Laptop --HTTP:5000--> Account A / VPC A (10.0.0.0/16)
                         Public subnet / webserver (Flask)
                                      |
                              Private TCP:3306
                                      |
                            VPC Peering (pcx-...)
                                      |
                       Account B / VPC B (10.1.0.0/16)
                         Private subnet / dbserver (MariaDB)
```

## 1. Prerequisites and network plan

- Two AWS accounts with permissions to create VPC, EC2, security group, route table, and VPC peering resources.
- Use **the same AWS Region** for both accounts in this lab (examples use `us-east-1`).
- AWS CLI configured with profiles `account-a` and `account-b`; replace all `<...>` placeholders.
- EC2 key pair(s), a local SSH client, and your laptop's public IPv4 `/32`.
- VPC CIDRs must **not overlap**. Use separate subnets belonging to the specified VPCs.

| Item | Account A (Requester) | Account B (Accepter) |
|---|---|---|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| EC2 | `webserver`, public IPv4 | `dbserver`, private IPv4 only |
| OS | Amazon Linux 2023 | Amazon Linux 2023 |
| Application | Flask, TCP 5000 | MariaDB, TCP 3306 |
| Route table | `RouteTableA` | `RouteTableB` |
| Example subnet ID (verify VPC ownership) | `subnet-00d96f94151b62f43` | `subnet-0c62fa06068a9b07b` |

> **Private DB package installation:** a DB instance in a private subnet needs a working package-access path (for example, a NAT Gateway in Account B with a public subnet/Internet Gateway and `0.0.0.0/0` route from the private subnet to the NAT Gateway). VPC peering is **not** a substitute for internet access, and a peer's NAT Gateway cannot be used transitively. Alternatively use a prepared AMI or offline packages. NAT Gateway incurs charges.

## 2. Create networking and instances (AWS Console)

1. **Account A:** Create VPC `VPCA` (`10.0.0.0/16`) and a public subnet. Attach an Internet Gateway; associate a route table containing `0.0.0.0/0 → igw-...` with that subnet. Launch `webserver` with Amazon Linux 2023, a public IPv4 address, and a key pair.
2. **Account B:** Create VPC `VPCB` (`10.1.0.0/16`) and a private subnet. Launch `dbserver` with Amazon Linux 2023 **without** a public IP. Configure temporary outbound package access if installing MariaDB with `dnf`.
3. Confirm VPC DNS resolution is enabled and both instances have the intended private addresses.

### Security groups (inbound)

| Instance | Protocol / port | Source |
|---|---|---|
| webserver | TCP 22 (SSH) | Your laptop public IP `/32` |
| webserver | TCP 5000 (lab HTTP) | Your laptop public IP `/32` |
| dbserver | TCP 3306 (MariaDB) | **Webserver private IP `/32`** |
| dbserver | TCP 22 (optional administration) | Webserver private IP `/32` |
| dbserver | ICMP IPv4 (optional ping) | Webserver private IP `/32` |

For the lab, allow necessary outbound connections on both security groups. Security groups are stateful; if custom network ACLs are used, allow traffic and return-path ephemeral ports in **both** directions. Do not expose TCP 3306 to the internet.

## 3. Create and accept cross-account VPC peering

**Account A (requester):** VPC Console → Peering Connections → Create Peering Connection → select VPC A, *Another account*, Account B ID, VPC B ID, and its Region.

**Account B (accepter):** VPC Console → Peering Connections → select pending request → Actions → Accept Request. Wait until status is **Active**.

Or use AWS CLI:

```bash
# Account A: create (substitute real IDs)
aws ec2 create-vpc-peering-connection \
  --profile account-a --region us-east-1 \
  --vpc-id <VPC_A_ID> --peer-vpc-id <VPC_B_ID> \
  --peer-owner-id <ACCOUNT_B_ID> \
  --query 'VpcPeeringConnection.VpcPeeringConnectionId' --output text

# Account B: accept (after receiving PCX_ID)
aws ec2 accept-vpc-peering-connection \
  --profile account-b --region us-east-1 \
  --vpc-peering-connection-id <PCX_ID>
```

## 4. Configure reciprocal routes and subnet associations

| Route table | Destination | Target |
|---|---|---|
| RouteTableA (webserver subnet) | `10.0.0.0/16` | local (automatic) |
| RouteTableA | `10.1.0.0/16` | `pcx-...` |
| RouteTableA | `0.0.0.0/0` | Account A Internet Gateway |
| RouteTableB (dbserver subnet) | `10.1.0.0/16` | local (automatic) |
| RouteTableB | `10.0.0.0/16` | `pcx-...` |

```bash
aws ec2 create-route --profile account-a --region us-east-1 \
  --route-table-id <RT_A_ID> --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id <PCX_ID>

aws ec2 create-route --profile account-b --region us-east-1 \
  --route-table-id <RT_B_ID> --destination-cidr-block 10.0.0.0/16 \
  --vpc-peering-connection-id <PCX_ID>

# Associate only if not already associated with the intended table
aws ec2 associate-route-table --profile account-a --region us-east-1 \
  --route-table-id <RT_A_ID> --subnet-id subnet-00d96f94151b62f43
aws ec2 associate-route-table --profile account-b --region us-east-1 \
  --route-table-id <RT_B_ID> --subnet-id subnet-0c62fa06068a9b07b
```

> If a subnet already has an **explicit** route-table association, use `replace-route-table-association` with its existing association ID instead. Verify the subnet IDs actually belong to VPC A and VPC B; these IDs are examples from the lab, not verified live resources.

## 5. Install and configure MariaDB on dbserver (Account B)

Connect using AWS Systems Manager Session Manager (if configured) or a bastion/jump host. Ensure the private instance can reach its package repositories.

```bash
sudo dnf update -y
sudo dnf install -y mariadb105-server
sudo systemctl enable --now mariadb
sudo systemctl status mariadb
```

Create the database and an application user restricted to the **webserver's private IP**. Replace `10.0.1.10` with the actual private IP and use a strong unique password.

```bash
sudo mariadb
```

```sql
CREATE DATABASE appdb;
CREATE USER 'appuser'@'10.0.1.10' IDENTIFIED BY 'REPLACE_WITH_STRONG_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'appuser'@'10.0.1.10';
USE appdb;
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL
);
INSERT INTO users (name, email) VALUES ('Demo User', 'demo@example.com');
EXIT;
```

Configure MariaDB to listen on the DBserver private interface (preferred) or `0.0.0.0` for a tightly restricted lab. Edit `/etc/my.cnf.d/mariadb-server.cnf` under `[mysqld]`:

```ini
[mysqld]
bind-address=0.0.0.0
```

```bash
sudo systemctl restart mariadb
sudo ss -lntp | grep 3306
```

## 6. Deploy Flask web application on webserver (Account A)

```bash
sudo dnf update -y
sudo dnf install -y python3 python3-pip
mkdir -p ~/webapp && cd ~/webapp
python3 -m venv .venv
source .venv/bin/activate
pip install flask pymysql
```

Create `app.py`:

```python
import os
from flask import Flask, jsonify
import pymysql

app = Flask(__name__)

@app.get("/")
def home():
    return "AWS cross-account VPC peering lab is running"

@app.get("/users")
def users():
    conn = pymysql.connect(
        host=os.environ["DB_HOST"],
        port=3306,
        user="appuser",
        password=os.environ["DB_PASSWORD"],
        database="appdb",
        connect_timeout=5,
        cursorclass=pymysql.cursors.DictCursor,
    )
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, name, email FROM users")
            return jsonify(cursor.fetchall())
    finally:
        conn.close()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

Run (do **not** commit or share the password):

```bash
export DB_HOST='<DB_PRIVATE_IP>'
read -rs -p 'Database password: ' DB_PASSWORD; echo
export DB_PASSWORD
python app.py
```

The Flask development server and plaintext HTTP are **for this controlled lab only**. Production requires a WSGI server, HTTPS, TLS for database traffic, and managed secrets.

## 7. Test end to end

From the webserver (install `nmap-ncat` if `nc` is missing):

```bash
sudo dnf install -y nmap-ncat mariadb105
nc -vz <DB_PRIVATE_IP> 3306
mariadb -h <DB_PRIVATE_IP> -u appuser -p appdb
```

From your laptop, while Flask is running:

```bash
curl http://<WEB_PUBLIC_IP>:5000/
curl http://<WEB_PUBLIC_IP>:5000/users
```

Expected JSON:

```json
[{"id":1,"name":"Demo User","email":"demo@example.com"}]
```

Optional private SSH jump from laptop (if the same SSH key is authorized on both instances):

```bash
chmod 400 mykey.pem
ssh -i mykey.pem -J ec2-user@<WEB_PUBLIC_IP> ec2-user@<DB_PRIVATE_IP>
```

## 8. Verify and troubleshoot

```bash
# Account A: inspect peering state
aws ec2 describe-vpc-peering-connections --profile account-a --region us-east-1 \
  --vpc-peering-connection-ids <PCX_ID> \
  --query 'VpcPeeringConnections[0].Status.Code' --output text

# Verify subnet VPC ownership (run with each owning account profile)
aws ec2 describe-subnets --profile account-a --region us-east-1 \
  --subnet-ids subnet-00d96f94151b62f43 \
  --query 'Subnets[*].[SubnetId,VpcId,CidrBlock]' --output table
aws ec2 describe-subnets --profile account-b --region us-east-1 \
  --subnet-ids subnet-0c62fa06068a9b07b \
  --query 'Subnets[*].[SubnetId,VpcId,CidrBlock]' --output table
```

| Symptom | Check |
|---|---|
| Peering remains `pending-acceptance` | Accept request in Account B |
| `nc` to 3306 times out | Reciprocal routes, subnet associations, SGs, NACLs, host firewall |
| `Connection refused` | MariaDB running and listening on the private interface |
| `Access denied for user` | DB username, password, and MariaDB host grant match webserver private IP |
| `dnf` fails on private dbserver | NAT/package repository connectivity in Account B |
| Flask `/users` fails | `DB_HOST`, `DB_PASSWORD`, SQL table, and database connectivity |

## 9. Security, costs, and cleanup

- Keep DB private; restrict TCP 3306 to the webserver's private IP (or supported SG reference).
- Do not put passwords, AWS credentials, or private SSH keys in Git.
- Cross-account peering supports private communication, but **does not automatically encrypt** application payloads. Enable MariaDB TLS for sensitive data.
- Review AWS charges for EC2, NAT Gateway, public IPv4, and data transfer/peering.
- Cleanup: stop the app; terminate EC2 instances; remove peering routes; delete peering connection; delete temporary NAT Gateway, Elastic IP, Internet Gateway, subnets, route tables, security groups, and VPCs when no longer needed. Delete resources in dependency order.

**Success criteria:** `pcx-...` is Active; the webserver can connect to DB private IP on TCP 3306; `/users` returns the row stored in Account B's MariaDB instance.
