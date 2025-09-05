# Deployment Configurations

This directory contains Kubernetes deployment configurations for the Spring PetClinic application and its supporting infrastructure. The configurations are organized as Helm charts for modular, repeatable deployments across environments.

## Directory Structure

```
deployment-configs/
├── addons/             # Kubernetes cluster add-ons
│   ├── charts/         # Helm chart repositories
│   ├── *.yaml          # Values files for add-ons
│   └── README.md       # Add-ons documentation
└── spring-petclinic/   # Application Helm chart
    ├── templates/      # Kubernetes resource templates
    ├── Chart.yaml      # Chart metadata
    ├── values.yaml     # Default configuration values
    └── README.md       # Application chart documentation
```

## Overview

The deployment configurations are split into two main categories:

1. **Cluster Add-ons**: Infrastructure components that enhance the EKS cluster
2. **Application Chart**: Spring PetClinic application deployment definition

This separation allows for clear ownership and independent lifecycle management of infrastructure versus application components.

## Cluster Add-ons

The `/addons` directory contains Helm chart values and configurations for essential cluster components:

- **AWS Load Balancer Controller**: Manages AWS ALB/NLB resources for Kubernetes Ingress
- **cert-manager**: Automates TLS certificate provisioning and management
- **Metrics Server**: Provides resource metrics for Horizontal Pod Autoscaler
- **External DNS**: Automates DNS record management in Route 53

These add-ons provide foundational capabilities required by the application, such as external access, TLS termination, and autoscaling.

For detailed information on add-ons, see the [Add-ons README](./addons/README.md).

## Application Chart

The `/spring-petclinic` directory contains a custom Helm chart for deploying the Spring PetClinic application. The chart includes:

- **Deployment**: Application container configuration
- **Service**: Internal networking setup
- **Ingress**: External access configuration using ALB
- **ConfigMap/Secrets**: Configuration and sensitive data management
- **HPA**: Horizontal scaling rules
- **ServiceAccount**: Identity for AWS service integration

The application chart is configured to work with AWS services like Aurora MySQL, S3, and Secrets Manager, leveraging the infrastructure provisioned by Terraform.

For detailed information on the application chart, see the [Spring PetClinic README](./spring-petclinic/README.md).

## Deployment Workflow

The typical deployment workflow follows this sequence:

1. **Provision Infrastructure**: Apply Terraform modules (00-network, 01-control-plane, 05-app-infra)
2. **Install Cluster Add-ons**: Deploy components from the `/addons` directory
3. **Deploy Application**: Apply the Spring PetClinic Helm chart

This workflow can be automated using CI/CD pipelines defined in your Git repository.

## Environment-Specific Configurations

For multi-environment deployments:

1. Create environment-specific values files (e.g., `values-dev.yaml`, `values-prod.yaml`)
2. Apply with environment override: `helm upgrade --install petclinic ./spring-petclinic -f values-dev.yaml`

## Security Considerations

The deployment configurations implement several security best practices:

- **IRSA**: IAM Roles for Service Accounts for AWS service access
- **Namespace Isolation**: Separate namespaces for different components
- **Network Policies**: Traffic control between application components
- **Secret Management**: Integration with AWS Secrets Manager
- **TLS Everywhere**: HTTPS for all external access

## Monitoring & Observability

The deployment includes configurations for:

- **Health Checks**: Liveness and readiness probes
- **Metrics**: Prometheus-compatible metrics endpoints
- **Logging**: Container logs captured via CloudWatch

## CI/CD Integration

These deployment configurations can be applied using:

- **GitHub Actions**: Workflows for automated deployments
- **ArgoCD**: GitOps-based continuous delivery
- **Manual Deployment**: Step-by-step commands for development

## Prerequisites

Before using these configurations:

1. AWS account with appropriate permissions
2. Kubernetes cluster provisioned with Terraform
3. `kubectl` and `helm` CLI tools configured
4. AWS CLI with proper credentials

## Troubleshooting

For deployment issues:

1. Check pod status: `kubectl get pods -n <namespace>`
2. View logs: `kubectl logs <pod-name> -n <namespace>`
3. Describe resources: `kubectl describe <resource> <name> -n <namespace>`
4. Verify Helm releases: `helm list -n <namespace>`
