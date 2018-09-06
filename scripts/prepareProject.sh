#!/bin/bash
# This script preapres an OpenShift project for deploying
#   the Solace message broker software. The following steps are necessary:
#   1. If using Helm (Tiller project detected) grant the necessary privileges to the Helm Tiller project so that the Tiller project
#      may deploy the necessary components of the Solace message broker software in its own project
#   2. Grant the necessary OpenShift privileges to the project hosting the Solace message broker as required
# 
# PREREQUISITES:
# 1. If used, Helm client and server-side components (Tiller) have been already deployed in the OpenShift environment
#
#  Usage:
#    sudo ./prepareProject.sh <projectName>
#
if [ $# -eq 0 ]; then
  echo "Usage: "
  echo "./prepareProject.sh <projectName>"
  exit 1
fi

PROJECT=$1
TILLER=tiller

function ocLogin() {
  # Log in as system:admin into OpenShift if not already logged in. This script requires a user with cluster-admin role
  oc whoami &> /dev/null
  if [ $? -ne 0 ]; then
      echo "Not logged into Openshift.  Now logging in."
      oc login -u system:admin -n default
      oc version
  else
      echo "Already logged into OpenShift as `oc whoami`"
  fi
}
ocLogin


# Create project
oc project ${PROJECT} &> /dev/null
if [ $? -ne 0 ]; then
  oc new-project ${PROJECT}
  oc policy add-role-to-user admin admin -n ${PROJECT}
else
  echo "Skipping project creation, project ${PROJECT} already exists..."
fi

# If deployed, grant the Tiller project the required access to deploy the Solace message router components
if [[ "`oc get projects | grep tiller`" ]]; then
  echo "Tiller project detected, adding access to the ${1} project..."
  oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:$TILLER:tiller
  echo
fi

# Configure the required OpenShift Policies and SCC privileges for the operation of the Solace message router software
echo "Granting the ${1} project policies and SCC privileges for correct operation..."
oc policy add-role-to-user edit system:serviceaccount:$PROJECT:default
oc adm policy add-scc-to-user privileged system:serviceaccount:$PROJECT:default
oc adm policy add-scc-to-user anyuid system:serviceaccount:$PROJECT:default


