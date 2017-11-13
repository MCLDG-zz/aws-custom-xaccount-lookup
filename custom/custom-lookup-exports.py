"""
This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

"""
    File name: custom-lookup-exports.py
    Author: Michael Edge
    Date created: 11 July 2017
    Python Version: 3.6

    This Lambda is used as a CloudFormation custom resource that will lookup CloudFormation stack
    exports in other accounts. This is useful if a resource in Account A needs to refer to a resource
    in Account B.

    For example, a Lambda in Account A wants to subscribe to an SNS Topic in Account B.
"""

import os
import boto3
import crhelper

# initialise logger
print('Loading function')
logger = crhelper.log_config({"RequestId": "CONTAINER_INIT"})
logger.info('Logging configured')

# set global to track init failures
init_failed = False

try:
    # this Lambda will query CloudFormation stacks in other accounts, so we need a cross account connection.
    # A cross-account role ARN is passed in CUSTOM_CROSS_ACCOUNT_ROLE_ARN, which contains the role ARN to
    # be assumed. This Lambda could change to query CloudFormation stacks in many accounts by looping
    # through the ARNs in CUSTOM_CROSS_ACCOUNT_ROLE_ARN and appending to the list of stack exports.
    print('assuming role in different account. Role ARN is: ' + os.environ['CUSTOM_CROSS_ACCOUNT_ROLE_ARN'])

    sts = boto3.client('sts')
    assumedRole = sts.assume_role(
        RoleArn=os.environ['CUSTOM_CROSS_ACCOUNT_ROLE_ARN'],
        RoleSessionName='LambdaCloudFormationSession'
    )
    print('assumed role ' + str(assumedRole))
    credentials = assumedRole['Credentials']
    accessKey = credentials['AccessKeyId']
    secretAccessKey = credentials['SecretAccessKey']
    sessionToken = credentials['SessionToken']
    print('establishing session in different account. Region is: ' + os.environ['AWS_DEFAULT_REGION'] + os.environ['AWS_REGION'] + ' accessKey is: ' + accessKey)

    cfn = boto3.client('cloudformation', region_name=os.environ['AWS_DEFAULT_REGION'], aws_access_key_id=accessKey,
                                 aws_secret_access_key=secretAccessKey, aws_session_token=sessionToken)
    print("initialization completed")
except Exception as e:
    logger.error(e, exc_info=True)
    init_failed = e


def create(event, context):
    response_data = get_exports()
    physical_resource_id = 'customResourceId'
    return physical_resource_id, response_data


def update(event, context):
    response_data = get_exports()
    physical_resource_id = event['PhysicalResourceId']
    return physical_resource_id, response_data


def delete(event, context):
    return


def get_exports():
    print('getting stack exports')
    stackexports=[]

    response = cfn.list_exports()
    stackexports.extend(response['Exports'])
    while 'NextToken' in response and response['NextToken'] is not None:
        token = response['NextToken']
        response = cfn.list_exports(NextToken=token)
        stackexports.extend(response['Exports'])
    print('list of stack exports: ' + str(stackexports))

    #create dict of stack exports
    stackexportvalues = {}
    for stackexport in stackexports:
        stackexportvalues[stackexport['Name']] = stackexport['Value']
    print('list of stack exports in dict: ' + str(stackexportvalues))

    return stackexportvalues


def handler(event, context):
    global logger
    print('CloudFormation event received: %s' % str(event))

    return crhelper.cfn_handler(event, context, create, update, delete, logger, init_failed)

