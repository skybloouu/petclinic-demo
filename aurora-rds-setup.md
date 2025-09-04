# Aurora MySQL RDS Configuration for Spring PetClinic

This document outlines the changes made to configure the Spring PetClinic application to use Aurora MySQL Serverless v2.

## Infrastructure Changes

### Aurora Serverless v2 Setup (Terraform)

A new Aurora MySQL Serverless v2 cluster has been created in the `05-app-infra` folder with the following characteristics:

- **Compute Configuration**: Serverless v2 with 0.5-1.0 ACU range (minimum possible for cost optimization)
- **Engine**: Aurora MySQL 8.0
- **Security**: 
  - Deployed in private data subnets
  - Security group to allow inbound MySQL traffic from the EKS cluster
  - KMS encryption for data at rest
- **Access Management**:
  - Credentials stored in AWS Secrets Manager
  - IAM role for the application to access the credentials
- **Monitoring**:
  - Performance Insights enabled with 7-day retention (free tier eligible)
  - CloudWatch Logs for audit, error, general, and slow query logs

### Application Configuration

1. Added a new `application-aurora.properties` file with optimized connection pool settings for Aurora Serverless v2
2. Updated Helm chart to:
   - Use the Aurora profile
   - Deploy an init container to fetch database credentials from AWS Secrets Manager
   - Configure environment variables for database connection

## Cost Optimization Features

1. **Minimum ACU Setting**: 0.5 ACU (lowest possible) to minimize costs during idle periods
2. **Maximum ACU Capping**: 1.0 ACU to prevent unexpected scaling and costs
3. **Single Instance Deployment**: Only deploying a writer instance with no additional read replicas
4. **Performance Insights**: Limited to 7-day retention (free tier eligible)
5. **IAM Authentication**: Using IAM for security rather than database users
6. **Secrets Manager**: Centralized credential management for security and easy rotation

## Deployment Instructions

### 1. Deploy the Aurora RDS Infrastructure

```bash
cd petclinic-demo/iac/terraform/05-app-infra
terraform init
terraform plan
terraform apply
```

### 2. Update Helm Values

Update the Helm values to point to the new Aurora RDS endpoint:

```bash
cd petclinic-demo/deployment-configs
helm upgrade spring-petclinic ./spring-petclinic --install \
  --namespace petclinic \
  --set app.springProfile=aurora \
  --set database.secretsManager.enabled=true \
  --set database.secretsManager.secretName=spring-petclinic-db-credentials-production
```

### 3. Verify Database Connection

Check the application logs to ensure it's connecting to Aurora:

```bash
kubectl logs -n petclinic deployment/spring-petclinic
```

## Scaling Considerations

The current configuration uses minimal resources for cost optimization. If you need to scale:

1. Update the serverlessv2_scaling_configuration in the terraform code:
   ```terraform
   serverlessv2_scaling_configuration {
     min_capacity = 0.5  # Can increase to 1.0 or higher if needed
     max_capacity = 1.0  # Can increase to handle higher loads
   }
   ```

2. Consider adding read replicas for read-heavy workloads:
   ```terraform
   resource "aws_rds_cluster_instance" "aurora_reader" {
     count              = 1  # Set to desired number of readers
     identifier         = "${var.application_name}-aurora-reader-${count.index}-${var.environment}"
     cluster_identifier = aws_rds_cluster.aurora_mysql.id
     instance_class     = "db.serverless"
     engine             = aws_rds_cluster.aurora_mysql.engine
     engine_version     = aws_rds_cluster.aurora_mysql.engine_version
   }
   ```
