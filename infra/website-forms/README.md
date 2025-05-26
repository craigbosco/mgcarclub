# data-analytics-platform-etl

This component defines a various data ingestion resources, which stage data in S3 and/or load the datawarehouse.


## Inventory

| Logical Name | Type | Description | Template | Update Policy | Deletion Policy |
|---|---|---|---|---|---|
| Job | AWS::Glue::Job | Standard Glue Job definition, parameterized to facilitate reuse. | ./resource-templates/template-etl-job.yml | (default) | (default) |

### Outputs

| Output Name | Value Description | Exported |
|---|---|---|
|  |  |  |

## Manual Deployment (CLI)

> ***Note***: Adding a profile to the commands below may be required depending on your local CLI configuraiton. Example: `--profile myProfile`.

- Validate template
  - CloudFormation CLI: `aws cloudformation validate-template --template-body file://template.yml`
  - CFN lint: `cfn-lint */template*.yml template.yml` (execute in same directory as template file)
- Create stack: `sh ./deploy-stack.sh --aws_profile assume --env dev --prefix elm-analytics --action create`
- Update stack: `sh ./deploy-stack.sh --aws_profile assume --env dev --prefix elm-analytics --action update`
- Delete stack: `aws cloudformation delete-stack --stack-name elm-analytics-etl-oracle --profile assume`
- Rollback Stack: `aws cloudformation continue-update-rollback --profile assume --stack-name elm-analytics-etl-edw`
## References

- Add links here
