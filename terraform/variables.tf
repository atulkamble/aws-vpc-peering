variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}
variable "availability_zone" {
  description = "Availability Zone"
  type        = string
  default     = "us-east-1a"
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "key_name" {
  description = "Unique AWS EC2 key pair name (must not already exist in account)"
  type        = string
  default     = "vpc-peering-lab-key"
}
variable "admin_cidr" {
  description = "Your public IP with /32 for SSH access to VM1. Never use 0.0.0.0/0."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && endswith(var.admin_cidr, "/32")
    error_message = "admin_cidr must be a single IPv4 /32 address, e.g. 203.0.113.10/32."
  }
}
variable "vpc1_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "vpc2_cidr" {
  type    = string
  default = "10.1.0.0/16"
}
variable "subnet1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
variable "subnet2_cidr" {
  type    = string
  default = "10.1.1.0/24"
}
