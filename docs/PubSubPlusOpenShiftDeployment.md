# Deploying a Solace PubSub+ Software Event Broker onto an OpenShift 4.6 platform

This is detailed documentation of deploying Solace PubSub+ Software Event Broker onto an OpenShift 4.6 platform including steps to set up a Red Hat OpenShift Container Platform platform on AWS.
* For a hands-on quick start using an existing OpenShift platform, refer to the [Quick Start guide](/README.md).
* For considerations about deploying in a general Kubernetes environment, refer to the [Solace PubSub+ on Kubernetes Documentation](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md)
* For the `pubsubplus` Helm chart configuration options, refer to the [PubSub+ Software Event Broker Helm Chart Reference](/pubsubplus/README.md).



Contents:
  * [Purpose of this Repository](#purpose-of-this-repository)
  * [Description of the Solace PubSub+ Software Event Broker](#description-of-solace-pubsub-software-event-broker)
  * [Production Deployment Architecture](#production-deployment-architecture)
  * [Deployment Options](#deployment-options)
  * [How to deploy Solace PubSub+ onto OpenShift / AWS](#how-to-deploy-solace-pubsub-onto-openshift--aws)
    + [Step 1: (Optional / AWS) Deploy OpenShift Container Platform onto AWS using the RedHat OpenShift AWS QuickStart Project](#step-1-optional--aws-deploy-openshift-container-platform-onto-aws-using-the-redhat-openshift-aws-quickstart-project)
    + [Step 2: Prepare your workspace](#step-2-prepare-your-workspace)
    + [Step 3: (Optional: only execute for Deployment option 1) Install the Helm v2 client and server-side tools](#step-3-optional-only-execute-for-deployment-option-1-install-the-helm-v2-client-and-server-side-tools)
    + [Step 4: Create a new OpenShift project to host the event broker deployment](#step-4-create-a-new-openshift-project-to-host-the-event-broker-deployment)
    + [Step 5: Optional: Load the event broker (Docker image) to your Docker Registry](#step-5-optional-load-the-event-broker-docker-image-to-your-docker-registry)
    + [Step 6-Option 1: Deploy the event broker using Helm](#step-6-option-1-deploy-the-event-broker-using-helm)
    + [Step 6-Option 2: Deploy the event broker using the OpenShift templates included in this project](#step-6-option-2-deploy-the-event-broker-using-the-openshift-templates-included-in-this-project)
  * [Validating the Deployment](#validating-the-deployment)
    + [Viewing Bringup Logs](#viewing-bringup-logs)
  * [Gaining Admin and SSH access to the event broker](#gaining-admin-and-ssh-access-to-the-event-broker)
  * [Testing data access to the event broker](#testing-data-access-to-the-event-broker)
  * [Deleting a deployment](#deleting-a-deployment)
    + [Deleting the PubSub+ deployment](#deleting-the-pubsub-deployment)
    + [Deleting the AWS OpenShift Container Platform deployment](#deleting-the-aws-openshift-container-platform-deployment)
  * [Special topics](#special-topics)
    + [Using NFS for persistent storage](#using-nfs-for-persistent-storage)
  * [Resources](#resources)


## Purpose of this Repository

This repository provides an example of how to deploy the Solace PubSub+ Software Event Broker onto an OpenShift 4.6 platform. There are [multiple ways](https://docs.openshift.com/index.html ) to get to an OpenShift platform, including [Code Ready Containers](https://developers.redhat.com/products/codeready-containers/overview). The easiest way to get an OpenShift cluster up and running is through the [Developer Sandbox](https://developers.redhat.com/developer-sandbox) program. You can sign up for a free 14 days trial. This guide will specifically use the Red Hat OpenShift Container Platform for deploying an HA group but concepts are transferable to other compatible platforms. 

The supported Solace PubSub+ Software Event Broker version is 9.4 or later.

For the Red Hat OpenShift Container Platform, we utilize the [RedHat OpenShift on AWS QuickStart](https://docs.openshift.com/container-platform/4.6/installing/installing_aws/installing-aws-default.html) project to deploy a Red Hat OpenShift Container Platform on AWS in a highly redundant configuration, spanning 3 zones.

This repository expands on the [Solace Kubernetes Quickstart](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/README.md ) to provide an example of how to deploy Solace PubSub+ in an HA configuration on the OpenShift Container Platform running in AWS.

The event broker deployment does not require any special OpenShift Security Context, the [default "restricted" SCC](//docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html) can be used.

## Description of Solace PubSub+ Software Event Broker 

Solace PubSub+ Software Event Broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The event broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. As well, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## Production Deployment Architecture

The following diagram shows an example HA deployment in AWS:
![alt text](/docs/images/network_diagram.jpg "Network Diagram")

<br/>
Key parts are the three PubSub+ Container instances in OpenShift pods, deployed on OpenShift (worker) nodes; the cloud load balancer exposing the event router's services and management interface; the OpenShift master nodes(s); and the Ansible Config Server, which acts as a bastion host for external ssh access.

## How to deploy Solace PubSub+ onto OpenShift / AWS

The following steps describe how to deploy an event broker onto an OpenShift environment. Optional steps are provided about setting up a Red Hat OpenShift Container Platform on Amazon AWS infrastructure (marked as Optional / AWS) and if you use AWS Elastic Container Registry to host the Solace PubSub+ Docker image (marked as Optional / ECR).

**Hint:** You may skip Step 1 if you already have your own OpenShift environment available.

### Step 1: (Optional / AWS) Deploy OpenShift Container Platform onto AWS using the RedHat OpenShift AWS QuickStart Project

* (Part I) Log into the AWS Web Console and run the [OpenShift AWS QuickStart project](https://aws.amazon.com/quickstart/architecture/openshift/ ), which will use AWS CloudFormation for the deployment.  We recommend you deploy OpenShift across 3 AWS Availability Zones for maximum redundancy.  Please refer to the RedHat OpenShift AWS QuickStart guide and supporting documentation:

  * [Installing a cluster quickly on AWS](https://docs.openshift.com/container-platform/4.6/installing/installing_aws/installing-aws-default.html)
  
  **Important:** As described in above documentation, this deployment requires a Red Hat account with a valid Red Hat subscription to OpenShift and will consume 10 OpenShift entitlements in a maximum redundancy configuration. When no longer needed ensure to follow the steps in the [Deleting the OpenShift Container Platform deployment](#deleting-the-openshift-container-platform-deployment ) section of this guide to free up the entitlements.

  This deployment will create 10 EC2 instances: an *ansible-configserver* and three of each *openshift-etcd*, *openshift-master* and *openshift-nodes* servers. <br>
  
  **Note:** only the "*ansible-configserver*" is exposed externally in a public subnet. To access the other servers that are in a private subnet, first [SSH into](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html ) the *ansible-configserver* instance then use that instance as a bastion host to SSH into the target server using it's private IP. For that we recommend enabling [SSH agent forwarding](https://developer.github.com/v3/guides/using-ssh-agent-forwarding/ ) on your local machine to avoid the insecure option of copying and storing private keys remotely on the *ansible-configserver*.

### Step 2: Prepare your workspace

**Important:** This and subsequent steps shall be executed on a host having the OpenShift client tools and able to reach your OpenShift cluster nodes - conveniently, this can be one of the *openshift-master* servers.

> If using Code Ready Containers or Developer Sandbox, continue using your terminal.

* SSH into your selected host and ensure you are logged in to OpenShift. If you used Step 1 to deploy OpenShift, the requested server URL is the same as the OpenShift console URL, the username is `admin` and the password is as specified in the CloudFormation template. Otherwise use the values specific to your environment.

```
## On an openshift-master server
oc whoami  
# if not logged in yet
oc login   
```

* The Solace OpenShift QuickStart project contains useful scripts to help you prepare an OpenShift project for event broker deployment. Retrieve the project in your selected host:

```
mkdir ~/workspace
cd ~/workspace
git clone https://github.com/SolaceProducts/pubsubplus-openshift-quickstart.git
cd pubsubplus-openshift-quickstart
```

### Step 3: Install the Helm client and server-side tools

This will deploy Helm in a dedicated "tiller-project" project. Do not use this project for your deployments.

- First download the Helm client. Follow the instructions from the [Helm website](https://helm.sh/docs/intro/install/) to get the CLI for your operating system.

- Use script to install the Helm v2 client and its Tiller server-side operator.
```bash
  # Setup local Helm client
  helm init --client-only
  # Install Tiller server-side operator into a new "tiller-project"
  oc new-project tiller-project
  oc process -f https://github.com/openshift/origin/raw/master/examples/helm/tiller-template.yaml -p TILLER_NAMESPACE="tiller-project" -p HELM_VERSION=v2.16.0 | oc create -f -
  oc rollout status deployment tiller
  # also let Helm know where Tiller was deployed
  export TILLER_NAMESPACE=tiller-project
```

### Step 4: Create a new OpenShift project to host the event broker deployment

This will create a new project for deployments if needed or you can use your existing project except "helm" (the "helm" project has special privileges assigned which shall not be used for deployments).
```
oc new-project solace-pubsub    # adjust your project name as needed here and in subsequent commands
```

### Step 5: Optional: Load the event broker (Docker image) to your Docker Registry

Deployment scripts will pull the Solace PubSub+ image from a [Docker registry](https://docs.Docker.com/registry/ ). There are several [options which registry to use](https://docs.openshift.com/container-platform/4.6/registry/architecture-component-imageregistry.html) depending on the requirements of your project, see some examples in (Part II) of this step.

**Hint:** You may skip the rest of this step if using the free PubSub+ Standard Edition available from the [Solace public Docker Hub registry](https://hub.Docker.com/r/solace/solace-pubsub-standard/tags/ ). The Docker Registry URL to use will be `solace/solace-pubsub-standard:<TagName>`.

* **(Part I)** Download a copy of the event broker Docker image.

  Go to the Solace Developer Portal and download the Solace PubSub+ as a **Docker** image or obtain your version from Solace Support.

     * If using Solace PubSub+ Enterprise Evaluation Edition, go to the Solace Downloads page. For the image reference, copy and use the download URL in the Solace PubSub+ Enterprise Evaluation Edition Docker Images section.

         | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
         | :---: |
         | 90-day trial version of PubSub+ Enterprise |
         | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |


* **(Part II)** Deploy the event broker Docker image to your Docker registry of choice

  Options include:

  * You can choose to use [OpenShift's Docker registry.](https://docs.openshift.com/container-platform/3.10/install_config/registry/deploy_registry_existing_clusters.html ). 

  * **(Optional / ECR)** You can utilize the AWS Elastic Container Registry (ECR) to host the event broker Docker image. For more information, refer to [Amazon Elastic Container Registry](https://aws.amazon.com/ecr/ ). If you are using ECR as your Docker registry then you must add the ECR login credentials (as an OpenShift secret) to your event broker HA deployment.  This project contains a helper script to execute this step:

```shell
    # Required if using ECR for Docker registry
    # Ensure to use aws cli v1, any sub version
    cd ~/workspace/pubsubplus-openshift-quickstart/scripts
    sudo su
    aws configure       # provide AWS config for root; provide your key ID, key and region.
    ./addECRsecret.sh solace-pubsub   # adjust your project name as needed
```

  Here is an outline of the additional steps required if loading an image to ECR:
  
  * Copy the Solace Docker image location and download the image archive locally using the `wget <url>` command.
  * Load the downloaded image to the local docker image repo using the `docker load -i <archive>` command
  * Go to your target ECR repository in the [AWS ECR Repositories console](https://console.aws.amazon.com/ecr ) and get the push commands information by clicking on the "View push commands" button.
  * Start from the `docker tag` command to tag the image you just loaded. Use `docker images` to find the  Solace Docker image just loaded. You may need to use 
  * Finally, use the `docker push` command to push the image.
  * Exit from superuser to normal user

![alt text](/docs/images/ECR-Registry.png "ECR Registry")

<br>

For general additional information, refer to the [Using private registries](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#using-private-registries) section in the general Event Broker in Kubernetes Documentation.

### Step 6: Deploy the event broker using Helm

Deploying using Helm provides more flexibility in terms of event broker deployment options, compared to those offered by the OpenShift templates provided by this project.

More information is provided in the following documents:
* [Solace PubSub+ on Kubernetes Deployment Guide](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md)
* [Kubernetes Deployment Quick Start Guide](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/README.md)

The deployment is using PubSub+ Software Event Broker Helm charts and customized by overriding [default chart parameters](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/tree/master/pubsubplus#configuration).

Consult the [Deployment Considerations](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#pubsub-event-broker-deployment-considerations) section of the general Event Broker in Kubernetes Documentation when planning your deployment.

In particular, the `securityContext.enabled` parameter must be set to `false`, indicating not to use the provided pod security context but let OpenShift set it, using SecurityContextConstraints (SCC). By default OpenShift will use the "restricted" SCC.

By default the publicly available [latest Docker image of PubSub+ Standard Edition](https://hub.Docker.com/r/solace/solace-pubsub-standard/tags/) will be used. [Load a different image into a registry](#step-5-optional-load-the-event-broker-docker-image-to-your-docker-registry) if required. If using a different image, add the `image.repository=<your-image-location>,image.tag=<your-image-tag>` values to the `--set` commands below, comma-separated.

Solace PubSub+ can be vertically scaled by deploying in one of the [client connection scaling tiers](//docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/Scaling-Tier-Resources.htm), controlled by the `solace.size` chart parameter.

Next an HA and a non-HA deployment examples are provided, using default parameters. For configuration options, refer to the [Solace PubSub+ Advanced Event Broker Helm Chart](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/tree/master/pubsubplus) reference.
After initiating a deployment with one of the commands below skip to the [Validating the Deployment](#validating-the-deployment) section.

> Ensure each command-line session has the TILLER_NAMESPACE environment variable properly set!

HA deployment example:

```bash
# One-time action: Add the PubSub+ charts to local Helm
helm repo add solacecharts https://solaceproducts.github.io/pubsubplus-kubernetes-quickstart/helm-charts
# Initiate the HA deployment
helm install --name my-ha-release \
  --set securityContext.enabled=false,solace.redundancy=true,solace.usernameAdminPassword=<EVENTBROKER_ADMIN_PASSWORD> \
  solacecharts/pubsubplus
# Check the notes printed on screen
# Wait until all pods running and ready and the active event broker pod label is "active=true" 
oc get pods --show-labels -w
```

Single-node, non-HA deployment example:

```bash
# One-time action: Add the PubSub+ charts to local Helm
helm repo add solacecharts https://solaceproducts.github.io/pubsubplus-kubernetes-quickstart/helm-charts
# Initiate the non-HA deployment
helm install --name my-nonha-release \
  --set securityContext.enabled=false,solace.redundancy=true,solace.usernameAdminPassword=<EVENTBROKER_ADMIN_PASSWORD> \
  solacecharts/pubsubplus
# Check the notes printed on screen
# Wait until the event broker pod is running, ready and the pod label is "active=true" 
oc get pods --show-labels -w
```

Note: an alternative to longer `--set` parameters is to define same parameter values in a YAML file:
```yaml
# Create example values file
echo "
securityContext
  enabled: false
solace
  redundancy: true,
  usernameAdminPassword: <EVENTBROKER_ADMIN_PASSWORD>" > deployment-values.yaml
# Use values file
helm install --name my-release \
  -v deployment-values.yaml \
  solacecharts/pubsubplus
```
  
## Validating the Deployment

If there are any issues with the deployment, refer to the [Kubernetes Troubleshooting Guide](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#troubleshooting) - substitute any `kubectl` commands with `oc` commands. Before retrying a deployment, ensure to delete PVCs remaining from the unsuccessful deployment - use `oc get pvc` to determine which ones.

Now you can validate your deployment from the OpenShift client shell:

```
[ec2-user@ip-10-0-23-198 ~]$ oc get statefulset,service,pods,pvc,pv --show-labels
NAME                                     DESIRED   CURRENT   AGE       LABELS
statefulset.apps/my-release-pubsubplus   3         3         2h        app.kubernetes.io/instance=my-release,app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/name=pubsubplus,helm.sh/chart=pubsubplus-1.0.0

NAME                                      TYPE           CLUSTER-IP     EXTERNAL-IP                                                                PORT(S)                                                                                                                                                             AGE       LABELS
service/my-release-pubsubplus             LoadBalancer   172.30.44.13   a7d53a67e0d3911eaab100663456a67b-73396344.eu-central-1.elb.amazonaws.com   22:32084/TCP,8080:31060/TCP,943:30321/TCP,55555:32434/TCP,55003:32160/TCP,55443:30635/TCP,80:30142/TCP,443:30411/TCP,5672:30595/TCP,1883:30511/TCP,9000:32277/TCP   2h        app.kubernetes.io/instance=my-release,app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/name=pubsubplus,helm.sh/chart=pubsubplus-1.0.0
service/my-release-pubsubplus-discovery   ClusterIP      None           <none>                                                                     8080/TCP,8741/TCP,8300/TCP,8301/TCP,8302/TCP                                                                                                                        2h        app.kubernetes.io/instance=my-release,app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/name=pubsubplus,helm.sh/chart=pubsubplus-1.0.0

NAME                          READY     STATUS    RESTARTS   AGE       LABELS
pod/my-release-pubsubplus-0   1/1       Running   0          2h        active=true,app.kubernetes.io/instance=my-release,app.kubernetes.io/name=pubsubplus,controller-revision-hash=my-release-pubsubplus-7b788f768b,statefulset.kubernetes.io/pod-name=my-release-pubsubplus-0
pod/my-release-pubsubplus-1   1/1       Running   0          2h        active=false,app.kubernetes.io/instance=my-release,app.kubernetes.io/name=pubsubplus,controller-revision-hash=my-release-pubsubplus-7b788f768b,statefulset.kubernetes.io/pod-name=my-release-pubsubplus-1
pod/my-release-pubsubplus-2   1/1       Running   0          2h        app.kubernetes.io/instance=my-release,app.kubernetes.io/name=pubsubplus,controller-revision-hash=my-release-pubsubplus-7b788f768b,statefulset.kubernetes.io/pod-name=my-release-pubsubplus-2

NAME                                                 STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE       LABELS
persistentvolumeclaim/data-my-release-pubsubplus-0   Bound     pvc-7d596ac0-0d39-11ea-ab10-0663456a67be   30Gi       RWO            gp2            2h        app.kubernetes.io/instance=my-release,app.kubernetes.io/name=pubsubplus
persistentvolumeclaim/data-my-release-pubsubplus-1   Bound     pvc-7d5c60e9-0d39-11ea-ab10-0663456a67be   30Gi       RWO            gp2            2h        app.kubernetes.io/instance=my-release,app.kubernetes.io/name=pubsubplus
persistentvolumeclaim/data-my-release-pubsubplus-2   Bound     pvc-7d5f8838-0d39-11ea-ab10-0663456a67be   30Gi       RWO            gp2            2h        app.kubernetes.io/instance=my-release,app.kubernetes.io/name=pubsubplus

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                                 STORAGECLASS   REASON    AGE       LABELS
persistentvolume/pvc-58223d93-0b93-11ea-833a-0246f4c5a982   10Gi       RWO            Delete           Bound     openshift-infra/metrics-cassandra-1   gp2                      2d        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1c
persistentvolume/pvc-7d596ac0-0d39-11ea-ab10-0663456a67be   30Gi       RWO            Delete           Bound     solace-pubsub/data-my-release-pubsubplus-0    gp2                      2h        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1c
persistentvolume/pvc-7d5c60e9-0d39-11ea-ab10-0663456a67be   30Gi       RWO            Delete           Bound     solace-pubsub/data-my-release-pubsubplus-1    gp2                      2h        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1a
persistentvolume/pvc-7d5f8838-0d39-11ea-ab10-0663456a67be   30Gi       RWO            Delete           Bound     solace-pubsub/data-my-release-pubsubplus-2    gp2                      2h        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1b
[ec2-user@ip-10-0-23-198 ~]$
[ec2-user@ip-10-0-23-198 ~]$
[ec2-user@ip-10-0-23-198 ~]$ oc describe svc
Name:                     my-release-pubsubplus
Namespace:                solace-pubsub
Labels:                   app.kubernetes.io/instance=my-release
                          app.kubernetes.io/managed-by=Tiller
                          app.kubernetes.io/name=pubsubplus
                          helm.sh/chart=pubsubplus-1.0.0
Annotations:              <none>
Selector:                 active=true,app.kubernetes.io/instance=my-release,app.kubernetes.io/name=pubsubplus
Type:                     LoadBalancer
IP:                       172.30.44.13
LoadBalancer Ingress:     a7d53a67e0d3911eaab100663456a67b-73396344.eu-central-1.elb.amazonaws.com
Port:                     ssh  22/TCP
TargetPort:               2222/TCP
NodePort:                 ssh  32084/TCP
Endpoints:                10.131.0.17:2222
Port:                     semp  8080/TCP
TargetPort:               8080/TCP
NodePort:                 semp  31060/TCP
Endpoints:                10.131.0.17:8080
Port:                     semptls  943/TCP
TargetPort:               60943/TCP
NodePort:                 semptls  30321/TCP
Endpoints:                10.131.0.17:60943
Port:                     smf  55555/TCP
TargetPort:               55555/TCP
NodePort:                 smf  32434/TCP
Endpoints:                10.131.0.17:55555
Port:                     smfcomp  55003/TCP
TargetPort:               55003/TCP
NodePort:                 smfcomp  32160/TCP
Endpoints:                10.131.0.17:55003
Port:                     smftls  55443/TCP
TargetPort:               55443/TCP
NodePort:                 smftls  30635/TCP
Endpoints:                10.131.0.17:55443
Port:                     web  80/TCP
TargetPort:               60080/TCP
NodePort:                 web  30142/TCP
Endpoints:                10.131.0.17:60080
Port:                     webtls  443/TCP
TargetPort:               60443/TCP
NodePort:                 webtls  30411/TCP
Endpoints:                10.131.0.17:60443
Port:                     amqp  5672/TCP
TargetPort:               5672/TCP
NodePort:                 amqp  30595/TCP
Endpoints:                10.131.0.17:5672
Port:                     mqtt  1883/TCP
TargetPort:               1883/TCP
NodePort:                 mqtt  30511/TCP
Endpoints:                10.131.0.17:1883
Port:                     rest  9000/TCP
TargetPort:               9000/TCP
NodePort:                 rest  32277/TCP
Endpoints:                10.131.0.17:9000
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

Find the **'LoadBalancer Ingress'** value listed in the service description above.  This is the publicly accessible Solace Connection URI for messaging clients and management. In the example it is `a7d53a67e0d3911eaab100663456a67b-73396344.eu-central-1.elb.amazonaws.com`.

### Viewing Bringup logs

To see the deployment events, navigate to:

* **OpenShift UI > (Your Project) > Search > Stateful Sets > ((name)-pubsubplus) > Events**

You can access the log stack for individual event broker pods from the OpenShift UI, by navigating to:

* **OpenShift UI > (Your Project) > Search > Stateful Sets > ((name)-pubsubplus) > Pods > ((name)-solace-(N)) > Logs**

![alt text](/docs/images/Solace-Pod-Log-Stack.png "Event Broker Pod Log Stack")

Where (N) above is the ordinal of the Solace PubSub+:
  * 0 - Primary event broker
  * 1 - Backup event broker
  * 2 - Monitor event broker

## Gaining Admin and SSH access to the event broker

The external management host URI will be the Solace Connection URI associated with the load balancer generated by the event broker OpenShift template.  Access will go through the load balancer service as described in the introduction and will always point to the active event broker. The default port is 22 for CLI and 8080 for SEMP/SolAdmin.

If you deployed OpenShift in AWS, then the Solace OpenShift QuickStart will have created an EC2 Load Balancer to front the event broker / OpenShift service.  The Load Balancer public DNS name can be found in the AWS EC2 console under the 'Load Balancers' section.

To launch Solace CLI or SSH into the individual event broker instances from the OpenShift CLI use:

```
# CLI access
oc exec -it XXX-XXX-pubsubplus-X cli   # adjust pod name to your deployment
# shell access
oc exec -it XXX-XXX-pubsubplus-X bash  # adjust pod name to your deployment
```

You can also gain access to the Solace CLI and container shell for individual event broker instances from the OpenShift UI.  A web-based terminal emulator is available from the OpenShift UI.  Navigate to an individual event broker Pod using the OpenShift UI:

* **OpenShift UI > (Your Project) > Search > Stateful Sets > ((name)-pubsubplus) > Pods > ((name)-pubsubplus-(N)) > Terminal**

Once you have launched the terminal emulator to the event broker pod you may access the Solace CLI by executing the following command:

```
/usr/sw/loads/currentload/bin/cli -A
```

![alt text](/docs/images/Solace-Primary-Pod-Terminal-CLI.png "Event Broker CLI via OpenShift UI Terminal emulator")

See the [Solace Kubernetes Quickstart README](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#gaining-admin-access-to-the-event-broker ) for more details including admin and SSH access to the individual event brokers.

## Testing data access to the event broker

To test data traffic though the newly created event broker instance, visit the Solace Developer Portal and select your preferred programming language to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/ ). Under each language there is a Publish/Subscribe tutorial that will help you get started.

Note: the Host will be the Solace Connection URI. It may be necessary to [open up external access to a port](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#modifying-or-upgrading-a-deployment ) used by the particular messaging API if it is not already exposed.

![alt text](/docs/images/solace_tutorial.png "getting started publish/subscribe")

<br>

## Deleting a deployment

### Deleting the PubSub+ deployment

To delete the deployment or to start over from Step 6 in a clean state:

```
helm list   # will list the releases (deployments)
helm delete XXX-XXX  # will delete instances related to your deployment - "my-release" in the example above
```

**Note:** Above will not delete dynamic Persistent Volumes (PVs) and related Persistent Volume Claims (PVCs). If recreating the deployment with same name and keeping the original PVCs, the original volumes get mounted with existing configuration. Deleting the PVCs will also delete the PVs:

```
# List PVCs
oc get pvc
# Delete unneeded PVCs
oc delete pvc <pvc-name>
```

To remove the project or to start over from Step 4 in a clean state, delete the project using the OpenShift console or the command line. For more details, refer to the [OpenShift Projects](https://docs.openshift.com/container-platform/4.6/applications/projects/working-with-projects.html ) documentation.

```
oc delete project solace-pubsub   # adjust your project name as needed
```

### Deleting the AWS OpenShift Container Platform deployment

To delete your OpenShift Container Platform deployment that was set up at Step 1, first you need to detach the IAM policies from the ‘Setup Role’ (IAM) that were attached in (Part II) of Step 1. Then you also need to ensure to free up the allocated OpenShift entitlements from your subscription otherwise they will no longer be available for a subsequent deployment.

Use this quick start's script to automate the execution of the required steps. SSH into the *ansible-configserver* then follow the commands:

```
# assuming pubsubplus-openshift-quickstart/scripts are still available from Step 1
cd ~/pubsubplus-openshift-quickstart/scripts
./prepareDeleteAWSOpenShift.sh
```

Now the OpenShift stack delete can be initiated from the AWS CloudFormation console.

## Special topics

### Using NFS for persistent storage

The Solace PubSub+ supports NFS for persistent storage, with "root_squash" option configured on the NFS server.

For an example deployment, specify the storage class from your NFS deployment ("nfs" in this example) in the `storage.useStorageClass` parameter and ensure `storage.slow` is set to `true`.

The Helm (NFS Server Provisioner)[https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner ] project is an example of a dynamic NFS server provisioner. Here are the steps to get going with it:

```
# Create the required SCC
sudo oc apply -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/scc.yaml
# Install the NFS helm chart, which will create all dependencies
helm install stable/nfs-server-provisioner --name nfs-test --set persistence.enabled=true,persistence.size=100Gi
# Ensure the "nfs-provisioner" service account got created
oc get serviceaccounts
# Bind the SCC to the "nfs-provisioner" service account
sudo oc adm policy add-scc-to-user nfs-provisioner -z nfs-test-nfs-server-provisioner
# Ensure the NFS server pod is up and running
oc get pod nfs-test-nfs-server-provisioner-0
```

If using templates top deploy locate the volume mont for `softAdb` in the template and disable it by commenting it out:

```yaml
# only mount softAdb when not using NFS, comment it out otherwise
#- name: data
#  mountPath: /usr/sw/internalSpool/softAdb
#  subPath: softAdb
```

## Resources

For more information about Solace technology in general please visit these resources:

* The Solace Developer Portal website at: http://dev.solace.com
* Understanding [Solace technology.](http://dev.solace.com/tech/)
* Ask the [Solace community](http://dev.solace.com/community/).