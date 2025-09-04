region      = "ap-south-1"
environment = "production"

vpc_cidr_main     = "10.0.0.0/22"
vpc_cidr_eks_pods = "100.64.0.0/16"

public_subnet_cidrs  = ["10.0.0.0/26", "10.0.0.64/26"]
app_subnet_cidrs     = ["10.0.1.0/25", "10.0.1.128/25"]
data_subnet_cidrs    = ["10.0.2.0/26", "10.0.2.64/26"]
eks_pod_subnet_cidrs = ["100.64.0.0/18", "100.64.64.0/18"]

vpc_tags = {
  "kubernetes.io/cluster/eks-cluster" = "shared"
}
