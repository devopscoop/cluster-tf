# Bootstrap

Based on:
- https://github.com/trussworks/terraform-aws-bootstrap
- https://opentofu.org/docs/language/settings/backends/configuration/

OpenTofu needs a place to store its state data files. In an AWS environment, we need an encrypted S3 bucket to store the files, and we use DynamoDB to control state locking.

This is a one-time setup process that needs to be done once per AWS account. This directory has everything we need to set it up.

1. Create a tfvars file for you environment in the root directory of this git repo. For example:
  ```
  # dev.tfvars
  account_alias = "devopscoop-dev"
  region        = "us-east-2"
  ```
1. Change to bootstrap dir:
  ```
  cd bootstrap
  ```
1. Set your AWS_PROFILE to one that has enough access to create the resources:
  ```
  export AWS_PROFILE=devopscoop_dev_AdministratorAccess
  ```
1. Initialize the repo:
  ```
  tofu init -var-file=dev.tfvars
  ```
1. Apply the code to create the S3 bucket and DynamoDB:
  ```
  tofu apply -var-file=dev.tfvars
  ```
1. Against our better judgement, commit the terraform.tfstate* files to the repo. This is normally SUPER-FORBIDDEN! State files often have cleartext secrets in them, and we NEVER want to commit secrets to the repo. However, these particular files don't have any secrets in them:
  ```
  git add -f terraform.tfstate*
  git commit -m "Bootstrapping OpenTofu"
  git push
  ```
