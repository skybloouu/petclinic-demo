# EKS Add-ons Helm Definitions

This directory contains Helm chart configuration (values files and helper scripts) for cluster add-ons. Apply using `helm upgrade --install` manually or via CI/CD.

## Included Add-ons

1. AWS Load Balancer Controller (`aws-load-balancer-controller`)
2. Metrics Server (`metrics-server`)
3. cert-manager (`cert-manager`)
4. External DNS (`external-dns`)

## Prerequisites
- EKS cluster OIDC provider enabled.
- IAM roles/policies created for service accounts where required (ALB controller & external-dns).

## Apply Order
1. metrics-server
2. cert-manager
3. aws-load-balancer-controller
4. external-dns (after IAM permissions + hosted zone)

## Example Commands
```
helm repo add eks https://aws.github.io/eks-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system -f addons/metrics-server-values.yaml
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --version v1.15.1 -f addons/cert-manager-values.yaml
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system -f addons/aws-load-balancer-controller-values.yaml
helm upgrade --install external-dns external-dns/external-dns -n kube-system -f addons/external-dns-values.yaml
```
