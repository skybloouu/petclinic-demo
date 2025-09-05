# EKS Add-ons Helm Definitions

This directory contains Helm chart configuration (values files and helper scripts) for cluster add-ons. Apply using `helm upgrade --install` manually or via CI/CD.

## Included Add-ons

1. **AWS Load Balancer Controller** (`aws-load-balancer-controller`)
   - Manages AWS Application and Network Load Balancers for Kubernetes
   - Provides Ingress implementation for Kubernetes
   - Enables traffic routing from AWS load balancers to Kubernetes services
   - Integrates with AWS Certificate Manager for TLS

2. **Metrics Server** (`metrics-server`)
   - Collects resource metrics from Kubernetes nodes and pods
   - Provides metrics for Horizontal Pod Autoscaler
   - Required for `kubectl top` command functionality
   - Lightweight and efficient metrics collection

3. **cert-manager** (`cert-manager`)
   - Automates certificate issuance and renewal
   - Integrates with Let's Encrypt for free TLS certificates
   - Manages certificate lifecycle in Kubernetes
   - Supports DNS and HTTP validation methods

4. **External DNS** (`external-dns`)
   - Automates DNS record management in Route 53
   - Synchronizes Kubernetes Ingress and Service resources with DNS records
   - Supports multiple DNS providers with AWS Route 53 as primary
   - Enables custom domain names for services

## Add-on Configuration Details

### AWS Load Balancer Controller

The controller is configured with:
- IAM Roles for Service Accounts (IRSA) integration
- Service account annotation for IAM role assumption
- Resource requests and limits for proper resource allocation
- VPC ID configuration for load balancer placement
- Region configuration for AWS API calls

Functionality:
- Creates and manages ALB/NLB based on Ingress and Service resources
- Configures target groups, listeners, and rules
- Manages security groups for load balancers
- Integrates with AWS WAF and Shield for security

### Metrics Server

Configured with:
- Kubelet certificate authentication
- Resource allocation appropriate for cluster size
- API service configuration for metrics API
- Aggregation layer integration

Functionality:
- Collects CPU and memory metrics from nodes and pods
- Exposes metrics API for HPA and other components
- Provides data for resource monitoring
- Supports Kubernetes autoscaling mechanisms

### cert-manager

Deployed with:
- Dedicated namespace for security isolation
- ClusterIssuer definitions for certificate authorities
- ACME configuration for Let's Encrypt integration
- Proper RBAC permissions for certificate management

Functionality:
- Issues certificates based on Ingress annotations or Certificate CRDs
- Manages certificate renewal and validation
- Creates Kubernetes secrets with certificate data
- Supports both staging and production Let's Encrypt environments

### External DNS

Set up with:
- IAM role for Route 53 access
- Configured to manage specific DNS zones
- Policy for record ownership
- TTL settings for DNS records

Functionality:
- Watches Ingress and Service resources for DNS annotations
- Creates and updates DNS records in Route 53
- Manages record ownership to prevent conflicts
- Supports various record types (A, CNAME, TXT)

## Prerequisites
- EKS cluster OIDC provider enabled.
- IAM roles/policies created for service accounts where required (ALB controller & external-dns).
- Kubernetes cluster with version 1.19+ for full compatibility
- AWS CLI access and permissions for IAM role creation
- Helm 3.x installed locally or in CI/CD

## Apply Order
1. metrics-server
2. cert-manager
3. aws-load-balancer-controller
4. external-dns (after IAM permissions + hosted zone)

This order ensures dependencies are satisfied, as the AWS Load Balancer Controller may depend on cert-manager for certificate issuance, and external-dns requires ALB controller to be functional for Ingress resources.

## Example Commands
```bash
# Add Helm repositories
helm repo add eks https://aws.github.io/eks-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

# Install each add-on
helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system -f addons/metrics-server-values.yaml
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --version v1.15.1 -f addons/cert-manager-values.yaml
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system -f addons/aws-load-balancer-controller-values.yaml
helm upgrade --install external-dns external-dns/external-dns -n kube-system -f addons/external-dns-values.yaml
```

## Verification Steps

After installing each add-on, verify its operation:

### Metrics Server
```bash
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl top nodes
```

### cert-manager
```bash
kubectl get pods -n cert-manager
kubectl get clusterissuers
```

### AWS Load Balancer Controller
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### External DNS
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns
```

## Troubleshooting

Common issues and solutions:

### AWS Load Balancer Controller
- **Pod creation failure**: Check IAM role permissions and OIDC trust relationship
- **Ingress not creating ALB**: Verify annotations and security group permissions
- **Target group registration issues**: Check node security groups and subnets

### cert-manager
- **Certificate issuance failure**: Check ClusterIssuer configuration and ACME challenge setup
- **Validation errors**: Verify DNS or HTTP challenge accessibility
- **Rate limiting**: Check for Let's Encrypt rate limits on issuance attempts

### Metrics Server
- **Connection refused**: Check kubelet certificate authentication settings
- **No metrics available**: Verify apiservice registration and aggregation layer

### External DNS
- **DNS records not created**: Check IAM permissions for Route 53 access
- **Ownership conflicts**: Verify txt-owner-id configuration
- **Zone filtering issues**: Check domain-filter settings

## Customization

To customize the add-ons:

1. Copy the appropriate values file
2. Modify the required parameters
3. Apply with `helm upgrade --install` specifying your custom values file`
