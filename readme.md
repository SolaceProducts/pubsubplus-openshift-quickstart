# Deploying a Solace PubSub+ Software Message Broker HA Group onto Red Hat OpenShift Container Platform 3.7 or 3.9

## Purpose of this Repository

This repository provides an example of how to deploy Solace PubSub+ software message brokers onto an OpenShift 3.7 or 3.9 platform. There are [multiple ways](https://docs.openshift.com/index.html ) to get to an OpenShift platform, including [MiniShift](https://github.com/minishift/minishift#welcome-to-minishift ). This guide will specifically use the Red Hat OpenShift Container Platform 3.7 or 3.9 but concepts are transferable to other compatible platforms.

We utilize the [RedHat OpenShift on AWS QuickStart](https://aws.amazon.com/quickstart/architecture/openshift/) project to deploy a Red Hat OpenShift Container Platform on AWS in a highly redundant configuration, spanning 3 zones.

This repository expands on the [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to provide an example of how to deploy Solace PubSub+ software message brokers in an HA configuration on the OpenShift Container Platform running in AWS.

**TODO: add hints how to set up non-HA for developers** 

![alt text](/resources/network_diagram.jpg "Network Diagram")

## Description of the Solace PubSub+ Software Message Broker

The Solace PubSub+ software message broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The message broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. As well, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## How to deploy a message broker onto OpenShift / AWS

The following steps describe how to deploy a message broker onto an OpenShift environment. Optional steps are provided about setting up a Red Hat OpenShift Container Platform on Amazon AWS infrastructure and if you use AWS Elastic Container Registry to host the Solace message broker Docker image - these are marked as (Optional / AWS).

There are also two options for deploying a message broker onto your OpenShift deployment.
* (Option 1): Execute the OpenShift templates included in this project for installing the message broker in a limited number of configurations 
* (Option 2): Use the Solace Kubernetes QuickStart to deploy the message broker onto your OpenShift environment.  The Solace Kubernetes QuickStart uses Helm to automate the process of message broker deployment through a wide range of configuration options and provides in-service upgrade of the message broker.

Steps to deploy the message broker:

**Note:** You may skip Step 1 if you already have your own OpenShift environment deployed.

### Step 1: (Optional / AWS) Deploy OpenShift Container Platform onto AWS using the RedHat OpenShift AWS QuickStart Project

* (Part I) Log into the AWS Web Console and run the [OpenShift AWS QuickStart project](https://aws.amazon.com/quickstart/architecture/openshift/).  We recommend you deploy OpenShift across 3 AWS Availability Zones for maximum redundancy.  Please refer to the RedHat OpenShift AWS QuickStart guide and supporting documentation:

  * [Deploying and Managing OpenShift Container Platform 3.7 on Amazon Web Services](https://access.redhat.com/documentation/en-us/reference_architectures/2017/html-single/deploying_and_managing_openshift_container_platform_3.7_on_amazon_web_services/index)
  
  **Important:** As described in above documentation, this deployment requires a Red Hat account with a valid Red Hat subscription to OpenShift and will consume 10 OpenShift entitlements in a maximum redundancy configuration. When no longer needed ensure to follow the steps in the [Deleting the OpenShift Container Platform deployment](#deleting-the-openshift-container-platform-deployment ) section of this guide to free up the entitlements.
  
  * **IAM policies required**

* (Part II) Once you have deployed OpenShift using the AWS QuickStart you will have to perform additional steps to re-configure OpenShift to integrate fully with AWS.  For full details please refer to the RedHat OpenShift documentation for configuring OpenShift for AWS:

  * [OpenShift > Configuring for AWS](https://docs.openshift.com/container-platform/3.7/install_config/configuring_aws.html)
  
  This quick start provides a script to automate the execution of the required steps:
  
   * Add the required AWS IAM policies to the ‘Setup Role’ (IAM) used by the RedHat QuickStart to deploy OpenShift to AWS
   
   * Tag public subnets so when creating a public service suitable public subnets can be found
   
   * Re-configure OpenShift Masters and OpenShift Nodes to make OpenShift aware of AWS deployment specifics
   
  To run the script, [ssh into the `ansible-configserver` EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html ).
   


### Step 2: Retrieve the Solace OpenShift QuickStart from GitHub
* The Solace OpenShift QuickStart project contains useful scripts to help you prepare an OpenShift project for message broker deployment.  You should retrieve the project on a host having the OpenShift client tools and a host that can reach your OpenShift cluster nodes.
```
mkdir ~/workspace
cd ~/workspace
git clone https://github.com/SolaceProducts/solace-openshift-quickstart.git
cd solace-openshift-quickstart
```

### Step 3: (Optional) Install the Helm client and server-side tools if you are going to use the Solace Kubernetes QuickStart to deploy the message broker
* **(Part I)** Use the ‘deployHelm.sh’ script to deploy the Helm client and server-side components.  Begin by installing the Helm client tool:
```
cd ~/workspace/solace-openshift-quickstart/scripts
. ./deployHelm.sh client
```

* After running the above script, note the values of the following environment variables and set their values in .bashrc (These environment variables are used when running the helm client tool):
  * HELM_HOME
  * TILLER_NAMESPACE
  * PATH

* **(Part II)** Install the Helm server-side ‘Tiller’ component.  Note, you will be prompted to log into OpenShift if you have not already done so.
```
cd ~/workspace/solace-openshift-quickstart/scripts
. ./deployHelm.sh server
```

### Step 4: Use scripts in the Solace OpenShift QuickStart to configure a project to host the message broker HA deployment.
* **(Part I)** Use the ‘prepareProject.sh’ script to create and configure an OpenShift project that meets requirements of the message broker HA deployment:
```
cd ~/workspace/solace-openshift-quickstart/scripts
sudo ./prepareProject.sh vmrha
```
* **(Part II, Optional / AWS)** If you are using the AWS Elastic Container Registry (ECR) then you must add the ECR login credentials (as an OpenShift secret) to your message broker HA deployment.  This project contains a helper script to execute this step:
```
sudo su –
aws configure
exit
cd ~/workspace/solace-openshift-quickstart/scripts
sudo ./addECRsecret.sh vmrha
```

### Step 5: Download and deploy the message broker (Docker image) to your Docker Registry

* **(Part I)** Download a copy of the message broker.  Follow Step 2 from the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to download the message broker.

* **(Part II)** Deploy the message broker docker image to your Docker registry of choice

  * **(Optional / AWS)** You can utilize the AWS Elastic Container Registry to host the VMR Docker image. For more information, refer to [Amazon Elastic Container Registry](https://aws.amazon.com/ecr/).

### Step 6: (Option 1) Deploy the message broker using the OpenShift templates included in this project

**Prerequisites:**
1. Determine your message broker disk space requirements.  We recommend a minimum of 30 gigabytes of disk space.
2. Define a strong password for the 'admin' user and then base64 encode the value.  This value will be specified as a parameter when processing the message broker OpenShift template:
```
echo -n 'strong@dminPw!' | base64
```

**Deploy the message broker:**

You can deploy the message broker in either a single-node or high-availability configuration:

* For a **Single-Node** configuration:
  * Process the Solace 'Single Node' OpenShift template to deploy the message broker in a single-node configuration.  Specify values for the DOCKER_REGISTRY_URL, VMR_IMAGE_TAG, VMR_STORAGE_SIZE, and VMR_ADMIN_PASSWORD parameters:
```
oc project vmrha
cd  ~/workspace/solace-openshift-quickstart/templates
oc process -f vmr_singleNode_template.yaml DEPLOYMENT_NAME=single-node-vmr DOCKER_REGISTRY_URL=<replace with your Docker Registry URL> VMR_IMAGE_TAG=<replace with your Solace VMR docker image tag> VMR_STORAGE_SIZE=30Gi VMR_ADMIN_PASSWORD=<base64 encoded password> | oc create -f -
```

* For a **High-Availability** configuration:
  * Process the Solace 'HA' OpenShift template to deploy the message broker in a high-availability configuration.  Specify values for the DOCKER_REGISTRY_URL, VMR_IMAGE_TAG, VMR_STORAGE_SIZE, and VMR_ADMIN_PASSWORD parameters:
```
oc project vmrha
cd  ~/workspace/solace-openshift-quickstart/templates
oc process -f vmr_ha_template.yaml DEPLOYMENT_NAME=vmr-ha DOCKER_REGISTRY_URL=<replace with your Docker Registry URL> VMR_IMAGE_TAG=<replace with your Solace VMR docker image tag> VMR_STORAGE_SIZE=30Gi VMR_ADMIN_PASSWORD=<base64 encoded password> | oc create -f -
```    

### Step 6: (Option 2) Deploy the message broker using the Solace Kubernetes QuickStart

If you require more flexibility in terms of message broker deployment options (compared to those offered by the OpenShift templates provided by this project) then use the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to deploy the message broker:

* Retrieve the Solace Kubernetes QuickStart from GitHub:

```
cd ~/workspace
git clone https://github.com/SolaceProducts/solace-kubernetes-quickstart.git
cd solace-kubernetes-quickstart
```

* Update the Solace Kubernetes values.yaml configuration file for your target deployment (Please refer to the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) for further details):

```
oc project vmrha
cd ~/workspace/solace-kubernetes-quickstart/solace
vi values.yaml
helm install . -f values.yaml
```
* The following table lists example values for the ‘values.yaml’ file to deploy a message broker in a Highly-Available configuration using persistent storage.

  |Variable                |Value                |Description                |
  |------------------------|---------------------|---------------------------|
  |cloudProvider           |aws                  |Set to 'aws' when deploying a message broker in an OpenShift / AWS environment|
  |solace / redundancy     |true                 |Set to ‘true’ for a message broker HA configuration|
  |image / repository      |ECR repository URI   |Retrieve the repository URI from the AWS ECR management page  |
  |image / tag             |VMR docker image tag |Select your repository in the AWS ECR management page.  This page will list all available Docker images in the repository and their associated Image Tag|
  |storage / persistent    |true                 |Set to ‘true’ to configure persistent disks to store message broker data|
  |storage / type          |standard             |Set to ‘standard’ to use lower-cost / standard performance disk types (AWS GP2)|
  |storage / size          |30Gi                 |Set to the minimum number of gigabytes for VMR data storage.  Refer to message broker documentation for further details.|

## Validating the Deployment

Now you can validate your deployment from the OpenShift client shell:
```
[ec2-user@ip-10-0-23-198 ~]$ oc get statefulset,service,pods,pvc,pv
NAME                                   DESIRED   CURRENT   AGE
statefulsets/oppulent-catfish-solace   3         3         17m

NAME                                    CLUSTER-IP       EXTERNAL-IP        PORT(S)                                                                                                                   AGE
svc/oppulent-catfish-solace             172.30.146.232   af12bcd7b0098...   22:31437/TCP,1883:32259/TCP,5672:32020/TCP,8000:31829/TCP,8080:32479/TCP,9000:32726/TCP,55003:31871/TCP,55555:30659/TCP   17m
svc/oppulent-catfish-solace-discovery   None             <none>             8080/TCP                                                                                                                  17m

NAME                           READY     STATUS    RESTARTS   AGE
po/oppulent-catfish-solace-0   1/1       Running   0          17m
po/oppulent-catfish-solace-1   1/1       Running   0          16m
po/oppulent-catfish-solace-2   1/1       Running   0          15m

NAME                                 STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS                AGE
pvc/data-oppulent-catfish-solace-0   Bound     pvc-f12f15c0-0098-11e8-8ed4-02a152ed1b12   30Gi       RWO           oppulent-catfish-standard   17m
pvc/data-oppulent-catfish-solace-1   Bound     pvc-0fa5577e-0099-11e8-8ed4-02a152ed1b12   30Gi       RWO           oppulent-catfish-standard   16m
pvc/data-oppulent-catfish-solace-2   Bound     pvc-2e1daed6-0099-11e8-8ed4-02a152ed1b12   30Gi       RWO           oppulent-catfish-standard   15m

NAME                                          CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                                  STORAGECLASS                REASON    AGE
pv/pvc-0fa5577e-0099-11e8-8ed4-02a152ed1b12   30Gi       RWO           Delete          Bound     vmrha/data-oppulent-catfish-solace-1   oppulent-catfish-standard             16m
pv/pvc-2e1daed6-0099-11e8-8ed4-02a152ed1b12   30Gi       RWO           Delete          Bound     vmrha/data-oppulent-catfish-solace-2   oppulent-catfish-standard             15m
pv/pvc-f12f15c0-0098-11e8-8ed4-02a152ed1b12   30Gi       RWO           Delete          Bound     vmrha/data-oppulent-catfish-solace-0   oppulent-catfish-standard             17m
[ec2-user@ip-10-0-23-198 ~]$
[ec2-user@ip-10-0-23-198 ~]$
[ec2-user@ip-10-0-23-198 ~]$ oc describe svc
Name:                   oppulent-catfish-solace
Namespace:              vmrha
Labels:                 app=solace
                        chart=solace-0.2.0
                        heritage=Tiller
                        release=oppulent-catfish
Annotations:            <none>
Selector:               active=true,app=solace,release=oppulent-catfish
Type:                   LoadBalancer
IP:                     172.30.146.232
LoadBalancer Ingress:   af12bcd7b009811e8a44106dd6bcb75d-1520996963.us-east-2.elb.amazonaws.com
Port:                   ssh     22/TCP
NodePort:               ssh     31437/TCP
Endpoints:              10.128.4.8:22
Port:                   mqtt    1883/TCP
NodePort:               mqtt    32259/TCP
Endpoints:              10.128.4.8:1883
Port:                   amqp    5672/TCP
NodePort:               amqp    32020/TCP
Endpoints:              10.128.4.8:5672
Port:                   mqttws  8000/TCP
NodePort:               mqttws  31829/TCP
Endpoints:              10.128.4.8:8000
Port:                   semp    8080/TCP
NodePort:               semp    32479/TCP
Endpoints:              10.128.4.8:8080
Port:                   rest    9000/TCP
NodePort:               rest    32726/TCP
Endpoints:              10.128.4.8:9000
Port:                   smfc    55003/TCP
NodePort:               smfc    31871/TCP
Endpoints:              10.128.4.8:55003
Port:                   smf     55555/TCP
NodePort:               smf     30659/TCP
Endpoints:              10.128.4.8:55555
Session Affinity:       None
Events:
  FirstSeen     LastSeen        Count   From                    SubObjectPath   Type            Reason                  Message
  ---------     --------        -----   ----                    -------------   --------        ------                  -------
  17m           17m             1       service-controller                      Normal          CreatingLoadBalancer    Creating load balancer
  17m           17m             1       service-controller                      Normal          CreatedLoadBalancer     Created load balancer


Name:                   oppulent-catfish-solace-discovery
Namespace:              vmrha
Labels:                 app=solace
                        chart=solace-0.2.0
                        heritage=Tiller
                        release=oppulent-catfish
Annotations:            service.alpha.kubernetes.io/tolerate-unready-endpoints=true
Selector:               app=solace,release=oppulent-catfish
Type:                   ClusterIP
IP:                     None
Port:                   semp    8080/TCP
Endpoints:              10.128.4.8:8080,10.130.2.4:8080,10.131.2.4:8080
Session Affinity:       None
Events:                 <none>
```

Note, the **'LoadBalancer Ingress'** value listed in the service description above.  This is the Solace Connection URL for messaging clients (AWS Load Balancer example).  

### Viewing bringup logs

It is possible to watch the message broker come up via logs in the OpenShift UI log stack for individual message broker pods.  You can access the log stack for individual message broker pods from the OpenShift UI, by navigating to:

* **OpenShift UI > (VMR Project) > Applications > Stateful Sets > ((name)-solace) > Pods > ((name)-solace-(N)) > Logs**

![alt text](/resources/VMR-Pod-Log-Stack.png "VMR Pod Log Stack")

## Gaining admin and ssh access to the message broker

The external management IP will be the Public IP associated with the load balancer generated by the message broker OpenShift template.  Access will go through the load balancer service as described in the introduction and will always point to the active message broker. The default port is 22 for CLI and 8080 for SEMP/SolAdmin.

If you deployed OpenShift in AWS, then the Solace OpenShift QuickStart will have created an EC2 Load Balancer to front the message broker / OpenShift service.  The Load Balancer public DNS name can be found in the AWS EC2 console under the 'Load Balancers' section.

You can gain access to the Solace CLI and container shell for individual message broker instances from the OpenShift UI.  A web-based terminal emulator is available from the OpenShift UI.  Navigate to an individual message broker Pod using the OpenShift UI:

* **OpenShift UI > (VMR Project) > Applications > Stateful Sets > ((name)-solace) > Pods > ((name)-solace-(N)) > Terminal**

Where (N) above is the ordinal of the Solace VMR:
  * 0 - Primary message broker
  * 1 - Backup message broker
  * 2 - Monitor message broker

Once you have launched the terminal emulator to the message broker pod you may access the Solace CLI by executing the following command:
```
/usr/sw/loads/currentload/bin/cli -A
```

![alt text](/resources/VMR-Primary-Pod-Terminal-VMR-CLI.png "VMR CLI via OpenShift UI Terminal emulator")

See the [Solace Kubernetes Quickstart README](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#gaining-admin-access-to-the-vmr ) for more details including admin and ssh access to the individual message brokers.

## Testing data access to the message broker

To test data traffic though the newly created message broker instance, visit the Solace Developer Portal and select your preferred programming language to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/ ). Under each language there is a Publish/Subscribe tutorial that will help you get started.

Note: the Host will be the Public IP. It may be necessary to [open up external access to a port](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#upgradingmodifying-the-vmr-cluster) used by the particular messaging API if it is not already exposed.

![alt text](/resources/solace_tutorial.png "getting started publish/subscribe")

<br>

## Deleting a deployment

### Deleting the Solace message broker deployment

### Deleting the OpenShift Container Platform deployment

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceProducts/solace-openshift-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

* The Solace Developer Portal website at: http://dev.solace.com
* Understanding [Solace technology.](http://dev.solace.com/tech/)
* Ask the [Solace community](http://dev.solace.com/community/).