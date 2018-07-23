# Deploying a Solace PubSub+ Software Message Broker HA Group onto an OpenShift 3.7 or 3.9 platform

## Purpose of this Repository

This repository provides an example of how to deploy Solace PubSub+ software message brokers onto an OpenShift 3.7 or 3.9 platform. There are [multiple ways](https://docs.openshift.com/index.html ) to get to an OpenShift platform, including [MiniShift](https://github.com/minishift/minishift#welcome-to-minishift ). This guide will specifically use the Red Hat OpenShift Container Platform 3.7 or 3.9 but concepts are transferable to other compatible platforms.

We utilize the [RedHat OpenShift on AWS QuickStart](https://aws.amazon.com/quickstart/architecture/openshift/ ) project to deploy a Red Hat OpenShift Container Platform on AWS in a highly redundant configuration, spanning 3 zones.

This repository expands on the [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) to provide an example of how to deploy Solace PubSub+ software message brokers in an HA configuration on the OpenShift Container Platform running in AWS.

![alt text](/resources/network_diagram.jpg "Network Diagram")

## Description of the Solace PubSub+ Software Message Broker

The Solace PubSub+ software message broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The message broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. As well, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## How to deploy a Solace PubSub+ Message Broker onto OpenShift / AWS

The following steps describe how to deploy a message broker onto an OpenShift environment. Optional steps are provided about setting up a Red Hat OpenShift Container Platform on Amazon AWS infrastructure (marked as Optional / AWS) and if you use AWS Elastic Container Registry to host the Solace message broker Docker image (marked as Optional / ECR).

There are also two options for deploying a message broker onto your OpenShift deployment:
* (Deployment option 1): This option allows great flexibility using the Kubernetes `Helm` tool to automate the process of message broker deployment through a wide range of configuration options including in-service rolling upgrade of the message broker. The [Solace Kubernetes QuickStart project](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) will be referred to deploy the message broker onto your OpenShift environment.
* (Deployment option 2): This option can be used directly, without any additional tool to deploy the message broker in a limited number of configurations, using OpenShift templates included in this project.

Steps to deploy the message broker:

**Hint:** You may skip Step 1 if you already have your own OpenShift environment deployed.

### Step 1: (Optional / AWS) Deploy OpenShift Container Platform onto AWS using the RedHat OpenShift AWS QuickStart Project

* (Part I) Log into the AWS Web Console and run the [OpenShift AWS QuickStart project](https://aws.amazon.com/quickstart/architecture/openshift/ ), which will use AWS CloudFormation for the deployment.  We recommend you deploy OpenShift across 3 AWS Availability Zones for maximum redundancy.  Please refer to the RedHat OpenShift AWS QuickStart guide and supporting documentation:

  * [Deploying and Managing OpenShift 3.9 on Amazon Web Services](https://access.redhat.com/documentation/en-us/reference_architectures/2018/html/deploying_and_managing_openshift_3.9_on_amazon_web_services/ )
  
  **Important:** As described in above documentation, this deployment requires a Red Hat account with a valid Red Hat subscription to OpenShift and will consume 10 OpenShift entitlements in a maximum redundancy configuration. When no longer needed ensure to follow the steps in the [Deleting the OpenShift Container Platform deployment](#deleting-the-openshift-container-platform-deployment ) section of this guide to free up the entitlements.

  This deployment will create 10 EC2 instances: an *ansible-configserver* and three of each *openshift-etcd*, *openshift-master* and *openshift-nodes* servers. <br>
  Note that only the *ansible-configserver* is exposed externally in a public subnet. To access the other servers that are in a private subnet, first [SSH into](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html ) the *ansible-configserver* instance then use that instance as a bastion host to SSH into the target server using it's private IP. For that we recommend enabling [SSH agent forwarding](https://developer.github.com/v3/guides/using-ssh-agent-forwarding/ ) on your local machine to avoid storing private keys remotely.

* (Part II) Once you have deployed OpenShift using the AWS QuickStart you will have to perform additional steps to re-configure OpenShift to integrate fully with AWS.  For full details, please refer to the RedHat OpenShift documentation for configuring OpenShift for AWS:

  * [OpenShift > Configuring for AWS](https://docs.openshift.com/container-platform/3.7/install_config/configuring_aws.html )
  
  To help with that this quick start provides a script to automate the execution of the required steps:
  
   * Add the required AWS IAM policies to the ‘Setup Role’ (IAM) used by the RedHat QuickStart to deploy OpenShift to AWS
   * Tag public subnets so when creating a public service suitable public subnets can be found
   * Re-configure OpenShift Masters and OpenShift Nodes to make OpenShift aware of AWS deployment specifics
   
  SSH into the *ansible-configserver* then follow the commands. The script will end with listing the private IP of the *openshift-master* servers, one of which you will need to SSH into for the next step, as described in (Part I).
  
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

Verify you have access and can login to the OpenShift console. You can get the URL from the CloudFormation page of the AWS services console, see the 'Outputs' tab of the *nested* OpenShiftStack substack.

![alt text](/resources/GetOpenShiftURL.png "Getting to OpenShift console URL")

<p align="center">OpenShift deployment example with nested OpenShiftStack, VPCStack, tabs, keys and values</p>


### Step 2: Prepare for the deployment

**Note:** This and subsequent steps shall be executed on a host having the OpenShift client tools and able to reach your OpenShift cluster nodes - conveniently, this can be one of the *openshift-master* servers.

* The Solace OpenShift QuickStart project contains useful scripts to help you prepare an OpenShift project for message broker deployment. SSH into your selected host and retrieve the project:

```
## On an openshift-master server
mkdir ~/workspace
cd ~/workspace
git clone https://github.com/SolaceProducts/solace-openshift-quickstart.git
cd solace-openshift-quickstart
```

### Step 3: (Optional: only for Deployment option 1 - use the Solace Kubernetes QuickStart to deploy the message broker) Install the Helm client and server-side tools

* **(Part I)** Use the ‘deployHelm.sh’ script to deploy the Helm client and server-side components.  Begin by installing the Helm client tool:

```
cd ~/workspace/solace-openshift-quickstart/scripts
./deployHelm.sh client
```

* After running the above script, note the export statements for the following environment variables from the output - copy and run them. It is also recommended to add them to `~/.bashrc` on your machine so they are automatically sourced at future sessions (These environment variables are required every time when running the `helm` client tool):
  * HELM_HOME
  * TILLER_NAMESPACE
  * PATH

* **(Part II)** Install the Helm server-side ‘Tiller’ component.  Note, you will be prompted to log into OpenShift if you have not already done so. If you used Step 1 to deploy OpenShift, the requested server URL is the same as the OpenShift console URL, the username is `admin` and the password is as specified in the CloudFormation template. Otherwise use the values specific to your environment.

```
cd ~/workspace/solace-openshift-quickstart/scripts
./deployHelm.sh server
```

### Step 4: Use scripts in the Solace OpenShift QuickStart to configure a project to host the message broker HA deployment

* Use the ‘prepareProject.sh’ script to create and configure an OpenShift project that meets requirements of the message broker HA deployment:

```
cd ~/workspace/solace-openshift-quickstart/scripts
sudo ./prepareProject.sh solace-pubsub-ha    # adjust your project name as needed here and in subsequent commands
```

### Step 5 Load the message broker (Docker image) to your Docker Registry

Deployment scripts will pull the Solace message broker image from a [docker registry](https://docs.docker.com/registry/ ). There are several [options which registry to use](https://docs.openshift.com/container-platform/3.7/architecture/infrastructure_components/image_registry.html#overview ) depending on the requirements of your project, see some examples in (Part II) of this step.

**Hint:** You may skip the rest of this step if using the free PubSub+ Standard Edition available from the [Solace public Docker Hub registry](https://hub.docker.com/r/solace/solace-pubsub-standard/tags/ ). The Docker Registry URL to use will be `solace/solace-pubsub-standard:<TagName>`.

* **(Part I)** Download a copy of the message broker Docker image.

  Go to the Solace Developer Portal and download the Solace PubSub+ software message broker as a **Docker** image or obtain your version from Solace Support.

  You can use this quick start with either PubSub+ `Standard` or PubSub+ `Enterprise Evaluation Edition`.

  | PubSub+ Standard<br/>Docker Image | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
  | :---: | :---: |
  | Free, up to 1k simultaneous connections,<br/>up to 10k messages per second | 90-day trial version, unlimited |
  | [Download Standard Docker Image](http://dev.solace.com/downloads/) | [Download Evaluation Docker Image](http://dev.solace.com/downloads#eval) |

* **(Part II)** Deploy the message broker docker image to your Docker registry of choice

  Options include:

  * You can choose to use [OpenShift's docker registry.](https://docs.openshift.com/container-platform/3.7/install_config/registry/deploy_registry_existing_clusters.html )

  * **(Optional / ECR)** You can utilize the AWS Elastic Container Registry (ECR) to host the message broker Docker image. For more information, refer to [Amazon Elastic Container Registry](https://aws.amazon.com/ecr/ ). If you are using ECR as your Docker registry then you must add the ECR login credentials (as an OpenShift secret) to your message broker HA deployment.  This project contains a helper script to execute this step:

```
# Required if using ECR for docker registry
sudo aws configure       # provide AWS config for root
cd ~/workspace/solace-openshift-quickstart/scripts
sudo ./addECRsecret.sh solace-pubsub-ha   # adjust your project name as needed
```

### Step 6: (Option 1) Deploy the message broker using the Solace Kubernetes QuickStart

If you require more flexibility in terms of message broker deployment options (compared to those offered by the OpenShift templates provided by this project) then use the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) to deploy the message broker:

* Retrieve the Solace Kubernetes QuickStart from GitHub:

```
cd ~/workspace
git clone https://github.com/SolaceProducts/solace-kubernetes-quickstart.git
cd solace-kubernetes-quickstart
```

* Update the Solace Kubernetes helm chart values.yaml configuration file for your target deployment with the help of the Kubernetes quick start `configure.sh` script. (Please refer to the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart#step-4 ) for further details):

Notes:

* `SOLACE_IMAGE_URL` is optional if using the latest Solace PubSub+ Standard edition message broker image from the Solace public Docker Hub registry
* Set the cloud provider option to `-c aws` when deploying a message broker in an OpenShift / AWS environment

HA deployment example:

```
oc project solace-pubsub-ha   # adjust your project name as needed
cd ~/workspace/solace-kubernetes-quickstart/solace
../scripts/configure.sh -p <ADMIN_PASSWORD> -c aws -v values-examples/prod1k-persist-ha-provisionPvc.yaml -i <SOLACE_IMAGE_URL> 
# Initiate the deployment
helm install . -f values.yaml
# Wait until all pods running and ready and the active message broker pod label is "active=true"
watch oc get statefulset,service,pods,pvc,pv --show-labels
```

non-HA deployment example:

```
oc project solace-pubsub-ha   # adjust your project name as needed
cd ~/workspace/solace-kubernetes-quickstart/solace
../scripts/configure.sh -p <ADMIN_PASSWORD> -c aws -v values-examples/prod1k-persist-noha-provisionPvc.yaml -i <SOLACE_IMAGE_URL> 
# Initiate the deployment
helm install . -f values.yaml
# Wait until all pods running and ready and the active message broker pod label is "active=true"
watch oc get statefulset,service,pods,pvc,pv --show-labels
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
oc project solace-pubsub-ha   # adjust your project name as needed
cd  ~/workspace/solace-openshift-quickstart/templates
oc process -f messagebroker_singlenode_template.yaml DEPLOYMENT_NAME=test-singlenode DOCKER_REGISTRY_URL=<replace with your Docker Registry URL> MESSAGEBROKER_IMAGE_TAG=<replace with your Solace message broker docker image tag> MESSAGEBROKER_STORAGE_SIZE=30Gi MESSAGEBROKER_ADMIN_PASSWORD=<base64 encoded password> | oc create -f -
# Wait until all pods running and ready
watch oc get statefulset,service,pods,pvc,pv
```

* For a **High-Availability** configuration:
  * Process the Solace 'HA' OpenShift template to deploy the message broker in a high-availability configuration.  Specify values for the DOCKER_REGISTRY_URL, MESSAGEBROKER_IMAGE_TAG, MESSAGEBROKER_STORAGE_SIZE, and MESSAGEBROKER_ADMIN_PASSWORD parameters:
```
oc project solace-pubsub-ha   # adjust your project name as needed
cd  ~/workspace/solace-openshift-quickstart/templates
oc process -f messagebroker_ha_template.yaml DEPLOYMENT_NAME=test-ha DOCKER_REGISTRY_URL=<replace with your Docker Registry URL> MESSAGEBROKER_IMAGE_TAG=<replace with your Solace message broker docker image tag> MESSAGEBROKER_STORAGE_SIZE=30Gi MESSAGEBROKER_ADMIN_PASSWORD=<base64 encoded password> | oc create -f -
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
pv/pvc-e2e20e0f-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           Delete          Bound     solace-pubsub-ha/data-plucking-squid-solace-0   plucking-squid-standard             3m        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1c
pv/pvc-e2e4379c-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           Delete          Bound     solace-pubsub-ha/data-plucking-squid-solace-1   plucking-squid-standard             3m        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1a
pv/pvc-e2e6e88d-7880-11e8-b199-06c6ba3800d0   30Gi       RWO           Delete          Bound     solace-pubsub-ha/data-plucking-squid-solace-2   plucking-squid-standard             3m        failure-domain.beta.kubernetes.io/region=eu-central-1,failure-domain.beta.kubernetes.io/zone=eu-central-1b
[ec2-user@ip-10-0-23-198 ~]$
[ec2-user@ip-10-0-23-198 ~]$
[ec2-user@ip-10-0-23-198 ~]$ oc describe svc
Name:                   plucking-squid-solace
Namespace:              solace-pubsub-ha
Labels:                 app=solace
                        chart=solace-0.3.0
                        heritage=Tiller
                        release=plucking-squid
Annotations:            <none>
Selector:               active=true,app=solace,release=plucking-squid
Type:                   LoadBalancer
IP:                     172.30.15.249
LoadBalancer Ingress:   ae2dd15e2788011e8b19906c6ba3800d-1889414054.eu-central-1.elb.amazonaws.com
Port:                   ssh     22/TCP
NodePort:               ssh     30811/TCP
Endpoints:              10.129.0.11:22
Port:                   semp    8080/TCP
NodePort:               semp    30295/TCP
Endpoints:              10.129.0.11:8080
Port:                   smf     55555/TCP
NodePort:               smf     30079/TCP
Endpoints:              10.129.0.11:55555
Session Affinity:       None
Events:
  FirstSeen     LastSeen        Count   From                    SubObjectPath   Type            Reason                  Message
  ---------     --------        -----   ----                    -------------   --------        ------                  -------
  5m            5m              1       service-controller                      Normal          CreatingLoadBalancer    Creating load balancer
  5m            5m              1       service-controller                      Normal          CreatedLoadBalancer     Created load balancer


Name:                   plucking-squid-solace-discovery
Namespace:              solace-pubsub-ha
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

Note, the **'LoadBalancer Ingress'** value listed in the service description above.  This is the publicly accessible Solace Connection URI for messaging clients and management. In the example it is `ae2dd15e2788011e8b19906c6ba3800d-1889414054.eu-central-1.elb.amazonaws.com`.

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

You can gain access to the Solace CLI and container shell for individual message broker instances from the OpenShift UI.  A web-based terminal emulator is available from the OpenShift UI.  Navigate to an individual message broker Pod using the OpenShift UI:

* **OpenShift UI > (Your Project) > Applications > Stateful Sets > ((name)-solace) > Pods > ((name)-solace-(N)) > Terminal**

Once you have launched the terminal emulator to the message broker pod you may access the Solace CLI by executing the following command:
```
/usr/sw/loads/currentload/bin/cli -A
```

![alt text](/resources/Solace-Primary-Pod-Terminal-CLI.png "Message Broker CLI via OpenShift UI Terminal emulator")

See the [Solace Kubernetes Quickstart README](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#gaining-admin-access-to-the-message-broker ) for more details including admin and ssh access to the individual message brokers.

## Testing data access to the message broker

To test data traffic though the newly created message broker instance, visit the Solace Developer Portal and select your preferred programming language to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/ ). Under each language there is a Publish/Subscribe tutorial that will help you get started.

Note: the Host will be the Solace Connection URI. It may be necessary to [open up external access to a port](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#upgradingmodifying-the-message-broker-cluster ) used by the particular messaging API if it is not already exposed.

![alt text](/resources/solace_tutorial.png "getting started publish/subscribe")

<br>

## Deleting a deployment

### Deleting the Solace message broker deployment

To delete the deployment or to start over from Step 6 in a clean state:

* If used (Option 1) `helm` to deploy, execute: 

```
helm list   # will list the releases (deployments)
helm delete XXX-XXX  # your deployment - "plucking-squid" in the example above
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
oc delete project solace-pubsub-ha   # adjust your project name as needed
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