#Week 22 project variables 
variable "region" {
  type    = string
  default = "us-east-2"
}

variable "vpc-cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "tenancy" {
  type    = string
  default = "default"
}

variable "true" {
  type    = bool
  default = true
}

variable "public-subnets" {
  default = {
    "public-subnet-1" = 1
    "public-subnet-2" = 2
  }
}

variable "private-subnets" {
  default = {
    "private-subnet-1" = 1
    "private-subnet-2" = 2
  }
}

variable "cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "ami" {
  description = "AMI"
  type        = string
  default     = "ami-0533def491c57d991"
}

variable "instance_type" {
  description = "Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 Key Name"
  type        = string
  default     = "EC2-Ohio"
}

variable "SSH" {
  type    = string
  default = "22"
}

variable "tcp" {
  type    = string
  default = "tcp"
}

variable "HTTP" {
  type    = string
  default = "80"
}

variable "HTTPS" {
  type    = string
  default = "443"
}

variable "egress-all" {
  type    = string
  default = "0"
}

variable "egress" {
  type    = string
  default = "-1"
}