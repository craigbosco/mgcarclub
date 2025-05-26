#!/bin/bash
set -uf -o pipefail

COMPONENT_FOUND=false
VALID_STACK_STATUSES='CREATE_COMPLETE UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE UPDATE_ROLLBACK_FAILED'

check_stack() {
    QUERY_RESULT=$(aws cloudformation list-stacks --stack-status-filter $VALID_STACK_STATUSES --output text --query "StackSummaries[?StackName==\`$INPUT_STACK_OR_STACKSET_NAME\`].[StackName]")

    if [ "$QUERY_RESULT" != "" ]; then
        echo FOUND
        COMPONENT_FOUND=true
    fi
}

create_stack() {
    echo Creating stack...
    STACK_ID=$(aws cloudformation create-stack --stack-name $INPUT_STACK_OR_STACKSET_NAME --template-url $INPUT_TEMPLATE_URL --parameters file://$INPUT_COMPONENT_PATH/$INPUT_PARAM_FILE_NAME --cli-input-yaml file://$INPUT_COMPONENT_PATH/$INPUT_CONFIG_FILE_NAME --output text)
    echo Checking stack create status...
    aws cloudformation wait stack-create-complete --stack-name $STACK_ID
      status=$?

      if [[ ${status} -ne 0 ]] ; then
          # Waiter encountered a failure state.
          echo "ERROR: Stack creation failed. AWS error code is ${status}."
          exit ${status}
      else
        echo "Stack create complete"
      fi
}

update_stack() {
    echo Updating stack...
    output=$(aws cloudformation update-stack --stack-name $INPUT_STACK_OR_STACKSET_NAME --template-url $INPUT_TEMPLATE_URL --parameters file://$INPUT_COMPONENT_PATH/$INPUT_PARAM_FILE_NAME --cli-input-yaml file://$INPUT_COMPONENT_PATH/$INPUT_CONFIG_FILE_NAME --output text 2>&1)
    RESULT=$?

    if [ $RESULT -ne 0 ]; then
      if [[ "$output" == *"No updates are to be performed"* ]]; then
        echo "No CloudFormation stack updates are to be performed."
      else
        echo "ERROR: Output of update stack call = $output"
        exit 1
      fi
    else
      echo "Stack ID = $output"
      echo Checking stack update status...
      aws cloudformation wait stack-update-complete --stack-name $output
      status=$?

      if [[ ${status} -ne 0 ]] ; then
          # Waiter encountered a failure state.
          echo "ERROR: Stack update failed. AWS error code is ${status}."
          exit ${status}
      else
        echo "Stack update complete"
      fi
    fi
}

echo Deploying Stack $INPUT_STACK_OR_STACKSET_NAME...
echo INPUT_COMPONENT_PATH = $INPUT_COMPONENT_PATH
echo INPUT_CONFIG_FILE_NAME = $INPUT_CONFIG_FILE_NAME
echo INPUT_PARAM_FILE_NAME = $INPUT_PARAM_FILE_NAME
echo INPUT_STACK_OR_STACKSET_NAME = $INPUT_STACK_OR_STACKSET_NAME
echo INPUT_TEMPLATE_URL = $INPUT_TEMPLATE_URL

echo Determining deploy action...
check_stack

if [[ "$COMPONENT_FOUND"  == true ]]
then
    update_stack
else
    create_stack
fi
echo "Script execution complete"
