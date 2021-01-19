# Deploying a Solace PubSub+ Software Event Broker onto an OpenShift 4 platform

This is detailed documentation of deploying Solace PubSub+ Software Event Broker onto an OpenShift 4 platform including steps to set up a Red Hat OpenShift Container Platform platform on AWS.
* For a hands-on quick start using an existing OpenShift platform, refer to the [Quick Start guide](/README.md).
* For considerations about deploying in a general Kubernetes environment, refer to the [Solace PubSub+ on Kubernetes Documentation](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md)
* For the `pubsubplus` Helm chart configuration options, refer to the [PubSub+ Software Event Broker Helm Chart Reference](/pubsubplus/README.md).



Contents:
  * [Purpose of this Repository](#purpose-of-this-repository)
  * [Description of Solace PubSub+ Software Event Broker](#description-of-solace-pubsub-software-event-broker)
  * [Production Deployment Architecture](#production-deployment-architecture)
  * [Deployment Options](#deployment-options)
      - [Option 1, using Helm](#option-1-using-helm)
      - [Option 2, using OpenShift templates](#option-2-using-openshift-templates)
  * [How to deploy Solace PubSub+ onto OpenShift / AWS](#how-to-deploy-solace-pubsub-onto-openshift-aws)
    + [Step 1: (Optional / AWS) Deploy a self-managed OpenShift Container Platform onto AWS](#step-1-optional-aws-deploy-a-self-managed-openshift-container-platform-onto-aws)
    + [Step 2: Specify an OpenShift project for deployment](#step-2-specify-an-openshift-project-for-deployment)
    + [Step 3: Optional: Using a Private Image Registry](#step-3-optional-using-a-private-image-registry)
    + [Step 4-Option 1: Deploy using Helm](#step-4-option-1-deploy-using-helm)
    + [Step 4-Option 2: Deploy using OpenShift Templates](#step-4-option-2-deploy-using-openshift-templates)
  * [Validating the Deployment](#validating-the-deployment)
    + [Viewing Bringup logs](#viewing-bringup-logs)
  * [Gaining Admin and SSH access to the event broker](#gaining-admin-and-ssh-access-to-the-event-broker)
  * [Testing data access to the event broker](#testing-data-access-to-the-event-broker)
  * [Deleting a deployment](#deleting-a-deployment)
    + [Deleting the PubSub+ deployment](#deleting-the-pubsub-deployment)
    + [Deleting the AWS OpenShift Container Platform deployment](#deleting-the-aws-openshift-container-platform-deployment)
  * [Special topics](#special-topics)
    + [Using NFS for persistent storage](#using-nfs-for-persistent-storage)
  * [Resources](#resources)

## Purpose of this Repository

This repository provides an example of how to deploy the Solace PubSub+ Software Event Broker onto an OpenShift 4 platform. There are [multiple ways](https://www.openshift.com/try ) to get to an OpenShift platform. This guide will specifically use the Red Hat OpenShift Container Platform for deploying an HA group with concepts transferable to other compatible platforms. There will be also hints on how to set up a simple single-node deployment using [CodeReady Containers](https://developers.redhat.com/products/codeready-containers/overview ) (the equivalent of MiniShift for OpenShift 4)  for development, testing or proof of concept purposes.

The supported Solace PubSub+ Software Event Broker version is 9.7 or later.

For the Red Hat OpenShift Container Platform, we utilize a self-managed 60 day evaluation subscription of [RedHat OpenShift cluster in AWS](https://cloud.redhat.com/openshift/install#public-cloud ) in a highly redundant configuration, spanning 3 zones.

This repository expands on the [Solace Kubernetes Quickstart](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/README.md ) to provide an example of how to deploy Solace PubSub+ in an HA configuration on the OpenShift Container Platform running in AWS.

The event broker deployment does not require any special OpenShift Security Context, the [default "restricted" SCC](https://docs.openshift.com/container-platform/4.6/authentication/managing-security-context-constraints.html ) can be used.

## Description of Solace PubSub+ Software Event Broker 

Solace PubSub+ Software Event Broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The event broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. As well, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## Production Deployment Architecture

The following diagram shows an example HA deployment in AWS:
![alt text](/docs/images/network_diagram.jpg "Network Diagram")

<br/>
Key parts are the three PubSub+ Container instances in OpenShift pods, deployed on OpenShift (worker) nodes; the cloud load balancer exposing the event router's services and management interface; the OpenShift master nodes(s); and the CLI console that hosts the `oc` OpenShift CLI utility client.

## Deployment Options

#### Option 1, using Helm

This option allows great flexibility using the Kubernetes `Helm` tool to automate the process of event broker deployment through a wide range of configuration options including in-service rolling upgrade of the event broker. The [Solace Kubernetes QuickStart project](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/tree/master ) will be referred to deploy the event broker onto your OpenShift environment.

#### Option 2, using OpenShift templates

This option can be used directly, without any additional tool to deploy the event broker in a limited number of configurations, using OpenShift templates included in this project. Follow the [steps provided](#step-6-option-2-deploy-the-event-broker-using-the-openshift-templates-included-in-this-project).


## How to deploy Solace PubSub+ onto OpenShift / AWS

The following steps describe how to deploy an event broker onto an OpenShift environment. Optional steps are provided about setting up a self-managed Red Hat OpenShift Container Platform on Amazon AWS infrastructure (marked as Optional / AWS) and if you use AWS Elastic Container Registry to host the Solace PubSub+ Docker image (marked as Optional / ECR).

**Hint:** You may skip Step 1 if you already have your own OpenShift environment available.

> Note: If using CodeReady Containers follow the [instructions to get to a working CodeReady Containers deployment](https://developers.redhat.com/products/codeready-containers/getting-started ). Linux, MacOS and Windows are supported. At the `crc start` step it helps to have a local `pullsecret` file created and also specify CPU and memory requirements, allowing 1 CPU and 2.5 GiB memory for CRC internal purposes. It also helps to specify a DNS server. Example: `crc start -p ./pullsecret -c 3 -m 8148 --nameserver 1.1.1.1`.

### Step 1: (Optional / AWS) Deploy a self-managed OpenShift Container Platform onto AWS

Pre-requisites:
* This requires a free Red Hat account, [create one](https://developers.redhat.com/login ) if needed
* A command console is required on your host platform with Internet access. Examples here are provided using Linux. MacOS is also supported.
* Designate a working directory for the OpenShift cluster installation. Files created here by the automated install process will be required when deleting the OpenShift cluster.
```
mkdir ~/workspace; cd ~/workspace
```

Procedure:
* From the [Install OpenShift Container Platform 4, In the public cloud](https://cloud.redhat.com/openshift/install#public-cloud ) section select "AWS", then "Installer-provisioned infrastructure". This will bring to a page with the required binaries and documentation.
* On your host command console download and expand the "OpenShift installer"
```
wget <link-address>  # copy here the link address from the "Download installer" button
tar -xvf openshift-install-linux.tar.gz    # Adjust filename if needed
rm openshift-install-linux.tar.gz
```
* Run the utility to create an install configuration, provide information at the prompts including the Pull Secret from the RedHat instructions page. This will create the file `install-config.yaml` with [installation configuration parameters](https://docs.openshift.com/container-platform/4.6/installing/installing_aws/installing-aws-customizations.html#installation-aws-config-yaml_installing-aws-customizations), most importantly the configuration for the worker and master nodes.
```
./openshift-install create install-config --dir=.
```
* Edit `install-config.yaml` as the worker node AWS machine type needs to be updated from default to meet [minimum CPU and Memory requirements](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#cpu-and-memory-requirements) for the targeted PubSub+ Software Event Broker configuration. When selecting an [EC2 instance type](https://aws.amazon.com/ec2/instance-types/) allow at least 1 CPU and 1GiB memory for OpenShift purposes that cannot be used by the broker. Here is an example updated configuration:
```
...
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform:
    aws:
      type: m5.2xlarge  # Adjust to your requirements
  replicas: 3
...
```
* Create a backup copy of the config file then launch the installation. This may take 40 minutes or more.
```
cp install-config.yaml install-config.yaml.bak
./openshift-install create cluster --dir=.
```
* A successful installation will end with hints how to get started. Take notes for future reference.
```
INFO Install complete!
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/opt/auth/kubeconfig'
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.iuacc.soltest.net
INFO Login to the console with user: "kubeadmin", and password: "CKGc9-XUT6J-PDtWp-d4DSQ"
```
* [Install](https://docs.openshift.com/container-platform/4.6/installing/installing_aws/installing-aws-default.html#cli-installing-cli_installing-aws-default) the `oc` client CLI tool.
* Follow above hints to get started, including verifying access to the web-console.


### Step 2: Specify an OpenShift project for deployment

Create a new project or switch to your existing project (do not use the `default` project as it's loose permissions doesn't reflect a typical OpenShift environment)
```
oc new-project solace-pubsub    # adjust your project name as needed here and in subsequent commands
```

### Step 3: Optional: Using a Private Image Registry

By default, deployment scripts will pull the Solace PubSub+ image from [Docker Hub](https://hub.docker.com/r/solace/solace-pubsub-standard/tags?page=1&ordering=last_updated ) and assuming Internet access of the OpenShift worker nodes no further configuration is required.

If using a private image registry, such as AWS ECR, a pull secret is required to enable access to the registry. The followings will walk through how to use AWS ECR for the broker image.

* Download a copy of the event broker image: go to the Solace Developer Portal and download the Solace PubSub+ as a **Docker** image or obtain your version from Solace Support.
     * If using Solace PubSub+ Enterprise Evaluation Edition, go to the Solace Downloads page. For the image reference, copy and use the download URL in the Solace PubSub+ Enterprise Evaluation Edition Docker Images section.

         | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
         | :---: |
         | 90-day trial version of PubSub+ Enterprise |
         | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |
* Push the broker image to the private registry. Follow the specific procedures for the registry you are using, e.g.: [for the AWS ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html ).
Note: if advised to run `aws ecr get-login-password` as part of the "Authenticate to your registry" step and it fails, try running `$(aws ecr get-login --region <your-registry-region> --no-include-email)` instead.
![alt text](/docs/images/ECR-Registry.png "ECR Registry")
* Create a pull secret from the registry information in the Docker configuration. This assumes that ECR login happened on the same machine:
```
oc create secret generic <my-pullsecret> \
   --from-file=.dockerconfigjson=$(readlink -f ~/.docker/config.json) \
   --type=kubernetes.io/dockerconfigjson
```
* Use `<my-pullsecret>` in following Step 4.

Additional information on private registries is also available from the Solace Kubernetes Quickstart documentation, refer to the [Using private registries](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#using-private-registries) section.

> Note: If using CodeReady Containers a workaround may be required if ECR login fails on the console (e.g. on Windows). In this case log into the OpenShift node: `oc get node`, then `oc debug node/<reported-node-name>`, finally execute `chroot /host` at the prompt. Since it is not straightforward to install the `aws` CLI on CoreOS running on the node, obtain `aws ecr get-login-password --region <ecr-region>` from a different machine where `aws` is installed. Then copy and paste it into this command: `echo "<paste-obtained-password-text>" | podman login --username AWS --password-stdin <registry>` - get `<registry>` from the URI from your ECR registry, in the example format of `9872397498329479394.dkr.ecr.us-east-2.amazonaws.com`. Then run `podman pull <your-ECR-image>` to load it locally on the CRC node. Exit the node and it will be possible to use your ECR image URL and tag for deployment (no need to use a pull secret here).

### Step 4-Option 1: Deploy using Helm

Using Helm to deploy offers more flexibility in terms of event broker deployment options, compared to those offered by OpenShift templates (see [Option 2](#step-4-option-2-deploy-using-openshift-templates).

Additional information is provided in the following documents:
* [Solace PubSub+ on Kubernetes Deployment Guide](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md)
* [Kubernetes Deployment Quick Start Guide](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/README.md)

The deployment is using PubSub+ Software Event Broker Helm charts and it is customized by overriding [default chart parameters](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/tree/master/pubsubplus#configuration).

* Consult the [Deployment Considerations](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#pubsub-event-broker-deployment-considerations) section of the general Event Broker in Kubernetes Documentation when planning your deployment.
* In particular, the `securityContext.enabled` parameter must be set to `false`, indicating not to use the provided pod security context but let OpenShift set it, using SecurityContextConstraints (SCC). By default OpenShift will use the "restricted" SCC.
* By default the publicly available [latest Docker image of PubSub+ Standard Edition](https://hub.Docker.com/r/solace/solace-pubsub-standard/tags/) will be used. Use a different image tag if required or [use an image from a different registry](#step-3-optional-using-a-private-image-registry). If using a different image, add the `image.repository=<your-image-location>,image.tag=<your-image-tag>` values to the `--set` commands below, comma-separated. Also specify a pull secret is required: `image.pullSecretName=<my-pullsecret>`
* The broker can be [vertically scaled](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#deployment-scaling ) using the `solace.size` chart parameter.

Procedure:
* Install Helm: use the [instructions from Helm](//github.com/helm/helm#install) or if using Linux simply run following. Helm is configured properly if the command `helm version` returns no error.
```bash
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
* See following examples:

_HA_ deployment example:
```bash
# One-time action: Add the PubSub+ charts to local Helm
helm repo add solacecharts https://solaceproducts.github.io/pubsubplus-kubernetes-quickstart/helm-charts
# Initiate the HA deployment - specify an admin password
helm install --name my-ha-release \
  --set securityContext.enabled=false,solace.redundancy=true,solace.usernameAdminPassword=<broker-admin-password> \
  solacecharts/pubsubplus
# Check the notes printed on screen
# Wait until all pods running and ready and the active event broker pod label is "active=true" 
oc get pods --show-labels -w
```

Single-node, _non-HA_ deployment example with _pull_ _secret_:
```bash
# One-time action: Add the PubSub+ charts to local Helm
helm repo add solacecharts https://solaceproducts.github.io/pubsubplus-kubernetes-quickstart/helm-charts
# Initiate the non-HA deployment - specify an admin password
helm install --name my-nonha-release \
  --set securityContext.enabled=false,solace.redundancy=true,solace.usernameAdminPassword=<broker-admin-password> \
  --set image.pullSecretName=<my-pullsecret> \
  solacecharts/pubsubplus
# Check the notes printed on screen
# Wait until the event broker pod is running, ready and the pod label is "active=true" 
oc get pods --show-labels -w
```

Note: as an alternative to longer `--set` parameters, it is possible to define same parameter values in a YAML file:
```yaml
# Create example values file - specify an admin password
echo "
securityContext
  enabled: false
solace
  redundancy: true,
  usernameAdminPassword: <broker-admin-password>" > deployment-values.yaml
# Use values file
helm install --name my-release \
  -v deployment-values.yaml \
  solacecharts/pubsubplus
```

### Step 4-Option 2: Deploy using OpenShift Templates

This deployment is using OpenShift templates and don't require Helm. It assumes [Step 2](#step-2-specify-an-openshift-project-for-deployment) and [optional step 3](#step-3-optional-using-a-private-image-registry) have been completed.

Pre-requisites and notes:
* Define a strong password for the 'admin' user of the event broker and then base64 encode the value.  This value will be specified as a parameter when processing the event broker OpenShift template:
```
echo -n 'strong@dminPw!' | base64
```
* DOCKER_REGISTRY_URL and EVENTBROKER_IMAGE_TAG default to `solace/solace-pubsub-standard` and `latest`.
* Determine your event broker [disk space requirements](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#disk-storage). `BROKER_STORAGE_SIZE` default is 30 gigabytes of disk space.
* The template by default provides for a broker supporting 100 connections. Adjust `export system_scaling_maxconnectioncount` in the template for higher scaling but ensure adequate resources are available to the pod(s) by adjusting both `cpu` and `memory` requests and limits. Refer to the [System Requirements in the Solace documentation](//docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/Scaling-Tier-Resources.htm).

Procedure:

* See following examples

Note: Default parameters can be omitted. Templates files can also be copied from GitHub location on local disk, edited and used from there.

Single-node, _non-HA_ deployment example with all default parameters:

```
oc process -f https://raw.githubusercontent.com/SolaceProducts/pubsubplus-openshift-quickstart/master/templates/eventbroker_singlenode_template.yaml \
    DEPLOYMENT_NAME=test-singlenode \
    BROKER_ADMIN_PASSWORD=<base64 encoded password> | oc create -f -
# Wait until all pods running and ready
oc get pods -w --show-labels
```

_HA_ deployment example with specifying all parameters:

```
oc process -f https://raw.githubusercontent.com/SolaceProducts/pubsubplus-openshift-quickstart/master/templates/eventbroker_ha_template.yaml \
    DEPLOYMENT_NAME=test-ha \
    BROKER_IMAGE_REGISTRY_URL=<replace with your Docker Registry URL> \
    BROKER_IMAGE_TAG=<replace with your Solace PubSub+ Docker image tag> \
    BROKER_IMAGE_REGISTRY_PULLSECRET=<my-pullsecret>
    BROKER_STORAGE_SIZE=30Gi \
    BROKER_ADMIN_PASSWORD=<base64 encoded password> | oc create -f -
# Wait until all pods running and ready
oc get pods -w --show-labels
```

  
## Validating the Deployment

If there are any issues with the deployment, refer to the [Kubernetes Troubleshooting Guide](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#troubleshooting) - substitute any `kubectl` commands with `oc` commands. Before retrying a deployment, ensure to delete PVCs remaining from the unsuccessful deployment - use `oc get pvc` to determine which ones.

Now you can validate your deployment from the console:

```
$ oc get statefulset,service,pods,pvc,pv --show-labels
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

> Note: there is no Load Balancer support if using CodeReady Containers and services shall be accessed through NodePorts instead. Use NodePort numbers together with CodeReady Containers' public IP address which can be obtained from the command `crc ip`.

### Viewing Bringup logs

To see the deployment events, navigate to:

* **OpenShift UI > (Your Project) > Applications > Stateful Sets > ((name)-pubsubplus) > Events**

You can access the log stack for individual event broker pods from the OpenShift UI, by navigating to:

* **OpenShift UI > (Your Project) > Applications > Stateful Sets > ((name)-pubsubplus) > Pods > ((name)-solace-(N)) > Logs**

![alt text](/docs/images/Solace-Pod-Log-Stack.png "Event Broker Pod Log Stack")

Where (N) above is the ordinal of the Solace PubSub+:
  * 0 - Primary event broker
  * 1 - Backup event broker
  * 2 - Monitor event broker

## Gaining Admin and SSH access to the event broker

The external management host URI will be the Solace Connection URI associated with the load balancer generated by the event broker OpenShift template.  Access will go through the load balancer service as described in the introduction and will always point to the active event broker. The default port is 22 for CLI and 8080 for SEMP/[Solace PubSub+ Broker Manager](https://docs.solace.com/Solace-PubSub-Manager/PubSub-Manager-Overview.htm).

If you deployed OpenShift in AWS, then the Solace OpenShift QuickStart will have created an EC2 Load Balancer to front the event broker / OpenShift service.  The Load Balancer public DNS name can be found in the AWS EC2 console under the 'Load Balancers' section.

To launch Solace CLI or SSH into the individual event broker instances from the OpenShift CLI use:

```
# CLI access
oc exec -it XXX-XXX-pubsubplus-X -- cli   # adjust pod name to your deployment
# shell access
oc exec -it XXX-XXX-pubsubplus-X -- bash  # adjust pod name to your deployment
```

You can also gain access to the Solace CLI and container shell for individual event broker instances from the OpenShift UI.  A web-based terminal emulator is available from the OpenShift UI.  Navigate to an individual event broker Pod using the OpenShift UI:

* **OpenShift UI > (Your Project) > Applications > Stateful Sets > ((name)-pubsubplus) > Pods > ((name)-pubsubplus-(N)) > Terminal**

Once you have launched the terminal emulator to the event broker pod you may access the Solace CLI by executing the following command:

```
/usr/sw/loads/currentload/bin/cli -A
```

![alt text](/docs/images/Solace-Primary-Pod-Terminal-CLI.png "Event Broker CLI via OpenShift UI Terminal emulator")

See the [Solace Kubernetes Quickstart README](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#gaining-admin-access-to-the-event-broker ) for more details including admin and SSH access to the individual event brokers.

## Testing data access to the event broker

To test data traffic though the newly created event broker instance, a simple option to use is the [SDKPerf tool](https://docs.solace.com/SDKPerf/SDKPerf.htm). Another option to quickly check messaging is [Try Me!](https://docs.solace.com/Solace-PubSub-Manager/PubSub-Manager-Overview.htm#Test-Messages), which is integrated into the [Solace PubSub+ Broker Manager](https://docs.solace.com/Solace-PubSub-Manager/PubSub-Manager-Overview.htm).

To try with building a client, visit the Solace Developer Portal and select your preferred programming language to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/ ). Under each language there is a Publish/Subscribe tutorial that will help you get started.

Note: the Host will be the Solace Connection URI. It may be necessary to [open up external access to a port](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#modifying-or-upgrading-a-deployment ) used by the particular messaging API if it is not already exposed.

![alt text](/docs/images/solace_tutorial.png "getting started publish/subscribe")

<br>

## Deleting a deployment

### Deleting the PubSub+ deployment

To delete the deployment or to start over from Step 6 in a clean state:

* If used (Option 1) Helm to deploy, execute: 

```
helm list   # will list the releases (deployments)
helm delete XXX-XXX  # will delete instances related to your deployment - "my-release" in the example above
```

* If used (Option 2) OpenShift templates to deploy, use:

```
oc process -f <template-used> DEPLOYMENT_NAME=<deploymentname> | oc delete -f -
```

**Note:** Above will not delete dynamic Persistent Volumes (PVs) and related Persistent Volume Claims (PVCs). If recreating the deployment with same name and keeping the original PVCs, the original volumes get mounted with existing configuration. Deleting the PVCs will also delete the PVs:

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

### Deleting the AWS OpenShift Container Platform deployment

To delete your OpenShift Container Platform deployment that was set up at Step 1:

```
cd ~/workspace
./openshift-install help # Check options
./openshift-install destroy cluster
./openshift-install destroy bootstrap
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

If using templates to deploy locate the volume mount for `softAdb` in the template and disable it by commenting it out:

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