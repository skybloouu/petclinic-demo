# PetClinic Demo - Cloud-Native Application with AWS and Kubernetes

This repository contains a complete cloud-native implementation of the Spring PetClinic application, deployed on AWS EKS with a comprehensive infrastructure as code (IaC) setup using Terraform and Kubernetes resources defined with Helm charts.

## Repository Structure

```
petclinic-demo/
├── .github/workflows/             # CI/CD pipeline definitions
├── deployment-configs/            # Kubernetes deployment configurations
│   ├── addons/                    # Cluster add-ons (ALB controller, cert-manager, etc.)
│   └── spring-petclinic/          # Application Helm chart
├── iac/terraform/                 # Infrastructure as Code with Terraform
│   ├── bootstrap/                 # Terraform state management and CI/CD setup
│   ├── 00-network/                # VPC, subnets, and network components
│   ├── 01-control-plane/          # EKS cluster and node groups
│   └── 05-app-infra/              # Application infrastructure (Aurora, ECR, IAM)
└── README.md                      # This documentation file
```

## Architecture Overview

This project implements a cloud-native architecture with the following components:

### Infrastructure Layer
- **Networking**: AWS VPC with public and private subnets across multiple availability zones
- **Compute**: EKS cluster with managed node groups using SPOT instances for cost optimization
- **Database**: Aurora Serverless v2 MySQL for scalable, managed database service
- **Storage**: S3 buckets for configuration and artifacts
- **Registry**: ECR repositories for container images

### Platform Layer
- **Kubernetes Add-ons**: Essential cluster extensions for production readiness
  - AWS Load Balancer Controller for Ingress resources
  - cert-manager for TLS certificate automation
  - Metrics Server for HPA functionality
  - External DNS for Route 53 integration
- **CI/CD**: GitHub Actions workflows for automated deployments

### Application Layer
- **Spring PetClinic**: Java-based web application with MySQL backend
- **Containerization**: Docker-based deployment with optimized images
- **Scalability**: Horizontal Pod Autoscaler for demand-based scaling
- **Networking**: ALB Ingress for external access with TLS termination

## Deployment Flow

The project follows a structured deployment process:

1. **Bootstrap**: Set up Terraform state backend and CI/CD IAM roles
   ```
   cd iac/terraform/bootstrap
   terraform init && terraform apply
   ```

2. **Network Infrastructure**: Create VPC and network components
   ```
   cd iac/terraform/00-network
   terraform init && terraform apply
   ```

3. **EKS Cluster**: Deploy Kubernetes control plane and worker nodes
   ```
   cd iac/terraform/01-control-plane
   terraform init && terraform apply
   ```

4. **Application Infrastructure**: Create Aurora database, ECR, and IAM roles
   ```
   cd iac/terraform/05-app-infra
   terraform init && terraform apply
   ```

5. **Kubernetes Add-ons**: Install cluster extensions
   ```
   cd deployment-configs
   # Follow instructions in deployment-configs/addons/README.md
   ```

6. **Application Deployment**: Deploy Spring PetClinic using Helm
   ```
   cd deployment-configs
   helm upgrade --install petclinic ./spring-petclinic -n petclinic --create-namespace
   ```

## CI/CD Pipelines

The repository includes GitHub Actions workflows for automated deployment:

- **Terraform Workflows**:
  - Network infrastructure deployment
  - EKS control plane deployment
  - Application infrastructure deployment

- **Kubernetes Workflows**:
  - Cluster add-ons deployment
  - Application deployment

These workflows automatically apply changes when code is pushed to the main branch, following GitOps principles.

## Security Features

This project implements several security best practices:

- **Network Isolation**: Private subnets for sensitive components
- **IAM Roles for Service Accounts (IRSA)**: Fine-grained AWS permissions
- **Secrets Management**: AWS Secrets Manager for sensitive data
- **TLS Everywhere**: HTTPS for all external endpoints
- **Least Privilege**: Minimized IAM permissions

## Monitoring and Observability

The architecture includes:

- **Metrics**: Prometheus-compatible metrics endpoints
- **Logging**: Container logs captured via CloudWatch
- **Tracing**: OpenTelemetry integration for distributed tracing
- **Alerting**: CloudWatch Alarms for critical thresholds

## Local Development

For local development:

1. **Prerequisites**:
   - AWS CLI
   - Terraform CLI
   - kubectl
   - Helm
   - Docker

2. **AWS Authentication**:
   ```bash
   aws configure
   ```

3. **EKS Cluster Access**:
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

4. **Local Application Testing**:
   ```bash
   cd spring-petclinic
   # Follow instructions in spring-petclinic README for local development
   ```

## Cost Optimization

The deployment utilizes several cost optimization strategies:

- **Spot Instances**: EKS node groups use Spot instances for reduced compute costs
- **Aurora Serverless**: Database scales down during periods of low activity
- **Autoscaling**: HPA scales application based on demand
- **Resource Limits**: Properly sized resource requests and limits

## Disaster Recovery

The architecture includes disaster recovery mechanisms:

- **Multi-AZ Deployment**: Resources distributed across availability zones
- **Database Backups**: Automated Aurora backups
- **Terraform State**: Remote state with versioning in S3
- **Infrastructure as Code**: Reproducible infrastructure

## Documentation

Each component includes detailed documentation:

- [Network Architecture](./iac/terraform/00-network/README.md)
- [EKS Control Plane](./iac/terraform/01-control-plane/README.md)
- [Application Infrastructure](./iac/terraform/05-app-infra/README.md)
- [Kubernetes Add-ons](./deployment-configs/addons/README.md)
- [Spring PetClinic Deployment](./deployment-configs/spring-petclinic/README.md)

## Contribution Guidelines

1. **Branch Naming**:
   - Feature: `feature/name-of-feature`
   - Bugfix: `bugfix/issue-description`
   - Documentation: `doc/component-name`

2. **Pull Request Process**:
   - Create a feature branch from `main`
   - Make changes and test locally
   - Submit PR with detailed description
   - Request review from maintainers

3. **Commit Standards**:
   - Use conventional commit messages
   - Include ticket/issue reference when applicable

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Acknowledgments

- Spring PetClinic for the sample application
- AWS for cloud infrastructure services
- Kubernetes community for container orchestration
- Terraform and Helm projects for IaC and application deployment
