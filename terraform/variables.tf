variable "region" {
  description = "AWS region to create the servers in"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}
