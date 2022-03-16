[![Actions Status](https://github.com/SolaceProducts/pubsubplus-openshift-quickstart/workflows/build/badge.svg?branch=master)](https://github.com/SolaceProducts/pubsubplus-openshift-quickstart/actions?query=workflow%3Abuild+branch%3Amaster)


# Deploying a Solace PubSub+ Software Event Broker onto an OpenShift 4 Platform

Solace [PubSub+ Platform](https://solace.com/products/platform/) is a complete event streaming and management platform for the real-time enterprise. The [PubSub+ software event broker](https://solace.com/products/event-broker/software/) efficiently streams event-driven information between applications, IoT devices, and user interfaces running in the cloud, on-premises, and in hybrid environments using open APIs and protocols like AMQP, JMS, MQTT, REST and WebSocket. It can be installed into a variety of public and private clouds, PaaS, and on-premises environments. Event brokers in multiple locations can be linked together in an [event mesh](https://solace.com/what-is-an-event-mesh/) to dynamically share events across the distributed enterprise.

## Overview

This project is a best practice template intended for development and demo purposes. It has been tested using OpenShift v4.9. The tested and recommended Solace PubSub+ Software Event Broker version is 9.12.

This document provides a quick getting started guide to install a Solace PubSub+ Software Event Broker in various configurations onto an OpenShift 4 platform. For OpenShift 3.11, refer to the [archived version of this quick start](https://github.com/SolaceProducts/pubsubplus-openshift-quickstart/tree/v1.1.1).

For detailed instructions, see [Deploying a Solace PubSub+ Software Event Broker onto an OpenShift 4 platform](/docs/PubSubPlusOpenShiftDeployment.md). There is also a general quick start for [Solace PubSub+ on Kubernetes](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md) available, which the OpenShift deployment builds upon.

The PubSub+ deployment does not require any special OpenShift Security Context; the default `restricted` SCC can be used.

We recommend using the PubSub+ Helm chart for convenience. An alternative method [using OpenShift templates](/docs/PubSubPlusOpenShiftDeployment.md#step-4-option-2-deploy-using-openshift-templates) is also available.

> Deprecation warning: deploying using OpenShift Templates is being phased out and the templates in this quickstart will be no longer maintained. The recommended deployment method is to use Helm. If Helm cannot be used then refer to the [PubSub+ Kubernetes documentation](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#alternative-deployment-with-generating-templates-for-the-kubernetes-kubectl-tool) to generate deployment manifests.

## Pre-requisite: Access to OpenShift Platform

There are [multiple ways](https://www.openshift.com/try ) to get to an OpenShift 4 platform:
- The detailed [Event Broker on OpenShift](/docs/PubSubPlusOpenShiftDeployment.md#step-1-optional--aws-deploy-a-self-managed-openshift-container-platform-onto-aws) documentation describes how to set up production-ready Red Hat OpenShift Container Platform platform on AWS.
- An option for developers is to locally deploy an all-in-one environment using [CodeReady Containers](https://developers.redhat.com/products/codeready-containers/overview).
- An easy way to get an OpenShift cluster up and running is through the [Developer Sandbox](https://developers.redhat.com/developer-sandbox) program. You can sign up for a free 14-day trial.

## Deploying PubSub+ Software Event Broker

The event broker can be deployed in either a three-node High-Availability (HA) group, or as a single-node standalone deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA deployment is required.

In this quick start we go through the steps to set up an event broker using [Solace PubSub+ Helm charts](https://artifacthub.io/packages/search?page=1&repo=solace).

There are three Helm chart variants available with default small-size configurations:
- `solace-pubsubplus-openshift-dev` - deploys a minimum footprint software event broker for developers (standalone)
- `solace-pubsubplus-openshift` - deploys a standalone software event broker that supports 100 connections
- `solace-pubsubplus-openshift-ha` - deploys three software event brokers in an HA group that supports 100 connections

For other event broker configurations or sizes, refer to the [PubSub+ Software Event Broker Helm Chart](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/pubsubplus/README.md) documentation.

You can install Helm charts on an OpenShift Container Platform cluster using the following methods:
* The Developer perspective of the OpenShift Web Console; or
* The CLI

## Option 1: Installing from the OpenShift Web Console, Developer perspective

This simple method uses the OpenShift Web Console graphical interface:

* In a browser open the OpenShift Web Console, Developer perspective.
* Find and select the required PubSub+ Helm chart variant from the catalog, then click on "Install".
* Provide a unique Release Name. It is recommended to change the name that is offered by default. The maximum length of the Release Name should be 28 characters.
* If required, provide additional chart configurations. For options, consult the README link at the top of the page. Note that currently the "Form view" offers all the possible fields and the "YAML view" shows only those that have a current configuration value. It may be necessary to refresh the browser to display the latest in "YAML view".

Additional information is available from the [OpenShift documentation](https://docs.openshift.com/container-platform/latest/applications/working_with_helm_charts/configuring-custom-helm-chart-repositories.html#odc-installing-helm-charts-using-Developer perspective_configuring-custom-helm-chart-repositories).

## Option 2: Installing from CLI

### Step 1: Ensure command-line console access to your OpenShift environment

Assuming you have access to an OpenShift 4 platform, log in as `kubeadmin` using the `oc login -u kubeadmin` command.

Ensure your OpenShift environment is ready:

```bash
# This command returns the current user
oc whoami
```

### Step 2: Install and Configure Helm

Follow the [instructions from Helm](//github.com/helm/helm#install), or if you're using Linux, simply run:
```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

Helm is configured properly if the `helm version` command returns no error.


### Step 3: Install the Software Event Broker with the Default Configuration

1. Add the Solace Helm charts to your local Helm repo:
    ```bash
    helm repo add openshift-helm-charts https://charts.openshift.io/
    ```

2. Create a new project or switch to your existing project (do not use the `default` project as its loose permissions don't reflect a typical OpenShift environment)
    ```bash
    oc new-project solace-pubsubplus
    ```

    By default the latest [Red Hat certified image](https://catalog.redhat.com/software/container-stacks/search?q=solace) of PubSub+ Standard Edition available from `registry.connect.redhat.com` is used. To use a different image, add the following values (comma-separated) to the `--set` commands in Step 3 below:

    ```bash
    helm install ... --set image.repository=<your-image-location>,image.tag=<your-image-tag>
    ```

    If it is required by the image repository, you can also add the following:
    ```bash
    --set image.pullSecretName=<your-image-repo-pull-secret>
    ```

3. Use one of the following Helm chart variants to create a deployment (for configuration options and deletion instructions, refer to the [PubSub+ Software Event Broker Helm Chart](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/tree/master/pubsubplus#configuration) documentation):

    - Create a Solace PubSub+ minimum deployment for development purposes using `solace-pubsubplus-openshift-dev`. This variant requires a minimum of 1 CPU and 3.4 GiB of memory to be available to the PubSub+ event broker pod.
      ```bash
      # Deploy PubSub+ Standard edition, minimum footprint developer version
      helm install my-release openshift-helm-charts/solace-pubsubplus-openshift-dev
      ```

    - Create a Solace PubSub+ standalone deployment that supports 100 connections using `solace-pubsubplus-openshift`. A minimum of 2 CPUs and 3.4 GiB of memory must be available to the PubSub+ pod.
      ```bash
      # Deploy PubSub+ Standard edition, standalone
      helm install my-release openshift-helm-charts/solace-pubsubplus-openshift
      ```

    - Create a Solace PubSub+ HA deployment that supports 100 connections using `solace-pubsubplus-openshift-ha`. This deployment requires that at least 2 CPUs and 3.4 GiB of memory are available to *each* of the three event broker pods.
      ```bash
      # Deploy PubSub+ Standard edition, HA
      helm install my-release openshift-helm-charts/solace-pubsubplus-openshift-ha
      ```

    All of the Helm options above start the deployment and write related information and notes to the console.

    Broker services are exposed by default through a Load Balancer that is specific to your OpenShift platform. For details, see the `Services access` section of the notes written to the console.

    > Note: the `solace-pubsubplus-openshift` Helm charts differ from the general `pubsubplus` charts in that the `securityContext.enabled` Helm parameter value is `false` by default, which is required for OpenShift.

4. Wait for the deployment to complete, following any instructions that are written to the console. You can now [validate the deployment and try the management and messaging services](/docs/PubSubPlusOpenShiftDeployment.md#validating-the-deployment).
 
    > Note: There is no external Load Balancer support with CodeReady Containers. Services are accessed through NodePorts instead. Check the results of the `oc get svc my-release-pubsubplus` command. This command returns the ephemeral NodePort port numbers for each message router service. Use these port numbers together with CodeReady Containers' public IP addresses, which can be obtained by running the `crc ip` command.

## Troubleshooting

If you have any problems, refer to the [Troubleshooting](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#troubleshooting) section of the general PubSub+ Kubernetes Documentation for help. Substitute any `kubectl` commands with `oc` commands.

If you need to start over, follow the steps to [delete the current deployment](/docs/PubSubPlusOpenShiftDeployment.md#deleting-a-deployment).


## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](//github.com/SolaceProducts/pubsubplus-openshift-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at [solace.dev](//solace.dev/)
- Understanding [Solace technology](//solace.com/products/platform/)
- Ask the [Solace community](//dev.solace.com/community/)
