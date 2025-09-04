# Aurora Serverless v2 configuration for Spring PetClinic application
# This file configures an Aurora MySQL Serverless v2 cluster for cost optimization

locals {
  db_name     = "petclinic"
  master_user = "petclinic"
}

# Get VPC and subnet information from the network stack
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "stackgen-terraform-state"
    key     = "env/00-network/terraform.tfstate"
    region  = "ap-south-1"
    profile = "personal"
  }
}

# Generate a random password for the database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the database credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "petclinic_db_secret" {
  name        = "${var.application_name}-db-credentials-${var.environment}"
  description = "Spring PetClinic Aurora MySQL credentials"

  tags = merge(
    {
      Environment = var.environment
      Application = var.application_name
    },
    var.tags
  )
}

# Store the JSON secret value with username and password
resource "aws_secretsmanager_secret_version" "petclinic_db_secret_version" {
  secret_id = aws_secretsmanager_secret.petclinic_db_secret.id
  secret_string = jsonencode({
    username = local.master_user
    password = random_password.db_password.result
    dbname   = local.db_name
    port     = 3306
    host     = aws_rds_cluster.aurora_mysql.endpoint
  })
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Create a security group for the Aurora cluster
resource "aws_security_group" "aurora_sg" {
  name        = "${var.application_name}-aurora-sg-${var.environment}"
  description = "Security group for Aurora MySQL cluster"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  # Allow inbound traffic from the EKS cluster on MySQL port
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    description = "MySQL access from within VPC"
    cidr_blocks = ["100.64.0.0/16"] # Replace with actual VPC CIDR if different
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.application_name}-aurora-sg-${var.environment}"
      Environment = var.environment
      Application = var.application_name
    },
    var.tags
  )
}

# Aurora MySQL parameter group
resource "aws_rds_cluster_parameter_group" "aurora_mysql_pg" {
  name        = "${var.application_name}-aurora-pg-${var.environment}"
  family      = "aurora-mysql8.0"
  description = "Parameter group for Aurora MySQL Serverless v2"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = merge(
    {
      Environment = var.environment
      Application = var.application_name
    },
    var.tags
  )
}

# Aurora MySQL DB cluster
resource "aws_rds_cluster" "aurora_mysql" {
  cluster_identifier              = "${var.application_name}-aurora-${var.environment}"
  engine                          = "aurora-mysql"
  engine_mode                     = "provisioned"
  engine_version                  = "8.0.mysql_aurora.3.04.1" # Compatible version
  database_name                   = local.db_name
  master_username                 = local.master_user
  master_password                 = random_password.db_password.result
  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.aurora_sg.id]
  backup_retention_period         = 7
  preferred_backup_window         = "03:00-05:00"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_mysql_pg.name

  # Enable deletion protection in production
  deletion_protection = var.environment == "production" ? true : false

  # Enable storage encryption
  storage_encrypted = true

  # Serverless v2 settings
  serverlessv2_scaling_configuration {
    min_capacity = 0.5 # Lowest possible for cost optimization
    max_capacity = 1.0 # Start small, can be increased as needed
  }

  # Skip final snapshot for dev/test, keep for prod
  skip_final_snapshot       = var.environment != "production"
  final_snapshot_identifier = var.environment == "production" ? "${var.application_name}-aurora-final-${var.environment}" : null

  # Enable MySQL 8.0 features
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = merge(
    {
      Environment = var.environment
      Application = var.application_name
    },
    var.tags
  )

  # Only create DB instances after the cluster is ready
  lifecycle {
    ignore_changes = [master_password]
  }
}

# Create DB subnet group
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = "${var.application_name}-aurora-subnet-group-${var.environment}"
  description = "Aurora MySQL subnet group"
  subnet_ids  = data.terraform_remote_state.network.outputs.data_subnet_ids

  tags = merge(
    {
      Environment = var.environment
      Application = var.application_name
    },
    var.tags
  )
}

# Aurora MySQL DB instance - Writer (Serverless v2)
resource "aws_rds_cluster_instance" "aurora_writer" {
  identifier           = "${var.application_name}-aurora-writer-${var.environment}"
  cluster_identifier   = aws_rds_cluster.aurora_mysql.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora_mysql.engine
  engine_version       = aws_rds_cluster.aurora_mysql.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # Performance Insights for monitoring
  performance_insights_enabled          = true
  performance_insights_retention_period = 7 # Free tier eligible

  tags = merge(
    {
      Environment = var.environment
      Application = var.application_name
      Role        = "Writer"
    },
    var.tags
  )
}

# Add permissions to the IRSA role to access the database secret
data "aws_iam_policy_document" "db_permissions" {
  statement {
    sid    = "GetDBCredentialsFromSecretManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.petclinic_db_secret.arn]
  }
}

resource "aws_iam_policy" "db_access_policy" {
  name        = "${var.application_name}-db-access-${var.environment}"
  description = "Policy to allow access to Aurora DB credentials"
  policy      = data.aws_iam_policy_document.db_permissions.json
}

resource "aws_iam_role_policy_attachment" "db_access_attachment" {
  role       = aws_iam_role.app_irsa.name
  policy_arn = aws_iam_policy.db_access_policy.arn
}
