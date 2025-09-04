# Infrastructure deployment configuration
environment         = "production"
application_name    = "spring-petclinic"
bucket_name         = "spring-petclinic-init-demo1"
kms_deletion_window = 7
kms_key_alias       = "spring-petclinic-init-demo1"

# Common tags for all resources
tags = {
  Application = "spring-petclinic"
  Purpose     = "Initialization Data"
}

# ECR / GitHub OIDC configuration
ecr_repository_name = "spring-petclinic"
github_owner        = "skybloouu"
github_repo         = "spring-petclinic"
github_branch       = "main"
