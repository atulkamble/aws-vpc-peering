variable "region" {
  default = "us-east-1"
}

variable "az" {
  default = "us-east-1a"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI"
  default     = "ami-0c02fb55956c7d316"
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  default     = "my-key" # <-- Replace with your actual key name
}
