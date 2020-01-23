# Deploying a Solace PubSub+ Software Event Broker onto an OpenShift 3.11 platform

The [Solace PubSub+ Platform](https://solace.com/products/platform/)'s [software event broker](https://solace.com/products/event-broker/software/) efficiently streams event-driven information between applications, IoT devices and user interfaces running in the cloud, on-premises, and hybrid environments using open APIs and protocols like AMQP, JMS, MQTT, REST and WebSocket. It can be installed into a variety of public and private clouds, PaaS, and on-premises environments, and brokers in multiple locations can be linked together in an [event mesh](https://solace.com/what-is-an-event-mesh/) to dynamically share events across the distributed enterprise.

## Overview

This document provides a quick getting started guide to install a Solace PubSub+ Software Event Broker in various configurations onto an OpenShift 3.11 platform.

Detailed OpenShift-specific documentation is provided in the [Solace PubSub+ on OpenShift Documentation](/docs/PubSubPlusOpenShiftDeployment.md). There is also a general [Solace PubSub+ on Kubernetes Documentation](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md) available, which the OpenShift deployment  builds upon.

This guide is intended mainly for development and demo purposes. The recommended Solace PubSub+ Software Event Broker version is 9.4 or later.

The PubSub+ deployment does not require any special OpenShift Security Context, the default "restricted" SCC can be used.

We recommend using the Helm tool for convenience. An alternative method [using OpenShift templates](/docs/PubSubPlusOpenShiftDeployment.md#step-6-option-2-deploy-the-event-broker-using-the-openshift-templates-included-in-this-project) is also available.

## How to deploy Solace PubSub+ Software Event Broker

The event broker can be deployed in either a 3-node High-Availability (HA) group, or as a single-node standalone deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA deployment is required.

In this quick start we go through the steps to set up an event broker using [Solace PubSub+ Helm charts](//hub.helm.sh/charts/solace).

There are three Helm chart variants available with default small-size configurations:
1.	`pubsubplus-dev` - minimum footprint PubSub+ for Developers (standalone)
2.	`pubsubplus` - PubSub+ standalone, supporting 100 connections
3.	`pubsubplus-ha` - PubSub+ HA, supporting 100 connections

For other event broker configurations or sizes, refer to the [PubSub+ Software Event Broker Helm Chart documentation](/pubsubplus/README.md).

### 1. Get an OpenShift environment

There are [multiple ways](https://docs.openshift.com/index.html ) to get to an OpenShift 3.11 platform, including [MiniShift](https://github.com/minishift/minishift#welcome-to-minishift ). The [detailed Event Broker on OpenShift Documentation](/docs/PubSubPlusOpenShiftDeployment.md#step-1-optional--aws-deploy-openshift-container-platform-onto-aws-using-the-redhat-openshift-aws-quickstart-project) describes how to set up a production-ready Red Hat OpenShift Container Platform platform on AWS.

Log in as `admin` using the `oc login -u admin` command. 

Check to ensure your OpenShift environment is ready:
```bash
# This shall return current user
oc whoami
```

### 2. Install and configure Helm

Note that Helm is transitioning from v2 to v3. Many deployments still use v2. PubSub+ can be deployed using either version, however concurrent use of v2 and v3 from the same command-line environment is not supported. Also note that there is a known [issue with using Helm v3 with OpenShift objects](https://bugzilla.redhat.com/show_bug.cgi?id=1773682) and until resolved Helm v2 is recommended.

<details open=true><summary><b>Instructions for Helm v2 setup</b></summary>
<p>

- First download the Helm v2 client. If using Windows, get the [Helm executable](https://storage.googleapis.com/kubernetes-helm/helm-v2.16.0-windows-amd64.zip ) and put it in a directory on your path.
```bash
  # Download Helm v2 client, latest version if needed
  curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash
```

- Use script to install the Helm v2 client and its Tiller server-side operator. This will deploy Tiller in a dedicated project. Do not use this project for your deployments.
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

</p>
</details>

<details><summary><b>Instructions for Helm v3 setup</b></summary>
<p>

- Use the [instructions from Helm](//github.com/helm/helm#install) or if using Linux simply run:
```bash
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
</p>
</details>

Helm is configured properly if the command `helm version` returns no error.


### 3. Install Solace PubSub+ Software Event Broker with default configuration

- Add the Solace Helm charts to your local Helm repo:
```bash
  helm repo add solacecharts https://solaceproducts.github.io/pubsubplus-kubernetes-quickstart/helm-charts
```

- By default the publicly available [latest Docker image of PubSub+ Standard Edition](https://hub.Docker.com/r/solace/solace-pubsub-standard/tags/) will be used. [Load a different image into a registry](/docs/PubSubPlusOpenShiftDeployment.md#step-5-optional-load-the-event-broker-docker-image-to-your-docker-registry) if required. If using a different image, add the `image.repository=<your-image-location>,image.tag=<your-image-tag>` values to the `--set` commands below, comma-separated.

- Create or switch to your project
```bash
  oc new-project solace-pubsub
```

<details open=true><summary><b>Instructions using Helm v2</b></summary>
<p>

- **Important**: For each new project using Helm v2, grant admin access to the server-side Tiller service from the "tiller-project" and set the TILLER_NAMESPACE environment.
```bash
  oc policy add-role-to-user admin "system:serviceaccount:tiller-project:tiller"
  # if not already exported, ensure Helm knows where Tiller was deployed
  export TILLER_NAMESPACE=tiller-project
```
> Ensure each command-line session has the TILLER_NAMESPACE environment variable properly set!

- Use one of the chart variants to create a deployment. For configuration options and delete instructions, refer to the [PubSub+ Software Event Broker Helm Chart documentation](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/tree/HelmReorg/pubsubplus).

a) Create a Solace PubSub+ minimum deployment for development purposes using `pubsubplus-dev`. It requires a minimum of 1 CPU and 2 GB of memory be available to the PubSub+ pod.
```bash
  # Deploy PubSub+ Standard edition, minimum footprint developer version
  helm install --name my-release solacecharts/pubsubplus-dev \
    --set securityContext.enabled=false
```

b) Create a Solace PubSub+ standalone deployment, supporting 100 connections scaling using `pubsubplus`. A minimum of 2 CPUs and 4 GB of memory must be available to the PubSub+ pod.
```bash
  # Deploy PubSub+ Standard edition, standalone
  helm install --name my-release solacecharts/pubsubplus \
    --set securityContext.enabled=false
```

c) Create a Solace PubSub+ HA deployment, supporting 100 connections scaling using `pubsubplus-ha`. The minimum resource requirements are 2 CPU and 4 GB of memory available to each of the three PubSub+ pods.
```bash
  # Deploy PubSub+ Standard edition, HA
  helm install --name my-release solacecharts/pubsubplus-ha \
    --set securityContext.enabled=false
```
</p>
</details>

<details><summary><b>Instructions using Helm v3</b></summary>
<p>

- Use one of the chart variants to create a deployment. For configuration options and delete instructions, refer to the [PubSub+ Software Event Broker Helm Chart documentation](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/tree/HelmReorg/pubsubplus).

a) Create a Solace PubSub+ minimum deployment for development purposes using `pubsubplus-dev`. It requires minimum 1 CPU and 2 GB of memory available to the PubSub+ event broker pod.
```bash
  # Deploy PubSub+ Standard edition, minimum footprint developer version
  helm install my-release solacecharts/pubsubplus-dev \
    --set securityContext.enabled=false
```

b) Create a Solace PubSub+ standalone deployment, supporting 100 connections scaling using `pubsubplus`. A minimum of 2 CPUs and 4 GB of memory must be available to the PubSub+ pod.
```bash
  # Deploy PubSub+ Standard edition, standalone
  helm install my-release solacecharts/pubsubplus \
    --set securityContext.enabled=false
```

c) Create a Solace PubSub+ HA deployment, supporting 100 connections scaling using `pubsubplus-ha`. The minimum resource requirements are 2 CPU and 4 GB of memory available to each of the three event broker pods.
```bash
  # Deploy PubSub+ Standard edition, HA
  helm install my-release solacecharts/pubsubplus-ha \
    --set securityContext.enabled=false
```
</p>
</details>

The above options will start the deployment and write related information and notes to the screen.

> Note: If using MiniShift an additional step is required to expose the service: `oc get --export svc my-release-pubsubplus`. This will return a service definition with nodePort port numbers for each message router service. Use these port numbers together with MiniShift's public IP address which can be obtained from the command `minishift ip`.

Wait for the deployment to complete following the instructions, then you can [validate the deployment and try the management and messaging services](/docs/PubSubPlusOpenShiftDeployment.md#validating-the-deployment).

If any issues, refer to the [Troubleshooting](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#troubleshooting) section of the general PubSub+ Kubernetes Documentation - substitute any `kubectl` commands with `oc` commands.

If you need to start over, follow the [steps to delete the current deployment](/docs/PubSubPlusOpenShiftDeployment.md#deleting-the-pubsub-event-broker-deployment).


## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](//github.com/SolaceProducts/solace-kubernetes-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: [solace.dev](//solace.dev/)
- Understanding [Solace technology](//solace.com/products/platform/)
- Ask the [Solace community](//dev.solace.com/community/).
