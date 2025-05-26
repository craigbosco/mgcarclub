#!/bin/bash

# Example: Deploying an update to dev update
# sh .\deploy-stack.sh --aws_profile default --env dev --action update


# Functions
programname=$0
usage() {
  echo ""
  echo "Deploys this component by packaging, uploading to S3 and creating/updating the CFN stack."
  echo ""
  echo "usage: $programname --aws_profile string --env string --action string --prefix string"
  echo ""
  echo "  --aws_profile string    name of the profile used for AWS cli commands"
  echo "                          (example: default)"
  echo "  --region string         region used for s3 deploy path (must match profile region)"
  echo "                          (example: update)"
  echo "  --env string            name of the env, used for selecting the associated param file"
  echo "                          (example: prod)"
  echo "  --action string         name of the deploy action: create or update"
  echo "                          (example: update)"
  echo "  --prefix string         value to prefix the stack name with"
  echo "                          (example: update)"
  echo "  --name_override string  value to use for stack name instead of prefix + folder name"
  echo "                          (example: update)"
  echo ""
}

die() {
  printf "Script failed: %s\n\n" "$1"
  exit 1
}

echoWithTime() {
  command echo "$@" -- $(date)
}


# Main
while [ $# -gt 0 ]; do
  if [ "$1" = "--help" ]; then
    usage
    exit 0
  elif [[ $1 == "--"* ]]; then
    v="${1/--/}"
    declare "$v"="$2"
    shift
  fi
  shift
done

if [[ -z "$aws_profile" ]]; then aws_profile="default"; fi
if [[ -z "$region" ]]; then region="us-east-1"; fi
if [[ -z "$env" ]]; then usage; die "Missing parameter --env"; fi
if [[ -z "$action" ]]; then usage; die "Missing parameter --action"; fi
if [[ -z "$prefix" ]]; then prefix=""; fi
if [[ -z "$name_override" ]]; then name_override=""; fi

COMPONENT_NAME=$(basename "$(pwd)")
if [ "$prefix" != "" ]; then COMPONENT_NAME=$(echo "$prefix-$COMPONENT_NAME"); fi
if [ "$name_override" != "" ]; then STACK_NAME=$name_override; else STACK_NAME=$COMPONENT_NAME; fi

echo "==================================="
echoWithTime "EXECUTING CFN DEPLOYMENT"
echo "==================================="
echo "AWS CLI Profile: $aws_profile"
echo "Environment: $env"
echo "Action: $action"
echo "Prefix: $prefix"
echo "Component Name: $COMPONENT_NAME"
echo "Stack Name = $STACK_NAME"

echo ""
echo "-----------------------------------"
echo "SETUP..."
echo ""

CICD_BUCKET=$(aws cloudformation list-exports --query "Exports[?Name=='elm-analytics-app-cicd:bucket'].[Value]" --output text --profile $aws_profile)
CICD_CMK=$(aws cloudformation list-exports --query "Exports[?Name=='elm-analytics-app-cicd:cmk'].[Value]" --output text --profile $aws_profile)

echo ""
echo "-----------------------------------"
echo "PACKAGING..."

if ! aws cloudformation package --template-file template.yml --s3-bucket $CICD_BUCKET --s3-prefix "locally-packaged/$COMPONENT_NAME" --kms-key-id $CICD_CMK --output-template-file packaged-template.yml --profile $aws_profile
then
  echo "Error detected. Exiting..."
  exit 1
fi

echo ""
echo "-----------------------------------"
echo "UPLOADING..."
echo ""

if ! aws s3 cp ./packaged-template.yml s3://$CICD_BUCKET/locally-packaged/$COMPONENT_NAME/packaged-template.yml --sse "aws:kms" --sse-kms-key-id $CICD_CMK --profile $aws_profile
then
  echo "Error detected. Exiting..."
  exit 1
fi


echo ""
echo "-----------------------------------"
echo "DEPLOYING..."
echo ""

if [ "$action" = "create" ]
then
  echo "Creating stack $STACK_NAME..."
  if ! stack_id=$(aws cloudformation create-stack --stack-name $STACK_NAME --template-url https://$CICD_BUCKET.s3.$region.amazonaws.com/locally-packaged/$COMPONENT_NAME/packaged-template.yml --parameters file://params-$env.json --cli-input-yaml file://stack-config.yml --profile $aws_profile --query "StackId" --output text)
  then
    echo "Error detected. Exiting..."
    exit 1
  fi
  echo "Waiting for operation to complete on stack: $stack_id"
  aws cloudformation wait stack-create-complete --stack-name $stack_id --profile $aws_profile

elif [ "$action" = "update" ]
then
  echo "Updating stack $STACK_NAME..."
  if ! stack_id=$(aws cloudformation update-stack --stack-name $STACK_NAME --template-url https://$CICD_BUCKET.s3.$region.amazonaws.com/locally-packaged/$COMPONENT_NAME/packaged-template.yml --parameters file://params-$env.json --cli-input-yaml file://stack-config.yml --profile $aws_profile --query "StackId" --output text)
  then
    echo "Error detected. Exiting..."
    exit 1
  fi
echo "Waiting for operation to complete on stack: $stack_id"
  aws cloudformation wait stack-update-complete --stack-name $stack_id --profile $aws_profile

else
  echo "!!! INVALID ACTION !!! Exiting..."
  exit 1
fi

echo ""
echo "-----------------------------------"
echo "CLEANUP..."
echo ""

# remove the packaged template
rm -f packaged-template.yml


echo ""
echo "==================================="
echo "COMPLETE"
echo "==================================="