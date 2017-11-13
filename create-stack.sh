#!/usr/bin/env bash
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

#set the account numbers and profiles of two accounts

#AccountA: the custom Lambda resource is deployed here, which looks up CloudFormation exports in Account B
AccountA=123456789012
AccountAProfile=<your profile name for AccountA>
#AccountB: the cross-account role is deployed here, which allows AccountA to lookup CloudFormation exports in Account B
AccountB=123456789012
AccountBProfile=<your profile name for AccountB>
#region to deploy the stacks into
region=us-east-1
#temporary bucket used to upload the SAM template. PUT access is required
S3_TMP_BUCKET=<your bucket name>

#deploy cross account role to Account B
echo -e "Creating cross-account role in Account B"
aws cloudformation deploy --stack-name cross-account-role --template-file cross-account-role.yaml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides AccountA=$AccountA --profile $AccountBProfile --region $region

#get the role ARN
CrossAccountRole=$(aws cloudformation describe-stacks --stack-name cross-account-role --profile $AccountBProfile --region $region --query 'Stacks[0].Outputs[?OutputKey==`CrossAccountRole`].OutputValue' --output text)
echo -e "CrossAccountRole: $CrossAccountRole"

#deploy custom resource to Account A
echo -e "creating custom resource in Account A"
cd custom
pip install -r requirements.txt -t .
aws cloudformation package --template-file custom-lookup-exports.yaml --s3-bucket $S3_TMP_BUCKET --s3-prefix custom --output-template-file output-custom-lookup-exports.yaml --profile $AccountAProfile --region $region
aws cloudformation deploy --stack-name custom-lookup --template-file output-custom-lookup-exports.yaml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides CrossAccountRole=$CrossAccountRole --profile $AccountAProfile --region $region
cd ..

#test the cross account stack lookup
echo -e "creating the test stacks"
aws cloudformation deploy --template-file test/test-stack-account-B.yaml --stack-name test-stack-account-B --profile $AccountBProfile --region $region
aws cloudformation deploy --template-file test/test-stack-account-A.yaml --stack-name test-stack-account-A --profile $AccountAProfile --region $region
