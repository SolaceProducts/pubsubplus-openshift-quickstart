#!/bin/bash
# This script will automate the steps to deploy the Helm client and server-side components
#   NOTE: Helm is a templating engine which can be used to generate OpenShift template files and execute
#    the template on the OpenShift server.
#
# REQUIREMENTS:
# 1. The Helm client and server-side components must be deployed in your OpenShift environment 
#       in order to use the Solace 'helm' (Chart) templates
# 2. The Tiller project must be granted sufficient privileges to execute the specified OpenShift template(s).
#
#  Usage:
#    . ./deployHelm.sh client
#    . ./deployHelm.sh server
#
TILLER_PROJECT=tiller
HELM_VERSION=2.7.2

function helmVersion() {
  which helm &> /dev/null  
  if [ $? -ne 0 ]; then
    echo "The helm client tool executable is not in your search path"
    echo "export PATH=\$PATH:\$HOME/linux-amd64"
  else 
    helm version
    if [ $? -ne 0 ]; then
      echo "There was a problem retrieving helm details.  Ensure you have the following environment variables defined:"
      echo "  HELM_HOME=\${HOME}/.helm"
      echo "  TILLER_NAMESPACE=${TILLER_PROJECT}"
    fi
  fi
}

function ocLogin() {
  # Log the user into OpenShift if they are not already logged in
  oc whoami &> /dev/null
  if [ $? -ne 0 ]; then
      echo "Not logged into Openshift.  Now logging in."
      oc login
  else
      echo "Already logged into OpenShift as `oc whoami`"
  fi
}

function deployHelmClient () {
  # Deploy Helm client
  which helm &> /dev/null
  if [ $? -ne 0 ]; then
    cd $HOME
    curl -s "https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar xz
    $HOME/linux-amd64/helm init --client-only
  
    echo "export PATH=\$PATH:\$HOME/linux-amd64"
    export PATH=$PATH:~/linux-amd64

    echo "export HELM_HOME=\$HOME/.helm"
    export HELM_HOME=$HOME/.helm

    echo "export TILLER_NAMESPACE=${TILLER_PROJECT}"
    export TILLER_NAMESPACE=$TILLER_PROJECT
  else
    echo "Skipping Helm client installation, Helm is already installed"
    echo "  helm executable found in --> $(which helm)"
  fi
}

function deployHelmServer() {
  # Deploy Helm / Tiller Server
  ocLogin

  oc project $TILLER_PROJECT &> /dev/null
  if [ $? -ne 0 ]; then
      echo "Deploying Helm Tiller to project name: $TILLER_PROJECT"

      echo "export HELM_HOME=\$HOME/.helm"
      export HELM_HOME=$HOME/.helm

      echo "export TILLER_NAMESPACE=${TILLER_PROJECT}"
      export TILLER_NAMESPACE=$TILLER_PROJECT
 
      oc new-project $TILLER_PROJECT
      oc process -f templates/deployHelmServer.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" | oc create -f -
      oc rollout status deployment $TILLER_PROJECT
      echo "Waiting for Tiller pod to complete deployment"
      sleep 10 ; # Allow some time for Tiller server to complete deployment
      helmVersion
  else
      echo "Helm ${TILLER_PROJECT} project already exists.  Skipping its creation."
      oc describe project ${TILLER_PROJECT}
      helmVersion
  fi
}

if [ "$1" == "client" ]; then
  deployHelmClient
elif [ "$1" == "server" ]; then
  deployHelmServer
else
  echo "Usage: "
  echo " . ./deployHelm.sh [client | server]"
fi
