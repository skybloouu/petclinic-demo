variable "region" {
  description = "AWS Region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr_main" {
  description = "CIDR block for main VPC"
  type        = string
}

variable "vpc_cidr_eks_pods" {
  description = "CIDR block for EKS pods"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for application subnets"
  type        = list(string)
}

variable "data_subnet_cidrs" {
  description = "CIDR blocks for data subnets"
  type        = list(string)
}

variable "eks_pod_subnet_cidrs" {
  description = "CIDR blocks for EKS pod subnets"
  type        = list(string)
}

variable "vpc_tags" {
  description = "Tags for VPC"
  type        = map(string)
  default     = {}
}
