#!/bin/bash
# This script adds an AWS ECR credentials secret to an OpenShift project 
#   1. Configure an OpenShift Secret containing AWS ECR access credentials to allow the VMR project to pull the VMR software
#       from the remote AWS (Elastic Container Registry) Docker repository.
# 
# PREREQUISITES:
# 1. The user has run the 'aws configure' command as root user
# 2. The VMR software (Docker Image) has been deployed in an external publicly accessible Docker Registry (AWS
#      Elastic Container Registry)
#
#  Usage:
#    sudo ./addECRsecret.sh <vmrProjectName>
#
if [ $# -eq 0 ]; then
  echo "Usage: "
  echo " sudo ./addECRsecret.sh <VMR project name>"
fi

PROJECT=$1
TILLER=tiller

function ocLogin() {
  # Log the user into OpenShift if they are not already logged in
  oc whoami &> /dev/null
  if [ $? -ne 0 ]; then
      echo "Not logged into Openshift.  Now logging in."
      oc login
      oc version
  else
      echo "Already logged into OpenShift as `oc whoami`"
  fi
}
ocLogin


# Switch to the VMR project
oc project ${PROJECT} &> /dev/null
if [ $? -ne 0 ]; then
  echo "The project ${PROJECT} does not exist.  Run the prepareProject.sh script to create an OpenShift project for deploying Solace VMR"
fi

# Create an OpenShift Secret to contain the AWS ECR login credentials
#
SECRET_FILE=/root/secret-aws-ecr.yml

echo "Configure access to AWS Elastic Container Registry, Logging into AWS ECR..."
$(aws ecr get-login --no-include-email)

dockerconfigjson_base64=`echo -n "$(cat /root/.docker/config.json)" | base64 | tr -d '\n'`
echo -n \
"---
kind: Secret
apiVersion: v1
metadata:
  name: aws-ecr
data:
  .dockerconfigjson: $dockerconfigjson_base64
type: kubernetes.io/dockerconfigjson
" \
> $SECRET_FILE


# Configure the AWS ECR credentials secret for each required OpenShift service account
#
echo "Configuring AWS ECR credentials for each required service account..."
serviceAccounts=(default deployer builder)

found=$(oc get secrets -n $PROJECT | grep aws-ecr | wc -l)
if [[ $found -eq 0 ]]; then
  oc create -f /root/secret-aws-ecr.yml -n $PROJECT
  for sa in ${serviceAccounts[@]}; do
    oc secrets add serviceaccount/$sa secrets/aws-ecr --for=pull -n $PROJECT
    echo "ECR secret added to service account $sa"
  done
else
  oc replace -f ${SECRET_FILE} -n $PROJECT
fi
