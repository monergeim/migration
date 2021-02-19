variable "aws_region" {
  description = "AWS Region"
  default     = "eu-west-1"
}

variable "aws_access_key" {
  description = "AWS Access key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret key"
  type        = string
}

variable "cluster_name" {
  default = "exberry-eks"
  type    = string
}

variable "ns" {
  type    = string
}

variable "kube_conf" {
  type        = string
}

variable "snaps" {
  type = map
}
