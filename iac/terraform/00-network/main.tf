module "vpc" {
  source = "./modules/vpc"

  region            = var.region
  environment       = var.environment
  vpc_cidr_main     = var.vpc_cidr_main
  vpc_cidr_eks_pods = var.vpc_cidr_eks_pods

  public_subnet_cidrs  = var.public_subnet_cidrs
  app_subnet_cidrs     = var.app_subnet_cidrs
  data_subnet_cidrs    = var.data_subnet_cidrs
  eks_pod_subnet_cidrs = var.eks_pod_subnet_cidrs

  vpc_tags = var.vpc_tags
}
