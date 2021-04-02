#!/usr/bin/env bash

#!/bin/bash
###########################
## Use for local deploys ##
###########################

set -e

SUBDOMAIN="blog"
ZONE_NAME="kye.dev"

DOCKER_BUILDKIT=1 docker build -f ./infrastructure/Dockerfile.static --output type=local,dest=dist/ .

# Terraform state, bucket name
AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
terraform_state_bucket="terraform-remote-$AWS_ACCOUNT_ID"

# # TF version
tf_ver="v0.14.9"; if [[ ! $(Terraform --version) =~ "Terraform $tf_ver" ]]; then echo "Terraform $tf_ver is required"; exit 1; fi

mkdir -p build

# pushd infrastructure
# zip -r "../build/edge.zip" lambdaEdge/
# popd

# # Cleanup .terraform
pushd infrastructure/terraform
# rm -rf .terraform/

# # Deploy terraform
terraform init \
  -backend-config bucket="${terraform_state_bucket}"

# # If the workspace does not exist, create it.
# if ! terraform workspace select ${WORKSPACE}; then
#     terraform workspace new ${WORKSPACE}
# fi
TF_VAR_subdomain_name=$SUBDOMAIN TF_VAR_hosted_zone_name=$ZONE_NAME terraform apply -auto-approve
BUCKET_NAME=$(terraform output --raw bucket_name)
popd

aws s3 sync dist/ s3://$BUCKET_NAME/ --exclude \"*.DS_Store*\"; exit_status=$?; if [ $exit_status -eq 2 ]; then exit 0; fi; exit $exit_status
aws s3 cp dist/index.html s3://$BUCKET_NAME/ --cache-control max-age=0