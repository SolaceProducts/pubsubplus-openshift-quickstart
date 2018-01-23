# Install Solace Message Router HA deployment onto an OpenShift 3.6 cluster deployed on Amazon AWS

## Purpose of this repository

This repository expands on [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to provide a concrete example of how to deploy redundant Solace VMRs in an HA configuration on the OpenShift platform running in AWS.  We utilize the [RedHat OpenShift on AWS QuickStart](https://aws.amazon.com/quickstart/architecture/openshift/) project to deploy OpenShift on AWS in a highly redundant configuration spanning 3 zones.

![alt text](/resources/network_diagram.jpg "Network Diagram")

## Description of Solace VMR

Solace Virtual Message Router (VMR) software provides enterprise-grade messaging capabilities so you can easily enable event-driven communications between applications, IoT devices, microservices and mobile devices across hybrid cloud and multi cloud environments. The Solace VMR supports open APIs and standard protocols including AMQP 1.0, JMS, MQTT, REST and WebSocket, along with all message exchange patterns including publish/subscribe, request/reply, fan-in/fan-out, queueing, streaming and more. The Solace VMR can be deployed in all popular public cloud, private cloud and on-prem environments, and offers both feature parity and interoperability with Solace’s proven hardware appliances and Messaging as a Service offering called Solace Cloud.

## How to Deploy a VMR onto OpenShift / AWS

The following steps describe how to utilize the Solace OpenShift HA QuickStart project to deploy the Solace VMR software onto an OpenShift environment.  Additional optional steps are included if you are deploying OpenShift onto Amazon AWS infrastructure.  

There are two options for deploying the Solace VMR software onto your OpenShift deployment.
* Execute the OpenShift templates included in this project for installing the VMR software in a limited number of configurations 
* Use the Solace Kubernetes QuickStart project to deploy the Solace VMR software onto your OpenShift environment.  The Solace Kubernetes project utilizes Helm to automate the process of deploying the Solace VMR software using a wide range of configuration options.

Steps to deploy the Solace VMR software:

### Step 1 (Optional / AWS) Deploy OpenShift onto AWS using the RedHat OpenShift on AWS QuickStart Project

* (Part I) Log into the AWS Web Console and run the [OpenShift AWS QuickStart project](https://aws.amazon.com/quickstart/architecture/openshift/).  We recommend you deploy OpenShift across 3 AWS Availability Zones for maximum redundancy.  Please refer to the RedHat OpenShift AWS QuickStart guide and supporting documentation.
[Deploying and Managing OpenShift Container Platform 3.6 on Amazon Web Services](https://access.redhat.com/documentation/en-us/reference_architectures/2017/html-single/deploying_and_managing_openshift_container_platform_3.6_on_amazon_web_services/index)

* (Part II) Once you have deployed OpenShift using the AWS QuickStart you will have to perform additional steps to re-configure OpenShift to integrate fully with AWS.  Please refer to the RedHat OpenShift documentation for configuring OpenShift for AWS.
[OpenShift > Configuring for AWS](https://docs.openshift.com/container-platform/3.6/install_config/configuring_aws.html)

### Step 2: Retrieve the Solace OpenShift HA QuickStart project from GitHub
* The Solace OpenShift HA QuickStart project contains useful scripts to help you prepare an OpenShift project for deploying Solace VMR.  You should retrieve the project on a host having the OpenShift client tools and a host that can reach your OpenShift cluster nodes.
```
mkdir ~/workspace
cd ~/workspace
git clone https://github.com/SolaceDev/solace-openshift-quickstart.git
cd solace-openshift-quickstart
git checkout highavail
```

### Step 3: (Optional / AWS) If you are going to use the Solace Kubernetes Project to deploy the Solace VMR software onto your OpenShift deployment then you must deploy the Helm client and server-side tools:
* **(Part I)** Utilize the ‘deployHelm.sh’ script to deploy the Helm client and server-side components.  Begin by installing the Helm client tool:
```
cd ~/workspace/solace-openshift-quickstart/scripts
. ./installHelm.sh client
```

* After running the above script, take note of the values of the following environment variables and set their values in your .bashrc (These environment variables are used when running the helm client tool):
  * HELM_HOME
  * TILLER_NAMESPACE
  * PATH

* **(Part II)** Install the Helm server-side ‘Tiller’ component.
```
cd ~/workspace/solace-openshift-quickstart/scripts
. ./installHelm.sh server
```

### **Step 4:** Utilize scripts in the Solace OpenShift QuickStart to configure a project to host the VMR HA software:
* **(Part I)** Use the ‘prepareProject.sh’ script to create and configure an OpenShift project that meets requirements of the Solace VMR HA software:
```
cd ~/workspace/solace-openshift-quickstart/scripts
sudo ./prepareProject.sh vmrha
```
* **(Part II, Optional / AWS)** If you are using the AWS Elastic Container Registry (ECR) then you must add the ECR login credentials (as an OpenShift secret) to your VMR HA project.  This project contains a helper script to execute this step:
```
sudo su –
aws configure
exit
cd ~/workspace/solace-openshift-quickstart/scripts
sudo ./addECRsecret.sh vmrha
```

### **Step 5:** (Optional) If you require more flexibility in terms of Solace VMR deployment options (compared to those offered by templates in this project) then utilize the [Solace Kubernetes QuickStart project](https://github.com/SolaceProducts/solace-kubernetes-quickstart):
For now:
```
cd ~/workspace
git clone https://github.com/KenBarr/solace-kubernetes-quickstart.git
cd solace-kubernetes-quickstart
git checkout reliability
```
Should be:
```
cd ~/workspace
git clone https://github.com/SolaceProducts/solace-kubernetes-quickstart.git
cd solace-kubernetes-quickstart
```

### **Step 6:** Download and deploy Solace VMR software (Docker image) to a Docker Registry:
* **(Part I)** Download a copy of the Solace VMR Software.  Follow Step 2 from the [Solace Kubernetes QuickStart](https://github.com/SolaceProducts/solace-kubernetes-quickstart) to download the VMR software (Community Edition for single-node deployments, Evaluation Edition for VMR HA deployments)
* **(Part II)** Deploy the VMR docker image your Docker registry
```
docker load -i <Solace VMR tarball>
```
* Follow any necessary steps to deploy the VMR docker image to your Docker Registry

* **(Part II - Optional / AWS)** Utilize the AWS Elastic Container Registry to host your VMR docker image.  Deploy the VMR docker image to the AWS ECR registry.  You can launch the ECR management page from the AWS Console, search for ‘Elastic Container Service’, then select the ‘Repositories’ link on the left navigation pane.
[Amazon Elastic Container Registry](https://aws.amazon.com/ecr/)
  * **Note:** Ensure your ECR registry is created in the AWS Region where you have deployed your OpenShift environment.

### **Step 7:** Deploy the Solace VMR message router software 
* Deploy VMR software using the Solace OpenShift HA QuickStart templates:
  * Deploy VMR in a single-node configuration
  * Deploy VMR in a high-availability configuration
* **(Optional)** Deploy VMR software using the Solace Kubernetes QuickStart project
Update the Solace Kubernetes values.yaml configuration file for your target deployment (Please refer to the Solace Kubernetes QuickStart project for further details):
  * Configure the values.yaml file to deploy the Solace VMR software in either a single-node or Highly-Available configuration. 
```
cd ~/workspace/solace-kubernetes-quickstart/solace
vi values.yaml
helm install . -f values.yaml
```
  * The following table lists example values for the ‘values.yaml’ file to deploy Solace VMR in a Highly-Available configuration using persistent storage.

  |Variable                |Value                |Description                |
  |------------------------|---------------------|---------------------------|
  |cloudProvider           |aws                  |Set to 'aws' when deploying Solace VMR in an OpenShift / AWS environment|
  |solace / redundancy     |true                 |Set to ‘true’ for a Solace VMR HA configuration|
  |image / repository      |ECR repository URI   |Retrieve the repository URI from the AWS ECR management page  |
  |image / tag             |VMR docker image tag |Select your repository in the AWS ECR management page.  This page will list all available Docker images in the repository and their associated Image Tag|
  |storage / persistent    |true                 |Set to ‘true’ to configure persistent disks to store Solace VMR data|
  |storage / type          |standard             |Set to ‘standard’ to use lower-cost / standard performance disk types (AWS GP2)|
  |storage / size          |30Gi                 |Set to the minimum number of gigabytes for VMR data storage.  Refer to Solace VMR documentation for further details.|

## Gaining admin and ssh access to the VMR

The external management IP will be the Public IP associated with Load Balancer generated by the Solace VMR OpenShift template.  Access will go through the load balancer service as described in the introduction and will always point to the active VMR. The default port is 22 for CLI and 8080 for SEMP/SolAdmin.

If you deployed OpenShift in AWS then the Solace OpenShift QuickStart will have created an EC2 Load Balancer to front the Solace VMR / OpenShift service.  The Load Balancer public DNS name can be found in the AWS EC2 console under the 'Load Balancers' section.

You can gain access to the Solace VMR CLI and container shell for individual VMR instances from the OpenShift UI.  A web-based Terminal emulator is available from the OpenShift UI.  Navigate to an invidual Solace VMR Pod using the OpenShift UI:
* **OpenShift UI > (VMR Project) > Applications > Stateful Sets > ((name)-solace) > Pods > ((name)-solace-(N))**

Where (N) above is the ordinal of the Solace VMR:
  * 0 - Primary VMR
  * 1 - Backup VMR
  * 2 - Monitor VMR

Once you have launched the Terminal emulator to the Solace VMR pod you may access the Solace VMR CLI by executing the following command:
```
/usr/sw/loads/currentload/bin/cli -A
```

See the [Solace Kubernetes Quickstart README](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#gaining-admin-access-to-the-vmr ) for more details including admin and ssh access to the individual VMRs.

## Testing Data access to the VMR

To test data traffic though the newly created VMR instance, visit the Solace developer portal and select your preferred programming language to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/ ). Under each language there is a Publish/Subscribe tutorial that will help you get started.

Note: the Host will be the Public IP. It may be necessary to [open up external access to a port](https://github.com/SolaceProducts/solace-kubernetes-quickstart/tree/master#upgradingmodifying-the-vmr-cluster) used by the particular messaging API if it is not already exposed.

![alt text](/resources/solace_tutorial.png "getting started publish/subscribe")

<br>

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