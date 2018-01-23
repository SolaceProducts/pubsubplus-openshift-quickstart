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

### Step 1 (Optional) Deploy OpenShift onto AWS using the RedHat OpenShift on AWS QuickStart Project

* (Part I) Log into the AWS Web Console and run the [OpenShift AWS QuickStart project](https://aws.amazon.com/quickstart/architecture/openshift/).  We recommend you deploy OpenShift across 3 AWS Availability Zones for maximum redundancy.  Please refer to the RedHat OpenShift AWS QuickStart guide and supporting documentation.
[Deploying and Managing OpenShift Container Platform 3.6 on Amazon Web Services](https://access.redhat.com/documentation/en-us/reference_architectures/2017/html-single/deploying_and_managing_openshift_container_platform_3.6_on_amazon_web_services/index)

* (Part II) Once you have deployed OpenShift using the AWS QuickStart you will have to perform additional steps to re-configure OpenShift to integrate fully with AWS.  Please refer to the RedHat OpenShift documentation for configuring OpenShift for AWS.
[OpenShift > Configuring for AWS](https://docs.openshift.com/container-platform/3.6/install_config/configuring_aws.html)

