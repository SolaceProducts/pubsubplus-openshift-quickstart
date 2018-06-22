#!/bin/sh
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#################################################
# Run this script from the ansible-configserver #
#################################################

# The purpose of this script is to cleanup before deleting an AWS OpenShift environment to avoid delete failed or leaking of resources:
#  - Release AWS IAM roles
#  - Release subscriptions

# First check all required env variables have been defined
if [[ -z "$OPENSHIFTSTACK_STACKNAME" || -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "Must provide all following variables in environment. Example (substitute your own parameters!):

export OPENSHIFTSTACK_STACKNAME=XXXXXXXXXXXXXXXXXXXXX
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXX
  " 1>&2
  exit 1
fi
REGION=`curl -s http://instance-data/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//'` # use current region

# Remove AWS IAM policies from ‘Setup Role’ (IAM) used by the RedHat QuickStart to deploy OpenShift to AWS.
echo "Releasing policies from AWS ('Setup') IAM Role"
AWS_IAM_ROLE_NAME=`aws cloudformation describe-stack-resources --region $REGION --stack-name $OPENSHIFTSTACK_STACKNAME --logical-resource-id SetupRole --query StackResources[0].PhysicalResourceId --output text`
if [[ -z "$AWS_IAM_ROLE_NAME" ]]; then
  echo "Couldn't identify the resource ID of the AWS ('Setup') IAM Role. Verify the required env variables are exported and valid:
OPENSHIFTSTACK_STACKNAME, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY" 1>&2
  exit 1
fi
declare -a POLICIES=("AmazonEC2FullAccess" "AWSLambdaFullAccess" "IAMFullAccess" "AmazonS3FullAccess" "AmazonVPCFullAccess" "AWSKeyManagementServicePowerUser" "AmazonRoute53FullAccess")
for policy in "${POLICIES[@]}"
do
  echo "Detaching IAM policy $policy from Role: ${AWS_IAM_ROLE_NAME=}"
  aws iam detach-role-policy --region $REGION --role-name ${AWS_IAM_ROLE_NAME} --policy-arn "arn:aws:iam::aws:policy/$policy"
done
echo

# Unregister subscriptions
echo "Releasing RedHat OpenShift subscriptions"
OPENSHIFT_INSTANCES_LIST=`aws ec2 describe-instances --region $REGION --filters "Name=tag:aws:cloudformation:stack-name,Values=$OPENSHIFTSTACK_STACKNAME" --query Reservations[].Instances[].PrivateIpAddress | awk -F'"' '{print $2}' | paste -sd " " -`
if [[ -z "$OPENSHIFT_INSTANCES_LIST" ]]; then
  echo "Couldn't identify OpenShift instances list. Verify the required env variables are exported and valid:
OPENSHIFTSTACK_STACKNAME, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY" 1>&2
  exit 1
fi
for node in $OPENSHIFT_INSTANCES_LIST
do
  sudo ssh -o StrictHostKeyChecking=no $node bash -c "'
  subscription-manager remove --all;  subscription-manager unregister
  '"
  echo Processed $node
done
echo
echo Cleanup of OpenShift for AWS is complete. You can proceed with deleting the stack in CloudFormation.


