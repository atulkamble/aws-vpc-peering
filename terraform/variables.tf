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
  description = "Amazon Linux 2 AMI for us-east-1"
  default     = "ami-0c02fb55956c7d316"
}

