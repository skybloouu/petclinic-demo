# PetClinic Infrastructure as Code (IaC)

This directory contains the Terraform code for provisioning the complete AWS infrastructure for the Spring PetClinic application. The infrastructure is organized into modular layers that build upon each other to create a secure, scalable, and maintainable environment.



## Module Structure

The Terraform code is organized into these primary modules:

| Module | Purpose | Dependencies |
|--------|---------|--------------|
| `bootstrap` | Terraform state management & CI/CD access | None |
| `00-network` | VPC, subnets, routing & networking | bootstrap |
| `01-control-plane` | EKS cluster & Kubernetes infrastructure | 00-network |
| `05-app-infra` | Application-specific AWS resources | 01-control-plane |

## Deployment Sequence

The modules must be deployed in a specific order due to their dependencies:

1. **bootstrap**: Initialize S3/DynamoDB for Terraform state
2. **00-network**: Establish the network foundation
3. **01-control-plane**: Deploy the EKS control plane
4. **05-app-infra**: Provision application-specific resources

## Module Details

### bootstrap

The foundation for all infrastructure, providing:
- S3 bucket for Terraform state storage
- DynamoDB table for state locking
- GitHub Actions OIDC integration for CI/CD
- IAM roles with least-privilege permissions

[View bootstrap documentation](./bootstrap/README.md)

### 00-network

The networking layer, providing:
- VPC with public and private subnets
- Internet Gateway and NAT Gateways
- Route tables and NACLs
- Multi-AZ topology for high availability
- Secondary CIDR for Kubernetes pods

[View network documentation](./00-network/README.md)

### 01-control-plane

The Kubernetes infrastructure layer, providing:
- EKS cluster with managed node groups
- Worker nodes in private subnets
- IAM roles for Kubernetes service accounts (IRSA)
- Core Kubernetes add-ons (AWS Load Balancer Controller, cert-manager)
- Security configurations and access management

[View control-plane documentation](./01-control-plane/README.md)

### 05-app-infra

The application infrastructure layer, providing:
- Aurora MySQL Serverless v2 database
- ECR repository for application images
- S3 bucket for application data
- IAM roles for application components
- Secrets management for database credentials

[View app-infra documentation](./05-app-infra/README.md)

## Terraform State Management

Each module maintains its own state file in the centralized S3 bucket defined in the bootstrap module. This separation allows for:

- Independent management of each infrastructure layer
- Reduced blast radius for changes
- Clearer permission boundaries
- Parallel workflows by different teams

## Configuration Pattern

Each module follows a consistent pattern:
- `main.tf`: Primary resource definitions
- `variables.tf`: Input variable declarations
- `outputs.tf`: Output values
- `provider.tf`: Provider configuration
- `backend.tf`: Terraform backend configuration
- `*.tf`: Additional resource definitions by category
- `README.md`: Documentation specific to the module

## Remote State Data Sharing

Modules reference outputs from other modules using the `terraform_remote_state` data source:

```terraform
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "stackgen-terraform-state"
    key    = "env/00-network/terraform.tfstate"
    region = "ap-south-1"
  }
}
```

This pattern allows modules to build upon resources created in earlier layers.

## Security Practices

The infrastructure implements numerous security best practices:

1. **Least Privilege Access**: IAM roles and policies follow the principle of least privilege
2. **Network Isolation**: Multi-tier network architecture with public/private subnet separation
3. **Secrets Management**: AWS Secrets Manager for database credentials
4. **Encryption**: Data encryption at rest and in transit
5. **OIDC Authentication**: Federated identity for CI/CD pipelines
6. **IRSA**: IAM Roles for Service Accounts for Kubernetes pod permissions

## Infrastructure Customization

Each module accepts input variables through `terraform.tfvars` files (not committed to the repository for security). Examples of key customization parameters:

- Environment name (dev/staging/production)
- Instance types and sizes
- Scaling parameters
- Domain names and certificates
- Repository and branch names for CI/CD

## Operational Considerations

1. **State Management**: Never manually modify the Terraform state
2. **Module Boundaries**: Respect module boundaries when making changes
3. **Sequence**: Follow the correct sequence for applying changes
4. **Documentation**: Keep module READMEs updated with any architectural changes
5. **Version Control**: All infrastructure changes should go through version control

## Continuous Deployment

The infrastructure supports CI/CD through GitHub Actions:
- OIDC authentication with AWS
- Separate workflows for each module
- Terraform plan/apply automation
- Branch protection for infrastructure changes

## Getting Started

To work with this infrastructure:

1. Ensure you have appropriate AWS credentials
2. Install Terraform v1.9+ locally
3. Review the module READMEs to understand the architecture
4. Create appropriate `terraform.tfvars` files for each module
5. Follow the deployment sequence when applying changes

## Diagram Generation

The architecture diagrams are generated using the Python `diagrams` package. The source code for the diagrams is available in the `/diagrams` directory at the project root.

## Future Enhancements

Planned infrastructure improvements:
- Implement AWS WAF for additional web application security
- Add CloudWatch dashboards for monitoring
- Integrate AWS Config for compliance monitoring
- Add blue/green deployment capabilities
