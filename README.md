# AWS Custom Resource - Cross Account Lookup
CloudFormation custom resource that will lookup CloudFormation stack exports in other accounts.

## Sample scenario
This scenario is an example of how the custom lookup could be used across accounts:

* You use CloudFormation to create your own Lambda function in Account A that wants to subscribe to an SNS Topic in Account B
* The CloudFormation template defines the custom resource provided in this repo
* The custom resource allows your CloudFormation template to lookup a CloudFormation stack export value in Account B
* You use the custom resource to lookup the SNS Topic ARN in Account B
* Your CloudFormation template in Account A creates a subscription to the SNS Topic in Account B

## How does it work?
The custom resource works as follows:
* An IAM role is created in Account B, which can be assumed by Account A
* A Lambda function, defined in custom-lookup-exports.py, is created in Account A that assumes the role in Account B
* Any CloudFormation template in Account A can define the Lambda function as a custom resource 
* The CloudFormation template in Account A invokes the Lambda resource, passing a CloudFormation export value name that exists in Account B
* The Lambda function assumes the role in Account B and looks up the CloudFormation export value
* The CloudFormation template in Account A can now refer to the resource in Account B

## Example
create-stack.sh will create an example so you can see how this works.

See the /test folder.
* test-stack-account-B.yaml: CloudFormation template that creates an SNS Topic in Account B, and exports the value 
* test-stack-account-A.yaml CloudFormation template in Account A that defines the custom resource and looks up the 
SNS Topic ARN in Account B. It then outputs this value. Check the Output tab for the appropriate CloudFormation stack
in the AWS Console

## Install
See create-stack.sh for details on how to install the custom resource

## Cleanup
See cleanup-stack.sh for details on how to remove the custom resource
