# Deploying a Solace PubSub+ Software Event Broker onto an OpenShift 4 platform

The [Solace PubSub+ Platform](https://solace.com/products/platform/)'s [software event broker](https://solace.com/products/event-broker/software/) efficiently streams event-driven information between applications, IoT devices and user interfaces running in the cloud, on-premises, and hybrid environments using open APIs and protocols like AMQP, JMS, MQTT, REST and WebSocket. It can be installed into a variety of public and private clouds, PaaS, and on-premises environments, and brokers in multiple locations can be linked together in an [event mesh](https://solace.com/what-is-an-event-mesh/) to dynamically share events across the distributed enterprise.

## Overview

This document provides a quick getting started guide to install a Solace PubSub+ Software Event Broker in various configurations onto an OpenShift 4 platform.

Detailed documentation is provided in the [Solace PubSub+ on OpenShift Documentation](/docs/PubSubPlusOpenShiftDeployment.md). There is also a general [Solace PubSub+ on Kubernetes Documentation](//github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md) available, which the OpenShift deployment  builds upon.

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

There are [multiple ways](https://www.openshift.com/try ) to get to an OpenShift 4 platform. The [detailed Event Broker on OpenShift Documentation](/docs/PubSubPlusOpenShiftDeployment.md#step-1-optional--aws-deploy-openshift-container-platform-onto-aws-using-the-redhat-openshift-aws-quickstart-project) describes how to set up a self-managed 60-day trial Red Hat OpenShift Container Platform on AWS. Another recommended option for developers is to use [CodeReady Containers](https://developers.redhat.com/products/codeready-containers/overview).

Assuming you have access to an OpenShift 4 platform, login as `kubeadmin` using the `oc login -u kubeadmin` command.

Check to ensure your OpenShift environment is ready:
```bash
# This shall return current user
oc whoami
```

### 2. Install and configure Helm

- Use the [instructions from Helm](//github.com/helm/helm#install) or if using Linux simply run:
```bash
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

Helm is configured properly if the command `helm version` returns no error.


### 3. Install Solace PubSub+ Software Event Broker with default configuration

- Add the Solace Helm charts to your local Helm repo:
```bash
  helm repo add solacecharts https://solaceproducts.github.io/pubsubplus-kubernetes-quickstart/helm-charts
```

- Create a new project or switch to your existing project (do not use the `default` project as it's loose permissions doesn't reflect a typical OpenShift environment)
```bash
  oc new-project solace-pubsub
```

- By default the public [latest Docker image of PubSub+ Standard Edition](https://hub.Docker.com/r/solace/solace-pubsub-standard/tags/) available from the DockerHub registry will be used. If using a different image, add the `image.repository=<your-image-location>,image.tag=<your-image-tag>` values to the `--set` commands below, comma-separated. Optionally also add `image.pullSecretName=<your-image-repo-pull-secret>` if required by the image repository.

- Use one of the chart variants to create a deployment. For configuration options and delete instructions, refer to the [PubSub+ Software Event Broker Helm Chart documentation](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/tree/master/pubsubplus#configuration).

a) Create a Solace PubSub+ minimum deployment for development purposes using `pubsubplus-dev`. It requires a minimum of 1 CPU and 3.4 GiB of memory be available to the PubSub+ event broker pod.
```bash
  # Deploy PubSub+ Standard edition, minimum footprint developer version
  helm install my-release solacecharts/pubsubplus-dev \
    --set securityContext.enabled=false
```

b) Create a Solace PubSub+ standalone deployment, supporting 100 connections scaling using `pubsubplus`. A minimum of 2 CPUs and 3.4 GiB of memory must be available to the PubSub+ pod.
```bash
  # Deploy PubSub+ Standard edition, standalone
  helm install my-release solacecharts/pubsubplus \
    --set securityContext.enabled=false
```

c) Create a Solace PubSub+ HA deployment, supporting 100 connections scaling using `pubsubplus-ha`. The minimum resource requirements are 2 CPU and 3.4 GiB of memory available to each of the three event broker pods.
```bash
  # Deploy PubSub+ Standard edition, HA
  helm install my-release solacecharts/pubsubplus-ha \
    --set securityContext.enabled=false
```
</p>
</details>

The above options will start the deployment and write related information and notes to the console.

Broker services are exposed by default through a Load Balancer that is specific to your OpenShift platform. For details check the `Services access` section of the notes.

Wait for the deployment to complete following the instructions, then you can [validate the deployment and try the management and messaging services](/docs/PubSubPlusOpenShiftDeployment.md#validating-the-deployment).
 
> Note: there is no Load Balancer support if using CodeReady Containers and services shall be accessed through NodePorts instead. Check the results of `oc get svc my-release-pubsubplus`. This will return the ephemeral nodePort port numbers for each message router service. Use these port numbers together with CodeReady Containers' public IP address which can be obtained from the command `crc ip`.

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
