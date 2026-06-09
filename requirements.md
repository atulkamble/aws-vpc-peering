# AWS VPC Peering – Mandatory Conditions

Before creating a VPC Peering connection, the following conditions must be satisfied:

## 1. Non-Overlapping CIDR Blocks (Mandatory)

The CIDR ranges of both VPCs must not overlap.

✅ Valid Example

```text
VPC-A : 10.0.0.0/16
VPC-B : 10.1.0.0/16
```

❌ Invalid Example

```text
VPC-A : 10.0.0.0/16
VPC-B : 10.0.0.0/24
```

AWS will not allow peering between overlapping CIDRs.

---

## 2. VPCs Must Exist

Both VPCs must already be created.

```text
VPC-A
VPC-B
```

---

## 3. Peering Request Must Be Accepted

One VPC owner sends a peering request.

```text
Requester VPC → Accepter VPC
```

The accepter must approve the request before it becomes active.

---

## 4. Route Tables Must Be Updated

Peering alone does not provide connectivity.

Routes must be added on both sides.

### VPC-A Route Table

```text
Destination     Target
10.1.0.0/16     pcx-xxxx
```

### VPC-B Route Table

```text
Destination     Target
10.0.0.0/16     pcx-xxxx
```

Without routes, communication will fail.

---

## 5. Security Groups Must Allow Traffic

Allow required ports from the peer VPC CIDR.

Example:

```text
SSH   TCP 22   Source: 10.1.0.0/16
HTTP  TCP 80   Source: 10.1.0.0/16
```

---

## 6. Network ACLs Must Allow Traffic

NACLs should permit inbound and outbound traffic.

Example:

```text
Inbound  : Allow 10.1.0.0/16
Outbound : Allow 10.1.0.0/16
```

---

## 7. DNS Resolution (Optional but Recommended)

Enable DNS resolution if accessing instances using private DNS names.

Peering Options:

```text
Enable DNS Resolution
Enable DNS Hostnames
```

---

## 8. Cross-Region Peering (Supported)

VPCs can be in:

* Same Region
* Different Regions

Example:

```text
Mumbai (ap-south-1)
↕
Virginia (us-east-1)
```

---

## 9. Cross-Account Peering (Supported)

VPCs can belong to:

* Same AWS Account
* Different AWS Accounts

The accepter account must approve the request.

---

## 10. No Transitive Routing

VPC Peering is **not transitive**.

```text
VPC-A ↔ VPC-B
VPC-B ↔ VPC-C
```

❌ Not Allowed

```text
VPC-A → VPC-C
```

To connect multiple VPCs, use:

* AWS Transit Gateway
* VPN
* Direct Connect

---

# VPC Peering Connectivity Checklist

| Requirement              | Mandatory        |
| ------------------------ | ---------------- |
| Non-overlapping CIDRs    | ✅                |
| Existing VPCs            | ✅                |
| Peering Request Accepted | ✅                |
| Route Table Updates      | ✅                |
| Security Group Rules     | ✅                |
| NACL Rules               | Recommended      |
| DNS Resolution           | Optional         |
| Same Region              | ❌ (Not Required) |
| Same Account             | ❌ (Not Required) |
| Transitive Routing       | ❌ Not Supported  |

## Exam/Interview One-Liner

**For VPC Peering to work, you need:**

1. Non-overlapping CIDR ranges
2. Active peering connection
3. Route table entries on both sides
4. Security groups and NACLs allowing traffic

Without any of these, connectivity between VPCs will fail.
