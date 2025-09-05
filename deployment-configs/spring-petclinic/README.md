# Spring PetClinic Helm Chart

This directory contains the Helm chart for deploying the Spring PetClinic application on Kubernetes. The chart defines all Kubernetes resources needed to run the application in a production-ready configuration with proper scaling, monitoring, and security controls.

## Overview

The Spring PetClinic Helm chart deploys a containerized version of the Spring PetClinic application, configured to work with:

1. **Aurora MySQL Database**: External AWS Aurora Serverless v2 database
2. **AWS Integrations**: S3 for configuration data, Secrets Manager for credentials
3. **Load Balancing**: AWS Application Load Balancer via Ingress
4. **Autoscaling**: Horizontal Pod Autoscaler for dynamic scaling

## Chart Components

### 1. Deployment

Defines the PetClinic application deployment with:
- Container image configuration
- Resource requests and limits
- Probes for health monitoring
- Environment variable configuration
- AWS service integration
- Multi-replica deployment for high availability

### 2. Service

Exposes the application within the cluster:
- ClusterIP service type
- Port configuration for HTTP traffic
- Selector for targeting application pods

### 3. Ingress

Configures external access through AWS ALB:
- Integration with AWS Load Balancer Controller
- TLS termination with ACM certificates
- Path-based routing
- Health check configuration
- SSL redirection

### 4. Horizontal Pod Autoscaler (HPA)

Provides automatic scaling based on CPU utilization:
- Minimum 2 replicas for high availability
- Maximum 5 replicas for peak loads
- Target CPU utilization of 80%

### 5. ServiceAccount

Enables AWS service access via IRSA:
- Integration with IAM role
- Permissions for S3 and Secrets Manager

### 6. ConfigMap & Secrets

Manages application configuration:
- Database connection information
- Application configuration
- Integration with AWS Secrets Manager

## Configuration Values

The `values.yaml` file provides extensive configuration options:

### Application Settings
- `app.contextPath`: Web context path (/petclinic)
- `app.healthPath`: Health check endpoint
- `app.springProfile`: Active Spring profile

### AWS Integration
- `aws.region`: AWS region for all service integrations
- `initData`: S3 bucket configuration for initialization data
- `serviceAccount.annotations`: IAM role ARN for IRSA

### Database Configuration
- `database.type`: Database type (Aurora MySQL)
- `database.secretsManager`: AWS Secrets Manager integration
- Fallback database configuration

### Deployment Settings
- `replicaCount`: Initial replica count
- `image`: Container image repository, tag, and pull policy
- `resources`: CPU and memory allocation
- `probes`: Health check configuration

### Scaling & Availability
- `autoscaling`: HPA configuration
- `podAntiAffinity`: Pod distribution across zones

### Networking
- `ingress`: ALB configuration with annotations
- `service`: Kubernetes service configuration

## Customization

The chart can be customized by:

1. **Creating a values override file**: Create a file with only the values you want to override
2. **Using --set flags**: Override specific values via the command line
3. **Modifying the base values.yaml**: Update the default values directly

## Deployment

Deploy the application using:

```bash
# From the deployment-configs directory
helm upgrade --install petclinic ./spring-petclinic \
  --namespace petclinic \
  --create-namespace \
  -f spring-petclinic/values.yaml
```

Or with overrides:

```bash
helm upgrade --install petclinic ./spring-petclinic \
  --namespace petclinic \
  --create-namespace \
  -f spring-petclinic/values.yaml \
  -f my-overrides.yaml
```

## Prerequisites

Before deploying this chart, ensure:

1. EKS cluster is properly configured
2. AWS Load Balancer Controller is installed
3. Aurora database is provisioned and credentials are in Secrets Manager
4. S3 bucket for initialization data exists
5. IAM role for IRSA is created with appropriate permissions
6. (Optional) ACM certificate for HTTPS is provisioned

## Environment-Specific Configurations

For multi-environment deployments:

1. Create environment-specific values files (e.g., `values-dev.yaml`, `values-prod.yaml`)
2. Override critical values like:
   - Image tag
   - Replica count and resource allocation
   - Database endpoints
   - Domain names and TLS certificates

## Security Considerations

This chart implements several security best practices:

1. **IRSA**: Uses IAM Roles for Service Accounts for AWS access
2. **Secrets Management**: Integrates with AWS Secrets Manager
3. **TLS**: Configures HTTPS with AWS-managed certificates
4. **Resource Isolation**: Deploys to a dedicated namespace
5. **Least Privilege**: Service account with minimal permissions

## Monitoring & Logging

The application exposes:

1. **Health Endpoints**: Spring Boot Actuator for health checks
2. **Metrics**: JMX and Prometheus endpoints
3. **Logs**: Standard output captured by Kubernetes

## Troubleshooting

Common issues and solutions:

1. **Pod startup failures**: Check pod logs and events
2. **Database connection issues**: Verify Secret Manager access and DB credentials
3. **S3 access problems**: Confirm IAM role permissions
4. **Ingress not working**: Check ALB controller logs and security groups
