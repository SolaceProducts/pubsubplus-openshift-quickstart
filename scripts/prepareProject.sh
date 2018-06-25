#!/bin/bash
# This script performs several operations necessary to prepare an OpenShift project for deploying
#   the VMR HA software using a Helm Chart.   The following steps are necessary:
#   1. Grant the necessary privileges to the Helm Tiller project so that the Tiller project may deploy the necessary components
#       of the VMR HA software in its own project
#   2. Grant the necessary OpenShift privileges to the VMR HA project as required for the correct operation of the VMR HA software
# 
# PREREQUISITES:
# 1. If used, Helm client and server-side components (Tiller) have been already deployed in the OpenShift environment
#
#  Usage:
#    sudo ./prepareProject.sh <vmrProjectName>
#
if [ $# -eq 0 ]; then
  echo "Usage: "
  echo " . ./prepareProject.sh <VMR project name>"
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


# Grant the admin user privileges to inspect OpenShift resources
echo "Adding policies to service accounts for working with OpenShift projects..."
oadm policy add-cluster-role-to-user cluster-admin admin
oadm policy add-cluster-role-to-user cluster-admin system::admin
oadm policy add-cluster-role-to-user cluster-admin system:controller:service-controller

# Create VMR HA project
oc project ${PROJECT} &> /dev/null
if [ $? -ne 0 ]; then
  oc new-project ${PROJECT}
else
  echo "Skipping project creation, project ${PROJECT} already exists..."
fi

# If deployed, grant the Tiller project the required access to deploy VMR HA project components
if [[ "`oc get projects | grep tiller`" ]]; then
  echo "Granting the Tiller project access to the VMR HA project..."
  oc policy add-role-to-user edit system:serviceaccount:$TILLER:tiller
  oadm policy add-cluster-role-to-user storage-admin system:serviceaccount:$TILLER:tiller
  oadm policy add-cluster-role-to-user cluster-admin system:serviceaccount:$TILLER:tiller
fi

# Configure the required OpenShift Policies and SCC privileges for the operation of the VMR HA software
echo "Granting the VMR HA project policies and SCC privileges for correct operation..."
oc policy add-role-to-user edit system:serviceaccount:$PROJECT:default
oadm policy add-cluster-role-to-user cluster-admin system:serviceaccount:$PROJECT:default
oadm policy add-scc-to-user privileged system:serviceaccount:$PROJECT:default
oadm policy add-scc-to-user anyuid system:serviceaccount:$PROJECT:default

