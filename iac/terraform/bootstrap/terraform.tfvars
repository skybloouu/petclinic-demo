# Provide real values before applying.
github_owner                = "skybloouu"
github_repo                 = "petclinic-demo"
allowed_branches            = ["main"]
create_github_oidc_provider = false
# Use import to get the existing provider ARN or uncomment and use the AWS CLI:
# aws iam list-open-id-connect-providers
existing_github_oidc_provider_arn = "arn:aws:iam::906766085108:oidc-provider/token.actions.githubusercontent.com" # Replace with actual ARN
