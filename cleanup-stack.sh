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

#delete the test stacks
echo -e "deleting test stacks"
aws cloudformation delete-stack --stack-name test-stack-account-B --profile $AccountBProfile --region $region
aws cloudformation wait stack-delete-complete --stack-name test-stack-account-B --profile $AccountBProfile --region $region
aws cloudformation delete-stack --stack-name test-stack-account-A --profile $AccountAProfile --region $region
aws cloudformation wait stack-delete-complete --stack-name test-stack-account-A --profile $AccountAProfile --region $region

#delete custom resource in Account A
echo -e "deleting custom resource in Account A"
aws cloudformation delete-stack --stack-name custom-lookup --profile $AccountAProfile --region $region
aws cloudformation wait stack-delete-complete --stack-name custom-lookup --profile $AccountAProfile --region $region

#delete cross account role in Account B
echo -e "deleting cross account role in Account B"
aws cloudformation delete-stack --stack-name cross-account-role --profile $AccountBProfile --region $region
aws cloudformation wait stack-delete-complete --stack-name cross-account-role --profile $AccountBProfile --region $region
