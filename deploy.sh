#!/bin/bash
# This script will automate the steps outlined in the readme.md file to deploy the template in solace-vmr-template.vmr
#
# REQUIREMENTS:
# 1. You need to have a private key in working directory in 'id_rsa' which gives access to the master node of your
#    Openshift deployment.  The script requires it to enable some SCCs on the project's service account.  This is temporary until the
#    VMR shared memory requirements are removed in a future version of the VMR.
# 2. You need to place the VMR Docker image .tar.gz file in the working directory.  The script will be loading it in the
#    local docker registry if it is missing.  You can also load the image yourself, and the script won't be looking for
#    image.  This image can be downloaded from http://dev.solace.com/downloads .
#
# ./deploy.sh <master-sshHost> <projectName> <domain>
# master-sshHost: The master node's SSH host string.  Must be like this : <username>@<host>.  The user must have admin
#                 access to the oadm command line tool.  A ssh private key must be located in the working directory in
#                 `id_rsa`.
# projectName: The name you want to give to the project to be deployed by this script
# domain: The domain name of the Openshift installation.  IE. openshift.example.com

SSH_HOST=$1
PROJECT_NAME=$2
DOMAIN=$3

# Have the user login if not already logged in
oc whoami &> /dev/null
if [ $? -ne 0 ]; then
    echo "Not logged to Openshift.  Now logging in."
    oc login
else
    echo "Already logged in as `oc whoami`"
fi

oc project &> /dev/null
if [ $? -ne 0 ]; then
    echo "Creating new Openshift project : $PROJECT_NAME"
    oc new-project $PROJECT_NAME
else
    echo "Project $PROJECT_NAME already exists.  Skipping its creation."
fi

echo "Assigning these SCCs: privileged and anyuid to project's service account."
ssh -i id_rsa $SSH_HOST "oadm policy add-scc-to-user privileged system:serviceaccount:$PROJECT_NAME:default"
ssh -i id_rsa $SSH_HOST "oadm policy add-scc-to-user anyuid system:serviceaccount:$PROJECT_NAME:default"

if [ -z "`docker images solace-app -q`" ]; then
  echo "Pushing docker image in `ls soltr-*-docker.tar.gz` to Openshift's Docker repository"
  docker load -i `ls soltr-*-docker.tar.gz`
fi
docker login --username=`oc whoami` --password=`oc whoami -t` docker-registry-default.$DOMAIN
docker tag `docker images -q solace-app` docker-registry-default.$DOMAIN/$PROJECT_NAME/solace-app:latest
docker push docker-registry-default.$DOMAIN/$PROJECT_NAME/solace-app

echo "Adding the Solace VMR template to the Openshift project"
oc create -f solace-vmr-template.yml

echo "Instantiating the Solace VMR template."
oc process solace-vmr-template VMR_IMAGE=`oc get imagestream solace-app -o jsonpath="{.status.dockerImageRepository}"` APPLICATION_SUBDOMAIN=$DOMAIN | oc create -f -
