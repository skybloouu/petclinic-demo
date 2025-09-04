variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr_main" {
  description = "CIDR block for main VPC"
  type        = string
  default     = "10.0.0.0/22"
}

variable "vpc_cidr_eks_pods" {
  description = "CIDR block for EKS pods"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/26", "10.0.0.64/26"]
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for application subnets"
  type        = list(string)
  default     = ["10.0.1.0/25", "10.0.1.128/25"]
}

variable "data_subnet_cidrs" {
  description = "CIDR blocks for data subnets"
  type        = list(string)
  default     = ["10.0.2.0/26", "10.0.2.64/26"]
}

variable "eks_pod_subnet_cidrs" {
  description = "CIDR blocks for EKS pod subnets"
  type        = list(string)
  default     = ["172.16.0.0/18", "172.16.64.0/18"]
}

variable "vpc_tags" {
  description = "Tags for VPC"
  type        = map(string)
  default = {
    "kubernetes.io/cluster/eks-cluster" = "shared"
  }
}
