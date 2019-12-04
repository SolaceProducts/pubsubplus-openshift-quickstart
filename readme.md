# Deploying a Solace PubSub+ Software Event Broker onto an OpenShift 3.11 platform

The [Solace PubSub+ Platform](https://solace.com/products/platform/)'s [PubSub+ Software Event Broker](https://solace.com/products/event-broker/software/) efficiently streams event-driven information between applications, IoT devices and user interfaces running in cloud, on-premise, and hybrid environments using open APIs and protocols like AMQP, JMS, MQTT, REST and WebSocket. It can be installed into a variety of public and private clouds, PaaS, and on-premise environments, and brokers in multiple locations can be linked together in an [Event Mesh](https://solace.com/what-is-an-event-mesh/) to dynamically share events across the distributed enterprise.

## Overview

This document provides a quick getting started guide to install a Solace PubSub+ Software Event Broker in various configurations onto an OpenShift 3.11 platform.

Detailed documentation is provided in the [Solace PubSub+ Event Broker on OpenShift Guide](/docs/PubSubPlusOpenShiftDeployment.md).

This guide is intended mainly for development and demo purposes. The recommended Solace PubSub+ Software Event Broker version is 9.4 or later.

## How to deploy the Solace PubSub+ Software Event Broker

Solace PubSub+ software event brokers can be deployed in either a 3-node High-Availability (HA) group, or as a single-node Standalone deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA deployment is required.

We recommend using the Helm tool for convenience. An alternative method [using OpenShift templates](/docs/PubSubPlusOpenShiftDeployment.md#step-6-option-2-deploy-the-event-broker-using-the-openshift-templates-included-in-this-project) is also available.

In this quick start we go through the steps to set up an event broker using [Solace PubSub+ Helm charts](//hub.helm.sh/charts/solace).

There are three Helm chart variants available with default small-size configurations:
1.	`pubsubplus-dev` - minimum footprint PubSub+ for Developers (Standalone)
2.	`pubsubplus` - PubSub+ Standalone, supporting 100 connections
3.	`pubsubplus-ha` - PubSub+ HA, supporting 100 connections

For other event broker configurations or sizes, refer to the [PubSub+ Helm Chart documentation](/pubsubplus/README.md).

### 1. Get an OpenShift environment

There are [multiple ways](https://docs.openshift.com/index.html ) to get to an OpenShift 3.11 platform, including [MiniShift](https://github.com/minishift/minishift#welcome-to-minishift ).

It may be necessary to log in using the `oc login` command. 

Check your OpenShift environment is ready:
```bash
# This shall return current user
oc whoami
```

### 2. Install and configure Helm

Note that Helm is transitioning from v2 to v3. Many deployments still use v2.

<details open=true><summary><b>Instructions for Helm v2 setup</b></summary>
<p>

- Use script to install the Helm v2 client first: 
> If using MiniShift, get the [Helm executable](https://storage.googleapis.com/kubernetes-helm/helm-v2.15.0-windows-amd64.zip ) and put it in a directory on your path before running the following script.
```bash
  wget https://raw.githubusercontent.com/SolaceProducts/solace-openshift-quickstart/master/scripts/deployHelm.sh; chmod +x deployHelm.sh
  ./deployHelm.sh client
  # Copy and run the export statements from the script output!
  # Example:
  #  export HELM_HOME=$HOME/.helm
  #  export TILLER_NAMESPACE=tiller
```
- Ensure to run the export statements.
- Install the Helm server-side "Tiller" component. This will also create a `tiller` project:
```bash
  ./deployHelm.sh server
```

</p>
</details>

<details><summary><b>Instructions for Helm v3 setup</b></summary>
<p>

- Use the [instructions from Helm] or if using Linux simply run:
```bash
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
</p>
</details>

Helm is configured properly if the command `helm version` returns no error.


### 3. Install the Solace PubSub+ event broker with default configuration

- Add the Solace Helm charts to your local Helm repo:
```bash
helm repo add solacecharts https://solacedev.github.io/solace-kubernetes-quickstart/helm-charts
```

- Create or switch to your project
```bash
oc new-project solace-pubsub
```

- By default the publicly available latest Docker image of PubSub+ Standard Edition will be used. [Load a different image into a registry](/docs/PubSubPlusOpenShiftDeployment.md#step-5-optional-load-the-event-broker-docker-image-to-your-docker-registry) if required.

- Use one of the chart variants to create a deployment. For configuration options and delete instructions, refer to the [PubSub+ Helm Chart documentation](https://github.com/SolaceDev/solace-kubernetes-quickstart/tree/HelmReorg/pubsubplus).

<details open=true><summary><b>Instructions using Helm v2</b></summary>
<p>

a) Create a Solace PubSub+ minimum deployment for development purposes using `pubsubplus-dev`. It requires minimum 1 CPU and 2 GB of memory available to the PubSub+ event broker pod.
```bash
# Deploy PubSub+ Standard edition, minimum footprint developer version
oc install --name my-release solacecharts/pubsubplus-dev
```

b) Create a Solace PubSub+ Standalone deployment, supporting 100 connections scaling using `pubsubplus`. Minimum 2 CPUs and 4 GB of memory must be available to the PubSub+ event broker pod.
```bash
# Deploy PubSub+ Standard edition, Standalone
oc install --name my-release solacecharts/pubsubplus
```

c) Create a Solace PubSub+ HA deployment, supporting 100 connections scaling using `pubsubplus-ha`. The minimum resource requirements are 2 CPU and 4 GB of memory available to each of the three PubSub+ event broker pods.
```bash
# Deploy PubSub+ Standard edition, HA
oc install --name my-release solacecharts/pubsubplus-ha
```
</p>
</details>

<details><summary><b>Instructions using Helm v3</b></summary>
<p>

a) Create a Solace PubSub+ minimum deployment for development purposes using `pubsubplus-dev`. It requires minimum 1 CPU and 2 GB of memory available to the PubSub+ event broker pod.
```bash
# Deploy PubSub+ Standard edition, minimum footprint developer version
oc install my-release solacecharts/pubsubplus-dev
```

b) Create a Solace PubSub+ Standalone deployment, supporting 100 connections scaling using `pubsubplus`. Minimum 2 CPUs and 4 GB of memory must be available to the PubSub+ event broker pod.
```bash
# Deploy PubSub+ Standard edition, Standalone
oc install my-release solacecharts/pubsubplus
```

c) Create a Solace PubSub+ HA deployment, supporting 100 connections scaling using `pubsubplus-ha`. The minimum resource requirements are 2 CPU and 4 GB of memory available to each of the three PubSub+ event broker pods.
```bash
# Deploy PubSub+ Standard edition, HA
oc install my-release solacecharts/pubsubplus-ha
```
</p>
</details>
Above options will start the deployment and write related information and notes to the screen.

Wait for the deployment to complete following the instructions, then you can [try out the management and messaging services](docs/PubSubPlusK8SDeployment.md#validating-the-deployment). Refer to the [Troubleshooting guide](docs/PubSubPlusK8SDeployment.md#troubleshooting) if any issues.

> Note: If using MiniShift an additional step is required to expose the service: `oc get --export svc my-release-pubsubplus`. This will return a service definition with nodePort port numbers for each message router service. Use these port numbers together with MiniShift's public IP address which can be obtained from the command `minishift ip`.


## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](//github.com/SolaceProducts/solace-kubernetes-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: //dev.solace.com
- Understanding [Solace technology.](//dev.solace.com/tech/)
- Ask the [Solace community](//dev.solace.com/community/).
