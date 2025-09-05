# PetClinic EKS Control Plane Architecture

This document describes the AWS EKS control plane architecture for the PetClinic application.

## Overview

The PetClinic application runs on an Amazon EKS cluster, which provides a managed Kubernetes control plane. The architecture includes the following components:

1. EKS Control Plane
2. Node Groups
3. Kubernetes Add-ons
4. IAM Roles for Service Accounts (IRSA)
5. VPC Networking Configuration
6. Load Balancing and Ingress

## EKS Control Plane

The EKS control plane is managed by AWS and includes:

- Kubernetes API server
- etcd (Kubernetes state store)
- Scheduler
- Controller Manager
- AWS-managed networking components

Configuration details:
- Kubernetes Version: 1.33
- API server endpoint is accessible publicly (configurable)
- Control plane runs in dedicated AWS-managed VPC
- Control plane security groups managed by AWS

## Node Groups

The EKS cluster uses managed node groups with the following configuration:

- Uses Amazon Linux 2023 (AL2023) AMI
- Uses SPOT instances for cost optimization
- Instance types: t3.medium (configurable)
- Autoscaling configuration:
  - Minimum: 1
  - Maximum: 3
  - Desired: 2
- Tagged for cluster autoscaler integration

## Kubernetes Add-ons

### Core Add-ons (AWS Managed)
1. CoreDNS - Cluster DNS service
2. kube-proxy - Network proxy
3. amazon-vpc-cni - VPC CNI plugin
4. EKS Pod Identity Agent - For IRSA functionality

### Additional Add-ons (Helm-installed)
1. AWS Load Balancer Controller
   - Provisions and manages AWS Application Load Balancers
   - Uses IRSA for AWS API permissions
   - Deployed in kube-system namespace

2. cert-manager
   - Manages TLS certificates
   - Supports Route53 DNS01 challenges for certificate issuance
   - Uses IRSA for Route53 API permissions
   - Deployed in cert-manager namespace

3. Metrics Server
   - Collects resource metrics from nodes and pods
   - Required for Horizontal Pod Autoscaling
   - Deployed in kube-system namespace

## IAM Roles for Service Accounts (IRSA)

The architecture uses IRSA to grant specific AWS permissions to Kubernetes service accounts:

1. ALB Controller Role:
   - Allows creating and managing AWS Application Load Balancers
   - Allows managing security groups, target groups, and listeners
   - Allows ACM certificate discovery

2. cert-manager Role:
   - Allows Route53 record management for DNS01 challenges
   - Scoped to specific hosted zone when configured

## Access Management

The cluster has the following access configurations:

1. Cluster Creator Admin Permissions:
   - The IAM entity that creates the cluster gets admin access

2. DevOps Admin Role:
   - IAM role with full cluster admin access
   - Uses EKS Cluster Access Entry

3. Admin User:
   - IAM user with full cluster admin access
   - Uses EKS Cluster Access Entry

## VPC Networking

The EKS cluster is deployed into a VPC with the following subnet structure:

1. Public Subnets:
   - One per availability zone
   - Contains NAT Gateways for private subnet egress
   - Houses public-facing load balancers

2. Private Application Subnets:
   - One per availability zone
   - Contains EKS worker nodes
   - Egress traffic flows through NAT Gateways

3. Private Data Subnets:
   - One per availability zone
   - For database resources (used by RDS/Aurora)
   - Isolated from direct internet access

4. EKS Pod Subnets:
   - Uses secondary CIDR block
   - Dedicated to Kubernetes pod IP addresses
   - Enables higher pod density and better IP management

## Load Balancing and Ingress

1. AWS Application Load Balancer (ALB):
   - Provisioned by the AWS Load Balancer Controller
   - Terminates TLS with ACM certificates
   - Routes traffic to Kubernetes services

2. Kubernetes Ingress Resources:
   - Define routing rules for applications
   - Annotated for ALB Controller integration
   - Support for various traffic routing patterns

## Security

1. Network Security:
   - Private subnets for worker nodes
   - Security groups for pod-to-pod communication
   - NAT Gateways for controlled outbound traffic

2. Pod Security:
   - IAM Roles for Service Accounts (IRSA)
   - Limited permissions based on least privilege
   - Pod Security Standards enforcement

3. Cluster Security:
   - EKS control plane managed by AWS
   - API server accessible via authorized principals only
   - Logging and auditing via CloudWatch

## Monitoring and Logging

1. CloudWatch:
   - Control plane logs
   - Worker node logs
   - Container insights (optional)

2. Metrics Server:
   - Provides metrics for Horizontal Pod Autoscaling
   - Captures CPU and memory usage

## Automation and Infrastructure as Code

The entire architecture is defined and provisioned using Terraform, with:

1. Network infrastructure defined in the 00-network module
2. EKS control plane and node groups defined in the 01-control-plane module
3. Add-ons deployed via Helm charts with values defined in deployment-configs
