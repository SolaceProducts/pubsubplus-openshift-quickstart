# Deploying a Solace PubSub+ Software Event Broker using Operator onto an OpenShift 4 Platform

The Solace PubSub+ Event Broker Operator (Operator) is a Kubernetes-native method to install and manage the lifecycle of a PubSub+ Software Event Broker on any Kubernetes platform including OpenShift.

>Note: We recommend using the PubSub+ Event Broker Operator. An alternative method using Helm is also available from an [earlier version of this repo](https://github.com/SolaceProducts/pubsubplus-openshift-quickstart/tree/v3.1.0).

This repository extends the [Solace PubSub+ Event Broker Operator on Kubernetes](https://github.com/SolaceDev/pubsubplus-kubernetes-operator) guide, providing additional specific instructions for the OpenShift 4 Platform.

Contents:
- [Deploying a Solace PubSub+ Software Event Broker using Operator onto an OpenShift 4 Platform](#deploying-a-solace-pubsub-software-event-broker-using-operator-onto-an-openshift-4-platform)
  - [Solace PubSub+ Software Event Broker](#solace-pubsub-software-event-broker)
  - [Overview](#overview)
  - [Step 1: Set Up OpenShift](#step-1-set-up-openshift)
  - [Step 2: Install the PubSub+ Event Broker Operator](#step-2-install-the-pubsub-event-broker-operator)
  - [Step 3: Deploy the PubSub+ Software Event Broker](#step-3-deploy-the-pubsub-software-event-broker)
  - [Contributing](#contributing)
  - [Authors](#authors)
  - [License](#license)
  - [Resources](#resources)

## Solace PubSub+ Software Event Broker

Solace [PubSub+ Platform](https://solace.com/products/platform/) is a complete event streaming and management platform for the real-time enterprise. The [PubSub+ Software Event Broker](https://solace.com/products/event-broker/software/) efficiently streams event-driven information between applications, IoT devices, and user interfaces running in the cloud, on-premises, and in hybrid environments using open APIs and protocols like AMQP, JMS, MQTT, REST and WebSocket. It can be installed into a variety of public and private clouds, PaaS, and on-premises environments. Event brokers in multiple locations can be linked together in an [Event Mesh](https://solace.com/what-is-an-event-mesh/) to dynamically share events across the distributed enterprise.

## Overview

This project is a best practice template intended for development and demo purposes. It has been tested using OpenShift v4.13. The tested and recommended PubSub+ Software Event Broker version is 10.4.

This document provides a quick getting started guide to install the broker in various configurations onto an OpenShift 4 platform.

For additional documentation, see [/docs/PubSubPlusOpenShiftDeployment.md](/docs/PubSubPlusOpenShiftDeployment.md) in this repo.

## Step 1: Set Up OpenShift

There are [multiple ways](https://www.openshift.com/try ) to set up an OpenShift 4 deployment, including the following examples:
- The detailed [Event Broker on OpenShift](/docs/PubSubPlusOpenShiftDeployment.md#deploy-a-production-ready-openshift-container-platform-onto-aws) documentation describes how to set up a production-ready Red Hat OpenShift Container Platform deployment on AWS.
- An option for developers is to locally deploy an all-in-one environment using [CodeReady Containers](https://developers.redhat.com/products/codeready-containers/overview). However, note that this requires sufficient local resources (minimum 2 CPUs and 4GB memory) in addition to the CodeReady resource requirements.

## Step 2: Install the PubSub+ Event Broker Operator

The certified PubSub+ Event Broker Operator is available in OpenShift from the [integrated OperatorHub catalog](https://catalog.redhat.com/software/search?p=1&vendor_name=Solace%20Corporation). Follow [Adding Operators to a cluster](https://docs.openshift.com/container-platform/latest/operators/admin/olm-adding-operators-to-cluster.html) in the OpenShift documentation to locate and install the "PubSub+ Event Broker Operator".

## Step 3: Deploy the PubSub+ Software Event Broker

Create a new OpenShift project. It is not recommended to use the `default` project.
```sh
oc new-project solace-pubsubplus
```

From here follow the steps in the [Solace PubSub+ Event Broker Operator Quick Start Guide](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart#3-pubsub-software-event-broker-deployment-examples) to deploy a single-node or an HA event broker.

>Note: the Operator recognizes the OpenShift environment and adjusts the default deployment `spec` parameters for the event broker, including the use of certified RedHat images. For more information, refer to the [detailed documentation](docs/PubSubPlusOpenShiftDeployment.md#broker-spec-defaults-in-openshift) in this repo.

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
