#!/bin/bash
set -uf -o pipefail

ATTEMPTS=5
COMPONENT_FOUND=false
VALID_STACKSET_STATUSES='ACTIVE'
WAIT_SECONDS=30

check_stack_set() {
    STACKSET_LIST=$(aws cloudformation list-stack-sets --status  $VALID_STACKSET_STATUSES --output text --query "Summaries[*].[StackSetName]")

    for stackset in $STACKSET_LIST
    do
        if [ "$stackset" = "$INPUT_STACK_OR_STACKSET_NAME" ]; then
            COMPONENT_FOUND=true
        fi
    done
}

create_stackset() {
    echo Creating stackset...
    STACKSET_ID=$(aws cloudformation create-stack-set --stack-set-name $INPUT_STACK_OR_STACKSET_NAME --template-url $INPUT_TEMPLATE_URL --parameters file://$INPUT_COMPONENT_PATH/$INPUT_PARAM_FILE_NAME --cli-input-yaml file://$INPUT_COMPONENT_PATH/$INPUT_STACKSET_CONFIG_FILE_NAME --output text)
    echo Stackset create complete
}

create_stackset_instances() {
    echo Creating stackset instances...
    OPERATION_ID=$(aws cloudformation create-stack-instances --stack-set-name $INPUT_STACK_OR_STACKSET_NAME --cli-input-yaml file://$INPUT_COMPONENT_PATH/$INPUT_INSTANCES_CONFIG_FILE_NAME --output text)
    echo "Checking stackset instances create status (operation id $OPERATION_ID)..."
    wait_for_operation $OPERATION_ID
    echo Stackset instances create complete
}

update_stackset() {
    echo Updating stackset...
    OPERATION_ID=$(aws cloudformation update-stack-set --stack-set-name $INPUT_STACK_OR_STACKSET_NAME --template-url $INPUT_TEMPLATE_URL --parameters file://$INPUT_COMPONENT_PATH/$INPUT_PARAM_FILE_NAME --cli-input-yaml file://$INPUT_COMPONENT_PATH/$INPUT_STACKSET_CONFIG_FILE_NAME --output text)
    echo Operation id = $OPERATION_ID
    wait_for_operation $OPERATION_ID
    echo Stackset update complete
}

update_stackset_instances() {
    echo Updating stackset instances...
    OPERATION_ID=$(aws cloudformation update-stack-instances --stack-set-name $INPUT_STACK_OR_STACKSET_NAME --cli-input-yaml file://$INPUT_COMPONENT_PATH/$INPUT_INSTANCES_CONFIG_FILE_NAME --output text)
    echo "Checking stackset instances update status (operation id $OPERATION_ID)..."
    wait_for_operation $OPERATION_ID
    echo Stackset instances update complete
}

wait_for_operation() {
    OP_ID=$1
    echo Checking operation...

    i=0
    while [[ i -lt $ATTEMPTS ]]
    do
        let i=i+1
        echo Querying status of operation $OP_ID...
        OPERATION_STATUS=$(aws cloudformation describe-stack-set-operation --stack-set-name $INPUT_STACK_OR_STACKSET_NAME --operation-id $OP_ID --query 'StackSetOperation.Status' --output text)
        echo Operation status = $OPERATION_STATUS

        if [ "$OPERATION_STATUS" = "SUCCEEDED" ]; then
            echo "Operation succeeded"
            break;
        elif [ "$OPERATION_STATUS" = "RUNNING" ] || [ "$OPERATION_STATUS" = "QUEUED" ]; then
            if [ $i -eq $ATTEMPTS ]; then
                echo "Operation did not complete in a timely manner."
                exit 1
            else
                echo "Wait and query again..."
                sleep $WAIT_SECONDS
            fi
        else
            echo "Operation failed, stopped or is stopping."
            exit 1
        fi
    done
}

echo Deploying StackSet $INPUT_STACK_OR_STACKSET_NAME...
echo INPUT_COMPONENT_PATH = $INPUT_COMPONENT_PATH
echo INPUT_INSTANCES_CONFIG_FILE_NAME = $INPUT_INSTANCES_CONFIG_FILE_NAME
echo INPUT_PARAM_FILE_NAME = $INPUT_PARAM_FILE_NAME
echo INPUT_STACK_OR_STACKSET_NAME = $INPUT_STACK_OR_STACKSET_NAME
echo INPUT_STACKSET_CONFIG_FILE_NAME = $INPUT_STACKSET_CONFIG_FILE_NAME
echo INPUT_TEMPLATE_URL = $INPUT_TEMPLATE_URL

echo Determining deploy action...
check_stack_set

if [[ "$COMPONENT_FOUND"  == true ]]
then
    update_stackset
else
    create_stackset
fi

# Calling create stack instances appears to be idempotent, handling creation of initial stackset instances
#   as well as adding instances to an existing stackset. Removal of stack instances is not supported by this script.
create_stackset_instances

echo "Script execution complete"
