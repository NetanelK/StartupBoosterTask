variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "cluster_desired_size" {
  type    = number
  default = 2
}

variable "cluster_max_size" {
  type    = number
  default = 4
}

variable "cluster_min_size" {
  type    = number
  default = 2
}
