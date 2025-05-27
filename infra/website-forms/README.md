# data-analytics-platform-etl

This component defines a various data ingestion resources, which stage data in S3 and/or load the datawarehouse.


## Inventory

| Logical Name | Type | Description | Template | Update Policy | Deletion Policy |
|---|---|---|---|---|---|
| IamCore | AWS::CloudFormation::Stack | IAM roles and policies for website forms functions including API Gateway execution role, Lambda execution role, and CloudWatch log groups | ./resource-templates/template-iamcore.yml | (default) | (default) |
| RegistrationAction | AWS::CloudFormation::Stack | DynamoDB table, Lambda function, and SNS topic for handling website form submissions | ./resource-templates/template-registration-action.yml | (default) | (default) |
| ApiFrontend | AWS::CloudFormation::Stack | API Gateway REST API with deployment, stage, usage plan, and API key for registration endpoint | ./resource-templates/template-apigw.yml | (default) | (default) |

### Outputs

| Output Name | Value Description | Exported |
|---|---|---|
| ApiEndpoint | POST endpoint for registrations | No |

## Manual Deployment (CLI)

> ***Note***: Adding a profile to the commands below may be required depending on your local CLI configuraiton. Example: `--profile myProfile`.

- Validate template
  - CloudFormation CLI: `aws cloudformation validate-template --template-body file://template.yml`
  - CFN lint: `cfn-lint */template*.yml template.yml` (execute in same directory as template file)
- Create stack: `sh ./deploy-stack.sh --aws_profile assume --env dev --prefix mgcarclub --action create`
- Update stack: `sh ./deploy-stack.sh --aws_profile assume --env dev --prefix mgcarclub --action update`
- Delete stack: `aws cloudformation delete-stack --stack-name mgcarclub-website-forms --profile assume`
- Rollback Stack: `aws cloudformation continue-update-rollback --profile assume --stack-name mgcarclub-website-forms`
## References

- Add links here
