variable "region" {
  type        = string
  description = "AWS region to build"
  default     = "us-west-2"
}

variable "profile" {
  type        = string
  description = "AWS credential profile"
  defautl     = "default"
}

variable "vpc_cidr" {
  type        = string
  description = "Base CIDR block"
  default     = "10.10.0.0/16"
}
