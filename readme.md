# Deploying a Solace PubSub+ Software Message Broker with **Security Enhancements** onto an OpenShift 3.10 or 3.11 platform

## Difference to the master branch

In this QuickStart the message broker gets deployed in an unprivileged container without any additional [Linux capabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html ) required. Compare with section [Running the message broker in unprivileged container](https://github.com/SolaceProducts/solace-openshift-quickstart#running-the-message-broker-in-unprivileged-container ) in the master branch.

This requires a Solace PubSub+ build which supports the security enhancements. A compatible build can be obtained through Solace Support.

## Purpose of this Repository

This repository provides an example of how to deploy Solace PubSub+ software message brokers onto an OpenShift 3.10 or 3.11 platform. There are [multiple ways](https://docs.openshift.com/index.html ) to get to an OpenShift platform, including [MiniShift](https://github.com/minishift/minishift#welcome-to-minishift ). This guide will specifically use the Red Hat OpenShift Container Platform for deploying an HA group but concepts are transferable to other compatible platforms. There will be also hints on how to set up a simple single-node MiniKube deployment using MiniShift for development, testing or proof of concept purposes. Instructions also apply to earlier OpenShift versions (3.7 and later).

For the Red Hat OpenShift Container Platform, we utilize the [RedHat OpenShift on AWS QuickStart](https://aws.amazon.com/quickstart/architecture/openshift/ ) project to deploy a Red Hat OpenShift Container Platform on AWS in a highly redundant configuration, spanning 3 zones.

This repository expands on the [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) to provide an example of how to deploy Solace PubSub+ software message brokers in an HA configuration on the OpenShift Container Platform running in AWS.

![alt text](/resources/network_diagram.jpg "Network Diagram")

## Description of the Solace PubSub+ Software Message Broker

The Solace PubSub+ software message broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The message broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. As well, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## How to deploy a Solace PubSub+ Message Broker onto OpenShift / AWS

The following steps describe how to deploy a message broker onto an OpenShift environment. Optional steps are provided about setting up a Red Hat OpenShift Container Platform on Amazon AWS infrastructure (marked as Optional / AWS) and if you use AWS Elastic Container Registry to host the Solace message broker Docker image (marked as Optional / ECR).

There are also two options for deploying a message broker onto your OpenShift deployment:
* (Deployment option 1, using Helm): This option allows great flexibility using the Kubernetes `Helm` tool to automate the process of message broker deployment through a wide range of configuration options including in-service rolling upgrade of the message broker. The [Solace Kubernetes QuickStart project](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) will be referred to deploy the message broker onto your OpenShift environment.
* (Deployment option 2, using OpenShift templates): This option can be used directly, without any additional tool to deploy the message broker in a limited number of configurations, using OpenShift templates included in this project.

This is a 6 steps process with some steps being optional. Steps to deploy the message broker:

**Hint:** You may skip Step 1 if you already have your own OpenShift environment deployed.

> Note: If using MiniShift follow the [instructions to get to a working MiniShift deployment](https://docs.okd.io/latest/minishift/getting-started/index.html ). If using MiniShift in a Windows environment one easy way to follow the shell scripts in the subsequent steps of this guide is to use [Git BASH for Windows](https://gitforwindows.org/ ) and ensure any script files are using unix style line endings by running the `dostounix` tool if needed. 

### Step 1: (Optional / AWS) Deploy OpenShift Container Platform onto AWS using the RedHat OpenShift AWS QuickStart Project

* (Part I) Log into the AWS Web Console and run the [OpenShift AWS QuickStart project](https://aws.amazon.com/quickstart/architecture/openshift/ ), which will use AWS CloudFormation for the deployment.  We recommend you deploy OpenShift across 3 AWS Availability Zones for maximum redundancy.  Please refer to the RedHat OpenShift AWS QuickStart guide and supporting documentation:

  * [Deploying and Managing OpenShift on Amazon Web Services](https://access.redhat.com/documentation/en-us/reference_architectures/2018/html/deploying_and_managing_openshift_3.9_on_amazon_web_services/ )
  
  **Important:** As described in above documentation, this deployment requires a Red Hat account with a valid Red Hat subscription to OpenShift and will consume 10 OpenShift entitlements in a maximum redundancy configuration. When no longer needed ensure to follow the steps in the [Deleting the OpenShift Container Platform deployment](#deleting-the-openshift-container-platform-deployment ) section of this guide to free up the entitlements.

  This deployment will create 10 EC2 instances: an *ansible-configserver* and three of each *openshift-etcd*, *openshift-master* and *openshift-nodes* servers. <br>
  
  **Note:** only the "*ansible-configserver*" is exposed externally in a public subnet. To access the other servers that are in a private subnet, first [SSH into](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html ) the *ansible-configserver* instance then use that instance as a bastion host to SSH into the target server using it's private IP. For that we recommend enabling [SSH agent forwarding](https://developer.github.com/v3/guides/using-ssh-agent-forwarding/ ) on your local machine to avoid the insecure option of copying and storing private keys remotely on the *ansible-configserver*.

* (Part II) Once you have deployed OpenShift using the AWS QuickStart you will have to perform additional steps to re-configure OpenShift to integrate fully with AWS.  For full details, please refer to the RedHat OpenShift documentation for configuring OpenShift for AWS:

  * [OpenShift > Configuring for AWS](https://docs.openshift.com/container-platform/3.10/install_config/configuring_aws.html )
  
  To help with that this quick start provides a script to automate the execution of the required steps:
  
   * Add the required AWS IAM policies to the ‘Setup Role’ (IAM) used by the RedHat QuickStart to deploy OpenShift to AWS
   * Tag public subnets so when creating a public service suitable public subnets can be found
   * Re-configure OpenShift Masters and OpenShift Nodes to make OpenShift aware of AWS deployment specifics
   
  SSH into the *ansible-configserver* then follow the commands.
  
```
## On the ansible-configserver server
# get the scripts
cd ~
git clone https://github.com/SolaceProducts/solace-openshift-quickstart.git
cd solace-openshift-quickstart/scripts
# substitute your own parameters for the following exports
# You can get the stack names e.g.: from the CloudFormation page of the AWS services console,
# see the 'Overview' tab of the *nested* OpenShiftStack and VPC substacks.
# You can get the access keys from the AWS services console IAM > Users > Security credentials.
export NESTEDOPENSHIFTSTACK_STACKNAME=XXXXXXXXXXXXXXXXXXXXX
export VPC_STACKNAME=XXXXXXXXXXXXXXXXXXXXX
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXX
# run the config script
./configureAWSOpenShift.sh
```

The script will end with listing the private IP of the *openshift-master* servers, one of which you will need to SSH into for the next step. The command to access it is `ssh <master-ip>` with SSH agent forwarding enabled.

Also verify you have access and can login to the OpenShift console. You can get the URL from the CloudFormation page of the AWS services console, see the 'Outputs' tab of the *nested* OpenShiftStack substack.

![alt text](/resources/GetOpenShiftURL.png "Getting to OpenShift console URL")

<p align="center">OpenShift deployment example with nested OpenShiftStack, VPCStack, tabs, keys and values</p>


### Step 2: Prepare your workspace

**Important:** This and subsequent steps shall be executed on a host having the OpenShift client tools and able to reach your OpenShift cluster nodes - conveniently, this can be one of the *openshift-master* servers.

> If using MiniShift, continue using your terminal.

* SSH into your selected host and ensure you are logged in to OpenShift. If you used Step 1 to deploy OpenShift, the requested server URL is the same as the OpenShift console URL, the username is `admin` and the password is as specified in the CloudFormation template. Otherwise use the values specific to your environment.

```
## On an openshift-master server
oc whoami  
# if not logged in yet
oc login   
```

* The Solace OpenShift QuickStart project contains useful scripts to help you prepare an OpenShift project for message broker deployment. Retrieve the project in your selected host:

```
mkdir ~/workspace
cd ~/workspace
git clone https://github.com/SolaceProducts/solace-openshift-quickstart.git
cd solace-openshift-quickstart
```

### Step 3: (Optional: only execute for Deployment option 1 - use the Solace Kubernetes QuickStart to deploy the message broker) Install the Helm client and server-side tools

* **(Part I)** Use the ‘deployHelm.sh’ script to deploy the Helm client and server-side components.  Begin by installing the Helm client tool:

> If using MiniShift, get the [Helm executable](https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-windows-amd64.zip ) and put it in a directory on your path before running the following script.

```
cd ~/workspace/solace-openshift-quickstart/scripts
./deployHelm.sh client
# Copy and run the export statuments from the script output!
```

  **Important:** After running the above script, note the **export** statements for the following environment variables from the output - copy and run them. It is also recommended to add them to `~/.bashrc` on your machine so they are automatically sourced at future sessions (These environment variables are required every time when running the `helm` client tool).

  
* **(Part II)** Install the Helm server-side ‘Tiller’ component:

```
cd ~/workspace/solace-openshift-quickstart/scripts
./deployHelm.sh server
```

### Step 4: Create and configure a project to host the message broker deployment

* Use the ‘prepareProject.sh’ script the Solace OpenShift QuickStart to create and configure an OpenShift project that meets requirements of the message broker deployment:

```
cd ~/workspace/solace-openshift-quickstart/scripts
sudo ./prepareProject.sh solace-pubsub    # adjust your project name as needed here and in subsequent commands
```

> Note: If using MiniShift on Windows use the command without `sudo`. If necessary, as a workaround, run just this command with logging in as "system:admin" before using `oc login -u system:admin`, then login afterward to the normal "admin" user. Running as the normal "admin" user provides the closest experience of  other OpenShift deployments.

### Step 5: Optional: Load the message broker (Docker image) to your Docker Registry

Deployment scripts will pull the Solace message broker image from a [Docker registry](https://docs.Docker.com/registry/ ). There are several [options which registry to use](https://docs.openshift.com/container-platform/3.10/architecture/infrastructure_components/image_registry.html#overview ) depending on the requirements of your project, see some examples in (Part II) of this step.

**Hint:** You may skip the rest of this step if using the free PubSub+ Standard Edition available from the [Solace public Docker Hub registry](https://hub.Docker.com/r/solace/solace-pubsub-standard/tags/ ). The Docker Registry URL to use will be `solace/solace-pubsub-standard:<TagName>`.

* **(Part I)** Download a copy of the message broker Docker image.

  Go to the Solace Developer Portal and download the Solace PubSub+ software message broker as a **Docker** image or obtain your version from Solace Support.

     * If using Solace PubSub+ Enterprise Evaluation Edition, go to the Solace Downloads page. For the image reference, copy and use the download URL in the Solace PubSub+ Enterprise Evaluation Edition Docker Images section.

         | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
         | :---: |
         | 90-day trial version of PubSub+ Enterprise |
         | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |


* **(Part II)** Deploy the message broker Docker image to your Docker registry of choice

  Options include:

  * You can choose to use [OpenShift's Docker registry.](https://docs.openshift.com/container-platform/3.10/install_config/registry/deploy_registry_existing_clusters.html )

  * **(Optional / ECR)** You can utilize the AWS Elastic Container Registry (ECR) to host the message broker Docker image. For more information, refer to [Amazon Elastic Container Registry](https://aws.amazon.com/ecr/ ). If you are using ECR as your Docker registry then you must add the ECR login credentials (as an OpenShift secret) to your message broker HA deployment.  This project contains a helper script to execute this step:

```
# Required if using ECR for Docker registry
cd ~/workspace/solace-openshift-quickstart/scripts
sudo su
aws configure       # provide AWS config for root
./addECRsecret.sh solace-pubsub   # adjust your project name as needed
```
  Here is an outline of the additional steps required if loading an image to ECR:
  
  * Copy the Solace Docker image location url and download the image archive locally using the `wget <url>` command.
  * Load the downloaded image to the local docker image repo using the `docker load -i <archive>` command
  * Go to your target ECR repository in the [AWS ECR Repositories console](https://console.aws.amazon.com/ecr ) and get the push commands information by clicking on the "View push commands" button.
  * Start from the `docker tag` command to tag the image you just loaded. Use `docker images` to find the  Solace Docker image just loaded. You may need to use 
  * Finally, use the `docker push` command to push the image.
  * Exit from superuser to normal user

![alt text](/resources/ECR-Registry.png "ECR Registry")

### Step 6: (Option 1) Deploy the message broker using the Solace Kubernetes QuickStart

If you require more flexibility in terms of message broker deployment options (compared to those offered by the OpenShift templates provided by this project) then use the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) to deploy the message broker:

* Retrieve the Solace Kubernetes QuickStart from GitHub:

Important: notice the use of the "SecurityEnhancements" branch below. The "master" branch is not compatible with the changes for OpenShift Security Enhancements.

```
cd ~/workspace
git clone https://github.com/SolaceProducts/solace-kubernetes-quickstart.git -b SecurityEnhancements
cd solace-kubernetes-quickstart
```

* Update the Solace Kubernetes Helm chart values.yaml configuration file for your target deployment with the help of the Kubernetes quick start `configure.sh` script. (Please refer to the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart#step-4 ) for further details):

Notes:

* Providing `-i SOLACE_IMAGE_URL` is optional (see [Step 5](#step-5-load-the-message-broker-Docker-image-to-your-Docker-registry ) if using the latest Solace PubSub+ Standard edition message broker image from the Solace public Docker Hub registry
* Set the cloud provider option to `-c aws` when deploying a message broker in an OpenShift / AWS environment
* Ensure Helm runs by executing `helm version`. If not, revisit [Step 3](#step-3-optional-only-for-deployment-option-1---use-the-solace-kubernetes-quickstart-to-deploy-the-message-broker-install-the-helm-client-and-server-side-tools ), including the export statements.

HA deployment example:

```
oc project solace-pubsub   # adjust your project name as needed
cd ~/workspace/solace-kubernetes-quickstart/solace
../scripts/configure.sh -p <ADMIN_PASSWORD> -c aws -v values-examples/prod1k-persist-ha-provisionPvc.yaml -i <SOLACE_IMAGE_URL> 
# Initiate the deployment
helm install . -f values.yaml
# Wait until all pods running and ready and the active message broker pod label is "active=true"
watch oc get pods --show-labels
```

non-HA deployment example:

```
oc project solace-pubsub   # adjust your project name as needed
cd ~/workspace/solace-kubernetes-quickstart/solace
../scripts/configure.sh -p <ADMIN_PASSWORD> -c aws -v values-examples/prod1k-persist-noha-provisionPvc.yaml -i <SOLACE_IMAGE_URL> 
# Initiate the deployment
helm install . -f values.yaml
# Wait until all pods running and ready and the active message broker pod label is "active=true"
watch oc get pods --show-labels
```

### Step 6: (Option 2) Deploy the message broker using the OpenShift templates included in this project

**Prerequisites:**
1. Determine your message broker disk space requirements.  We recommend a minimum of 30 gigabytes of disk space.
2. Define a strong password for the 'admin' user of the message broker and then base64 encode the value.  This value will be specified as a parameter when processing the message broker OpenShift template:
```
echo -n 'strong@dminPw!' | base64
```

**Deploy the message broker:**

You can deploy the message broker in either a single-node or high-availability configuration:

* For a **Single-Node** configuration:
  * Process the Solace 'Single Node' OpenShift template to deploy the message broker in a single-node configuration.  Specify values for the DOCKER_REGISTRY_URL, MESSAGEBROKER_IMAGE_TAG, MESSAGEBROKER_STORAGE_SIZE, and MESSAGEBROKER_ADMIN_PASSWORD parameters:
```
oc project solace-pubsub   # adjust your project name as needed
cd  ~/workspace/solace-openshift-quickstart/templates
oc process -f messagebroker_singlenode_template.yaml DEPLOYMENT_NAME=test-singlenode DOCKER_REGISTRY_URL=<replace with your Docker Registry URL> MESSAGEBROKER_IMAGE_TAG=<replace with your Solace message broker Docker image tag> MESSAGEBROKER_STORAGE_SIZE=30Gi MESSAGEBROKER_ADMIN_PASSWORD=<base64 encoded password> | oc create -f -
# Wait until all pods running and ready
watch oc get statefulset,service,pods,pvc,pv
```

* For a **High-Availability** configuration:
  * Process the Solace 'HA' OpenShift template to deploy the message broker in a high-availability configuration.  Specify values for the DOCKER_REGISTRY_URL, MESSAGEBROKER_IMAGE_TAG, MESSAGEBROKER_STORAGE_SIZE, and MESSAGEBROKER_ADMIN_PASSWORD parameters:
```
oc project solace-pubsub   # adjust your project name as needed
cd  ~/workspace/solace-openshift-quickstart/templates
oc process -f messagebroker_ha_template.yaml DEPLOYMENT_NAME=test-ha DOCKER_REGISTRY_URL=<replace with your Docker Registry URL> MESSAGEBROKER_IMAGE_TAG=<replace with your Solace message broker Docker image tag> MESSAGEBROKER_STORAGE_SIZE=30Gi MESSAGEBROKER_ADMIN_PASSWORD=<base64 encoded password> | oc create -f -
# Wait until all pods running and ready
watch oc get statefulset,service,pods,pvc,pv
```
  
## Validating the Deployment

Now you can validate your deployment from the OpenShift client shell:

```
[ec2-user@ip-10-0-23-198 ~]$ oc get statefulset,service,pods,pvc,pv --show-labels
NAME                                 DESIRED   CURRENT   AGE       LABELS
statefulsets/plucking-squid-solace   3         3         3m        app=solace,chart=solace-0.3.0,heritage=Tiller,release=plucking-squid

NAME                                  CLUSTER-IP      EXTERNAL-IP        PORT(S)                                       AGE       LABELS
svc/plucking-squid-solace             172.30.15.249   ae2dd15e27880...   22:30811/TCP,8080:30295/TCP,55555:30079/TCP   3m        app=solace,chart=solace-0.3.0,heritage=Tiller,release=plucking-squid
svc/plucking-squid-solace-discovery   None            <none>             8080/TCP                                      3m        app=solace,chart=solace-0.3.0,heritage=Tiller,release=plucking-squid

NAME                         READY     STATUS    RESTARTS   AGE       LABELS
po/plucking-squid-solace-0   1/1       Running   0          3m        active=true,app=solace,controller-revision-hash=plucking-squid-solace-335123159,release=plucking-squid
po/plucking-squid-solace-1   1/1       Running   0          3m        app=solace,controller-revision-hash=plucking-squid-solace-335123159,release=plucking-squid
po/plucking-squid-solace-2   1/1       Running   0          3m        app=solace,controller-revision-hash=plucking-squid-solace-335123159,release=plucking-squid

NAME                               STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS              AGE       LABELS
pvc/data-plucking-squid-solace-0   Bound     pvc-e2e20e0f-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           plucking-squid-standard   3m        app=solace,release=plucking-squid
pvc/data-plucking-squid-solace-1   Bound     pvc-e2e4379c-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           plucking-squid-standard   3m        app=solace,release=plucking-squid
pvc/data-plucking-squid-solace-2   Bound     pvc-e2e6e88d-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           plucking-squid-standard   3m        app=solace,release=plucking-squid

NAME                                          CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                                           STORAGECLASS              REASON    AGE       LABELS
pv/pvc-01e8785b-74b4-11e8-ac35-0afbbfab169a   1Gi        RWO           Delete          Bound     openshift-ansible-service-broker/etcd           gp2                                 4d        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1b
pv/pvc-229cf3d4-74b4-11e8-ba4e-02b74a526708   1Gi        RWO           Delete          Bound     aws-service-broker/etcd                         gp2                                 4d        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1b
pv/pvc-cf27bd8c-74b3-11e8-ac35-0afbbfab169a   10Gi       RWO           Delete          Bound     openshift-infra/metrics-cassandra-1             gp2                                 4d        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1c
pv/pvc-e2e20e0f-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           Delete          Bound     solace-pubsub/data-plucking-squid-solace-0   plucking-squid-standard             3m        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1c
pv/pvc-e2e4379c-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           Delete          Bound     solace-pubsub/data-plucking-squid-solace-1   plucking-squid-standard             3m        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1a
pv/pvc-e2e6e88d-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           Delete          Bound     solace-pubsub/data-plucking-squid-solace-2   plucking-squid-standard             3m        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1b
[ec2-user@ip-10-0-23-198 ~]$
[ec2-user@ip-10-0-23-198 ~]$
[ec2-user@ip-10-0-23-198 ~]$ oc describe svc
Name:                   plucking-squid-solace
Namespace:              solace-pubsub
Labels:                 app=solace
                        chart=solace-0.3.0
                        heritage=Tiller
                        release=plucking-squid
Annotations:            <none>
Selector:               active=true,app=solace,release=plucking-squid
Type:                   LoadBalancer
IP:                     172.30.15.249
LoadBalancer Ingress:   ae2dd15e2788011e8b19906c6ba3800d-1889414054.eu-central-1.elb.amazonaws.com
Port:                   ssh  22/TCP
TargetPort:             2222/TCP
NodePort:               ssh  31569/TCP
Endpoints:              10.128.2.11:2222
Port:                   semp  8080/TCP
TargetPort:             8080/TCP
NodePort:               semp  31260/TCP
Endpoints:              10.128.2.11:8080
Port:                   smf  55555/TCP
TargetPort:             55555/TCP
NodePort:               smf  32027/TCP
Endpoints:              10.128.2.11:55555
Port:                   semptls  943/TCP
TargetPort:             60943/TCP
NodePort:               semptls  31243/TCP
Endpoints:              10.128.2.11:60943
Port:                   web  80/TCP
TargetPort:             60080/TCP
NodePort:               web  32240/TCP
Endpoints:              10.128.2.11:60080
Port:                   webtls  443/TCP
TargetPort:             60443/TCP
NodePort:               webtls  30548/TCP
Endpoints:              10.128.2.11:60443
Session Affinity:       None
Events:
  FirstSeen     LastSeen        Count   From                    SubObjectPath   Type            Reason                  Message
  ---------     --------        -----   ----                    -------------   --------        ------                  -------
  5m            5m              1       service-controller                      Normal          CreatingLoadBalancer    Creating load balancer
  5m            5m              1       service-controller                      Normal          CreatedLoadBalancer     Created load balancer


Name:                   plucking-squid-solace-discovery
Namespace:              solace-pubsub
Labels:                 app=solace
                        chart=solace-0.3.0
                        heritage=Tiller
                        release=plucking-squid
Annotations:            service.alpha.kubernetes.io/tolerate-unready-endpoints=true
Selector:               app=solace,release=plucking-squid
Type:                   ClusterIP
IP:                     None
Port:                   semp    8080/TCP
Endpoints:              10.129.0.11:8080,10.130.0.12:8080,10.131.0.9:8080
Session Affinity:       None
Events:                 <none>
```

Find the **'LoadBalancer Ingress'** value listed in the service description above.  This is the publicly accessible Solace Connection URI for messaging clients and management. In the example it is `ae2dd15e2788011e8b19906c6ba3800d-1889414054.eu-central-1.elb.amazonaws.com`.

> Note: If using MiniShift an additional step is required to expose the service: `oc get --export svc plucking-squid-solace`. This will return a service definition with nodePort port numbers for each message router service. Use these port mumbers together with MiniShift's public IP address which can be obtained from the command `minishift ip`.


### Viewing bringup logs

To see the deployment events, navigate to:

* **OpenShift UI > (Your Project) > Applications > Stateful Sets > ((name)-solace) > Events**

You can access the log stack for individual message broker pods from the OpenShift UI, by navigating to:

* **OpenShift UI > (Your Project) > Applications > Stateful Sets > ((name)-solace) > Pods > ((name)-solace-(N)) > Logs**

![alt text](/resources/Solace-Pod-Log-Stack.png "Message Broker Pod Log Stack")

Where (N) above is the ordinal of the Solace message broker:
  * 0 - Primary message broker
  * 1 - Backup message broker
  * 2 - Monitor message broker

## Gaining admin and ssh access to the message broker

The external management host URI will be the Solace Connection URI associated with the load balancer generated by the message broker OpenShift template.  Access will go through the load balancer service as described in the introduction and will always point to the active message broker. The default port is 22 for CLI and 8080 for SEMP/SolAdmin.

If you deployed OpenShift in AWS, then the Solace OpenShift QuickStart will have created an EC2 Load Balancer to front the message broker / OpenShift service.  The Load Balancer public DNS name can be found in the AWS EC2 console under the 'Load Balancers' section.

To lauch Solace CLI or ssh into the individual message broker instances from the OpenShift CLI use:

```
# CLI access
oc exec -it XXX-XXX-solace-X cli   # adjust pod name to your deployment
# shell access
oc exec -it XXX-XXX-solace-X bash  # adjust pod name to your deployment
```

> Note for MiniShift: if using Windows you may get an error message: `Unable to use a TTY`. Install and preceed above commands with `winpty` until this is fixed in the MiniShift project.


You can also gain access to the Solace CLI and container shell for individual message broker instances from the OpenShift UI.  A web-based terminal emulator is available from the OpenShift UI.  Navigate to an individual message broker Pod using the OpenShift UI:

* **OpenShift UI > (Your Project) > Applications > Stateful Sets > ((name)-solace) > Pods > ((name)-solace-(N)) > Terminal**

Once you have launched the terminal emulator to the message broker pod you may access the Solace CLI by executing the following command:

```
/usr/sw/loads/currentload/bin/cli -A
```

![alt text](/resources/Solace-Primary-Pod-Terminal-CLI.png "Message Broker CLI via OpenShift UI Terminal emulator")

See the [Solace Kubernetes Quickstart README](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#gaining-admin-access-to-the-message-broker ) for more details including admin and SSH access to the individual message brokers.

## Testing data access to the message broker

To test data traffic though the newly created message broker instance, visit the Solace Developer Portal and select your preferred programming language to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/ ). Under each language there is a Publish/Subscribe tutorial that will help you get started.

Note: the Host will be the Solace Connection URI. It may be necessary to [open up external access to a port](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#upgradingmodifying-the-message-broker-cluster ) used by the particular messaging API if it is not already exposed.

![alt text](/resources/solace_tutorial.png "getting started publish/subscribe")

<br>

## Deleting a deployment

### Deleting the Solace message broker deployment

To delete the deployment or to start over from Step 6 in a clean state:

* If used (Option 1) Helm to deploy, execute: 

```
helm list   # will list the releases (deployments)
helm delete XXX-XXX  # will delete instances related to your deployment - "plucking-squid" in the example above
```

* If used (Option 2) OpenShift templates to deploy, use:

```
cd ~/workspace/solace-openshift-quickstart/templates
oc process -f <template-used> DEPLOYMENT_NAME=<deploymentname> | oc delete -f -
```

**Note:** Above will not delete dynamic Persistent Volumes (PVs) and related Persistent Volume Claims (PVCs). If recreating the deployment with same name, the original volumes get mounted with existing configuration. Deleting the PVCs will also delete the PVs:

```
# List PVCs
oc get pvc
# Delete unneeded PVCs
oc delete pvc <pvc-name>
```

To remove the project or to start over from Step 4 in a clean state, delete the project using the OpenShift console or the command line. For more details, refer to the [OpenShift Projects](https://docs.openshift.com/enterprise/3.0/dev_guide/projects.html ) documentation.

```
oc delete project solace-pubsub   # adjust your project name as needed
```

### Deleting the OpenShift Container Platform deployment

To delete your OpenShift Container Platform deployment that was set up at Step 1, first you need to detach the IAM policies from the ‘Setup Role’ (IAM) that were attached in (Part II) of Step 1. Then you also need to ensure to free up the allocated OpenShift entitlements from your subscription otherwise they will no longer be available for a subsequent deployment.

Use this quick start's script to automate the execution of the required steps. SSH into the *ansible-configserver* then follow the commands:

```
# assuming solace-openshift-quickstart/scripts are still available from Step 1
cd ~/solace-openshift-quickstart/scripts
./prepareDeleteAWSOpenShift.sh
```

Now the OpenShift stack delete can be initiated from the AWS CloudFormation console.

## Special topics

### Using NFS for persistent storage

The Solace PubSub+ message broker supports NFS for persistent storage, with "root_squash" option configured on the NFS server.

For an example using dynamic volume provisioning with NFS, use the Solace Kubernetes Helm chart `values-examples/prod1k-persist-ha-nfs.yaml` configuration file in [Step 6](#step-6-option-1-deploy-the-message-broker-using-the-solace-kubernetes-quickstart ). By default, this sample configuration is using the StorageClass "nfs" for volume claims, assuming this StorageClass is backed by an NFS server.

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

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceProducts/solace-openshift-quickstart/graphs/contributors ) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

* The Solace Developer Portal website at: http://dev.solace.com
* Understanding [Solace technology.](http://dev.solace.com/tech/)
* Ask the [Solace community](http://dev.solace.com/community/).