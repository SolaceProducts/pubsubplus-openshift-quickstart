# Deploying a Solace PubSub+ Software Event Broker Onto an OpenShift 4 Platform Using Operator

This document provides platform-specific information for deploying the [Solace PubSub+ Software Event Broker](https://solace.com/products/event-broker/software/) on OpenShift, using the Solace PubSub+ Event Broker Operator (Operator). It complements and should be used together with the [Solace PubSub+ Event Broker Operator User Guide](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/main/docs/EventBrokerOperatorUserGuide.md), which has instructions for Kubernetes in general.

Contents:
- [Deploying a Solace PubSub+ Software Event Broker Onto an OpenShift 4 Platform Using Operator](#deploying-a-solace-pubsub-software-event-broker-onto-an-openshift-4-platform-using-operator)
  - [Production Deployment Architecture](#production-deployment-architecture)
  - [OpenShift Platform Setup Examples](#openshift-platform-setup-examples)
    - [Deploying a Production-Ready OpenShift Container Platform onto AWS](#deploying-a-production-ready-openshift-container-platform-onto-aws)
      - [Deleting the AWS OpenShift Container Platform Deployment](#deleting-the-aws-openshift-container-platform-deployment)
    - [Deploying CodeReady Containers for OpenShift](#deploying-codeready-containers-for-openshift)
    - [Using a Private Image Registry for Broker and Prometheus Exporter Images](#using-a-private-image-registry-for-broker-and-prometheus-exporter-images)
      - [Using AWS ECR with CodeReady Containers](#using-aws-ecr-with-codeready-containers)
  - [Deployment Considerations](#deployment-considerations)
    - [Broker Spec Defaults in OpenShift](#broker-spec-defaults-in-openshift)
    - [Accessing Broker Services](#accessing-broker-services)
      - [Routes](#routes)
        - [HTTP With No TLS](#http-with-no-tls)
        - [HTTPS With TLS (Terminate at Ingress)](#https-with-tls-terminate-at-ingress)
        - [HTTPS with TLS (Re-encrypt at Ingress)](#https-with-tls-re-encrypt-at-ingress)
        - [General TCP over TLS with Passthrough to Broker](#general-tcp-over-tls-with-passthrough-to-broker)
    - [Security Considerations](#security-considerations)
    - [Helm-based Deployment](#helm-based-deployment)
  - [Exposing Metrics to Prometheus](#exposing-metrics-to-prometheus)
  - [Broker Deployment in OpenShift Using the Operator](#broker-deployment-in-openshift-using-the-operator)
    - [Quick Start](#quick-start)
- [Additional Resources](#additional-resources)
- [Appendix: Using NFS for Persistent Storage](#appendix-using-nfs-for-persistent-storage)

## Production Deployment Architecture

The following diagram shows an example of an HA group deployment of PubSub+ software event brokers in AWS:

![alt text](/docs/images/network_diagram.jpg "Network Diagram")

The key parts to note in the diagram above are:
- the three PubSub+ Container instances in OpenShift pods, deployed on OpenShift (worker) nodes
- the cloud load balancer exposing the event broker's services and management interface
- the OpenShift master nodes(s)
- the CLI console that hosts the `oc` OpenShift CLI utility client

## OpenShift Platform Setup Examples

You can skip this section if you already have your own OpenShift environment available.

There are [multiple ways](https://www.openshift.com/try ) to set up an OpenShift platform. This section provides a distributed production-ready example that uses the Red Hat OpenShift Container Platform for deploying an HA group of software event brokers, but the concepts are transferable to other compatible platforms.

This section also give tips for how to set up a simple single-node deployment using [CodeReady Containers](https://developers.redhat.com/products/codeready-containers/overview ) (the equivalent of MiniShift for OpenShift 4) for development, testing, or proof of concept purposes.

The last sub-section describes how to use a private image registry, such as AWS ECR, together with OpenShift.

### Deploying a Production-Ready OpenShift Container Platform onto AWS

This procedure requires the following:
- a free Red Hat account. You can create one [here](https://developers.redhat.com/login ), if needed.
- a command console on your host platform with Internet access. The examples here are for Linux, but MacOS is also supported.
- a designated working directory for the OpenShift cluster installation.
>**Important:** The automated install process creates files here that are required later for deleting the OpenShift cluster. Use a dedicated directory and do not delete any temporary files.

```
mkdir ~/workspace; cd ~/workspace
```

To deploy the container platform in AWS, do the following:
1. If you haven't already, log in to your RedHat account.
2. On the [**Create an OpenShift cluster**](https://cloud.redhat.com/openshift/create) page, under **Run it yourself**, select **AWS** and then **Installer-provisioned infrastructure**. A page is displayed that allows you to download the the required binaries and documentation.
3. Select your OS, and then make a note of the URL of the "Download installer" button.
4. On your host, in the command console, run the following commands to download and expand the OpenShift installer:
    ```
    wget <link-address>                        # Use the link address from the "Download installer" button
    tar -xvf openshift-install-linux.tar.gz    # Adjust the filename if needed
    rm openshift-install-linux.tar.gz
    ```
5. Run the utility to create an install configuration. Provide the necessary information at the prompts, including the pull secret from the RedHat instructions page. The utility creates the `install-config.yaml` file with the [installation configuration parameters](https://docs.openshift.com/container-platform/latest/installing/installing_aws/installing-aws-customizations.html#installation-aws-config-yaml_installing-aws-customizations), most importantly the configuration for the worker and master nodes.
    ```
    ./openshift-install create install-config --dir=.
    ```
6. Edit the `install-config.yaml` file to update the AWS machine type of the worker node to meet the [minimum CPU and Memory requirements](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#cpu-and-memory-requirements) for the targeted PubSub+ Software Event Broker configuration. When you select an [EC2 instance type](https://aws.amazon.com/ec2/instance-types/), allow at least 1 CPU and 1 GiB memory for OpenShift purposes that cannot be used by the broker. The following is an example of an updated configuration:
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
7. Create a backup copy of the configuration file, then launch the installation. The installation may take 40 minutes or more.
    ```
    cp install-config.yaml install-config.yaml.bak
    ./openshift-install create cluster --dir=.
    ```
8. If the installation is successful, information similar to the following is written to the command console. Take note of the web-console URL and login information for future reference.
    ```
    INFO Install complete!
    INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/opt/auth/kubeconfig'
    INFO Access the OpenShift web-console here: https://console-openshift-console.apps.iuacc.soltest.net
    INFO Login to the console with user: "kubeadmin", and password: "CKGc9-XUT6J-PDtWp-d4DSQ"
    ```
9. [Install](https://docs.openshift.com/container-platform/latest/installing/installing_aws/installing-aws-default.html#cli-installing-cli_installing-aws-default) the `oc` client CLI tool.
10. Verify that your cluster is working correctly by following the hints from Step 8, including verifying access to the OpenShift web-console.

#### Deleting the AWS OpenShift Container Platform Deployment

If you need to delete your [AWS OpenShift Container Platform deployment](#deploy-a-production-ready-openshift-container-platform-onto-aws), run the following commands:

```
cd ~/workspace
./openshift-install help # Check options
./openshift-install destroy cluster
```

These commands remove all resources of the deployment.

### Deploying CodeReady Containers for OpenShift

If you are using CodeReady Containers, follow the [getting started instructions](https://developers.redhat.com/products/codeready-containers/getting-started) to stand up a working CodeReady Containers deployment that supports Linux, MacOS, and Windows.

At the `crc start` step it is helpful to:
* have a local copy of the OpenShift `pullsecret` file created; 
* specify CPU and memory requirements, allowing 2 to 3 CPU and 2.5 to 7 GiB memory for CRC internal purposes (depending on your platform and CRC version); 
* also specify a DNS server, for example: `crc start -p ./pullsecret -c 5 -m 11264 --nameserver 1.1.1.1`.

### Using a Private Image Registry for Broker and Prometheus Exporter Images

By default, the deployment scripts pull the Solace PubSub+ image from the [Red Hat containerized products catalog](https://catalog.redhat.com/software/container-stacks/search?q=solace). If the OpenShift worker nodes have Internet access, no further configuration is required.

However, if you need to use a private image registry, such as AWS ECR, you must supply a pull secret to enable access to the registry. The steps that follow show how to use AWS ECR for the broker image.

1. Download a free trial of the the Solace PubSub+ Enterprise Evaluation Edition by going to the **Docker** section of the [Solace Downloads](https://solace.com/downloads/?fwp_downloads_types=pubsub-enterprise-evaluation) page, or obtain an image from Solace Support.
2. Push the broker image to the private registry. Follow the specific procedures for the registry you are using. For ECR, see the diagram below as well as the instructions in [Using Amazon ECR with the AWS CLI](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html).<br /><br />
    ![alt text](/docs/images/ECR-Registry.png "ECR Registry")<br />
    >Note: If you are advised to run `aws ecr get-login-password` as part of the "Authenticate to your registry" step and it fails, try running `$(aws ecr get-login --region <your-registry-region> --no-include-email)` instead. 

3. Create a pull secret from the registry information in the Docker configuration. This assumes that the ECR login happened on the same machine:
    ```
    oc create secret generic <my-pullsecret> \
       --from-file=.dockerconfigjson=$(readlink -f ~/.docker/config.json) \
       --type=kubernetes.io/dockerconfigjson
    ```
4. Use the pull secret you just created (`<my-pullsecret>`) in the broker deployment manifest.

For additional information, see the [Using private registries](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/main/docs/EventBrokerOperatorUserGuide.md#using-a-private-registry) section of the *Solace PubSub+ Event Broker Operator User Guide*.

#### Using AWS ECR with CodeReady Containers
If you are using CodeReady Containers, you might need to perform a workaround if the ECR login fails on the console (e.g., on Windows). In this case, do the following:
1. Log into the OpenShift node: `oc get node` 
2. Run the `oc debug node/<reported-node-name>` command.
3. At the prompt, run the `chroot /host` command.
4. Run the following command:
    ````
    echo "<password-text>" | podman login --username AWS --password-stdin <registry>
    ````
    Where:
    - `<password-text>`: The text returned from the [`aws ecr get-login-password --region <ecr-region>`](https://docs.aws.amazon.com/cli/latest/reference/ecr/get-login-password.html) command. Run this command from a different machine where `aws` is installed (it is not straightforward to install the `aws` CLI on the CoreOS running on the node).
    - `<registry>`: The URI for your ECR registry, for example `9872397498329479394.dkr.ecr.us-east-2.amazonaws.com`.
5. Run `podman pull <your-ECR-image>` to load the image locally on the CRC node. 
    After you exit the node, you can use your ECR image URL and tag for the deployment. There is no need for a pull secret in this case.

## Deployment Considerations

Consult the [Deployment Planning](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/main/docs/EventBrokerOperatorUserGuide.md#deployment-planning) section of the general *Solace PubSub+ Event Broker Operator User Guide* when planning your deployment.

The following sections apply only to the OpenShift platform.

### Broker Spec Defaults in OpenShift

The Operator detects (1) whether the OpenShift platform is used and (2) the name of the OpenShift project (namespace) for the broker deployment. It automatically adjusts the default values for the parameters listed in the table below. You can override the defaults by explicitly specifying the parameters.

| OpenShift Project (Namespace) | Broker Spec Parameter | General Kubernetes Defaults (for information only) | OpenShift Defaults |
| --- | --- | --- | --- |
| Any, excluding `default`. <br /><br />**Note:** We recommend that you do NOT use the `default` project. | `spec.securityContext.runAsUser` | 1000001| Not set (OpenShift sets it according to the OpenShift project settings) |
|| `spec.securityContext.fsGroup` | 1000002 | Not set (OpenShift sets it according to the OpenShift project settings) |
| `default` <br /><br />**Note:** Not recommended | `spec.securityContext.runAsUser` | 1000001 | 1000001 |
|| `spec.securityContext.fsGroup` | 1000002 | 1000002 |
| All OpenShift projects | `spec.image` | solace/solace-pubsub-standard | registry.connect.redhat.com/solace/pubsubplus-standard |
| | `spec.monitoring.image` | solace/solace-prometheus-exporter | registry.connect.redhat.com/solace/pubsubplus-prometheus-exporter |

Although `runAsUser` cannot be configured using a broker spec parameter, the Operator similarly adjusts the `runAsUser` settings for the Prometheus exporter pod.

### Accessing Broker Services

The principles for exposing services that are described in the [Solace PubSub+ Event Broker Operator User Guide](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/main/docs/EventBrokerOperatorUserGuide.md#accessing-broker-services) also apply here:
* LoadBalancer is the default service type and can be used to externally expose all broker services. This is an option for OpenShift as well and will not be further discussed here.
* Ingress and its equivalent, OpenShift Routes, can be used to expose specific services.

#### Routes

 OpenShift has a default production-ready [ingress controller setup](https://docs.openshift.com/container-platform/latest/networking/understanding-networking.html#nw-ne-openshift-ingress_understanding-networking) based on HAProxy. Using Routes is the recommended OpenShift-native way to configure Ingress. Refer to the OpenShift documentation for more information on [Ingress and Routes](https://docs.openshift.com/container-platform/latest/networking/understanding-networking.html#nw-ne-openshift-ingress_understanding-networking) and [how to configure Routes](https://docs.openshift.com/container-platform/latest/networking/routes/route-configuration.html).

 The same table provided for Ingress in the [Solace Kubernetes Quickstart](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/master/docs/PubSubPlusK8SDeployment.md#using-ingress-to-access-event-broker-services) applies here. HTTP-type broker services can be exposed with TLS (edge-terminated or re-encrypt) or without TLS. General TCP services can be exposed using TLS-passthrough to the broker Pods.

 The controller's external (router default) IP address can be determined from looking up the external-IP of the `router-default` service, by running `oc get svc -n openshift-ingress`. OpenShift can automatically assign DNS-resolvable unique host names and TLS-certificates when using Routes (except for TLS-passthrough). It is also possible to assign user-defined host names to the services, but you must ensure that they DNS-resolve to the router IP, and that any related TLS-certificates include those hostnames in the CN and/or SAN fields. 
 
>Note: If a PubSub+ service client requires that hostnames are provided in the SAN field, you must use user-defined TLS certificates, because OpenShift-generated certificates only use the CN field.

The following sections provide examples for each router type. Replace `<my-pubsubplus-service>` with the name of the service of your deployment. The port name must match the `service.ports` name in the PubSub+ `values.yaml` file.
Additional services can be exposed by an additional route for each.

> Note: When configuring Routes to connect two PubSub+ Event Broker services for [Message VPN Bridges](https://docs.solace.com/Features/VPN/Message-VPN-Bridges-Overview.htm), the service needs to be accessible from every other PubSub+ Event Broker service.

##### HTTP With No TLS

The following commands create an HTTP route to the REST service at path `/`:
```bash
oc expose svc <my-pubsubplus-service> --port tcp-rest \
    --name my-broker-rest-service --path /
# Query the route to get the generated host for accessing the service
oc get route my-broker-rest-service -o template --template='{{.spec.host}}'
```
External requests are targeted to the host at the HTTP port (80) and the specified path.

##### HTTPS With TLS (Terminate at Ingress)

Terminating TLS at the router is called "edge" in OpenShift. The target port is the backend broker's non-TLS service port.
```bash
oc create route edge my-broker-rest-service-tls-edge \
    --service <my-pubsubplus-service> \
    --port tcp-rest \
    --path /    # path is optional and must not be used for SEMP service
# Query the route to get the generated host for accessing the service
oc get route my-broker-rest-service-tls-edge -o template --template='{{.spec.host}}'
```
External requests are targeted to the host at the TLS port (443) and the specified path.

> Note: The example above uses OpenShift's generated TLS certificate, which is self-signed by default and includes a wildcard hostname in the CN field. To use user-defined TLS certificates with more control instead, refer to the [OpenShift documentation](https://docs.openshift.com/container-platform/latest/networking/routes/secured-routes.html#nw-ingress-creating-an-edge-route-with-a-custom-certificate_secured-routes).

##### HTTPS with TLS (Re-encrypt at Ingress)

Re-encrypt requires that TLS is configured on the backend PubSub+ broker. The target port is now the broker's TLS service port. The broker's CA certificate must be provided in the `--dest-ca-cert` parameter, so that the router can trust the broker.
```bash
oc create route reencrypt my-broker-rest-service-tls-reencrypt \
    --service <my-pubsubplus-service> \
    --port tls-rest \
    --dest-ca-cert my-pubsubplus-ca.crt \
    --path /
# Query the route to get the generated host for accessing the service
oc get route my-broker-rest-service-tls-reencrypt -o template --template='{{.spec.host}}'
```
The TLS certificate note in the previous section is also applicable here.

##### General TCP over TLS with Passthrough to Broker

Passthrough requires a TLS-certificate configured on the backend PubSub+ broker that validates all virtual host names for the services exposed, in the CN and/or SAN fields.

```bash
oc create route passthrough my-broker-smf-service-tls-passthrough \
    --service <my-pubsubplus-service> \
    --port tls-smf \
    --hostname smf.mybroker.com
```
Here the example PubSub+ SMF messaging service can be accessed at `tcps://smf.mybroker.com:443`. Also, `smf.mybroker.com` must resolve to the router's external IP as discussed above and the broker certificate must include `*.mybroker.com` in the CN and/or SAN fields.

The API client must support and use the SNI extension of the TLS handshake to provide the hostname to the OpenShift router for routing the request to the right backend broker.

### Security Considerations

The event broker deployment does not require any special OpenShift Security Context; the default most restrictive ["restricted-v2" SCC](https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html) can be used.

### Helm-based Deployment

We recommend using the PubSub+ Event Broker Operator. An alternative method using Helm is described and available from an [earlier version of this repo](https://github.com/SolaceProducts/pubsubplus-openshift-quickstart/tree/v3.2.0).

## Exposing Metrics to Prometheus

OpenShift ships with an integrated customized Prometheus deployment, with the following restrictions:
* Monitoring must be enabled for user-defined projects. Only default platform monitoring is enabled by default.
* The Grafana UI has been removed in OpenShift 4.11. Only built-in Dashboards are available.

Monitoring must be enabled for user-defined projects by [creating a `user-workload-monitoring-config` ConfigMap object](https://docs.openshift.com/container-platform/latest/monitoring/enabling-monitoring-for-user-defined-projects.html) in the `openshift-user-workload-monitoring` project.

After this, the only step required to [connect the broker metrics with Prometheus](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/main/docs/EventBrokerOperatorUserGuide.md#connecting-with-prometheus) is to [create a ServiceMonitor object](https://github.com/SolaceProducts/pubsubplus-kubernetes-quickstart/blob/main/docs/EventBrokerOperatorUserGuide.md#creating-a-servicemonitor-object) in the project where the broker has been deployed.

Check the OpenShift admin console in "Administrator" view to verify that the monitoring endpoint for the event broker deployment has been connected to Prometheus:

![alt text](/docs/images/PrometheusTargets.png "Prometheus targets")

To enable custom Dashboards in the Grafana UI, you must install the community Grafana Operator from OpenShift's OperatorHub and then connect it to OpenShift Prometheus via a GrafanaDataSource.

## Broker Deployment in OpenShift Using the Operator

### Quick Start

Refer to the [Quick Start Guide](/README.md) in the root of this repo. It provides information about [installing the Operator](/README.md#step-2-install-the-pubsub-event-broker-operator) and [deploying the PubSub+ Event Broker](/README.md#step-3-deploy-the-solace-pubsub-software-event-broker).

# Additional Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).

# Appendix: Using NFS for Persistent Storage

> **Important:** This section is provided for information only—NFS is currently not supported for PubSub+ production deployments. 

The NFS server must be configured with the "root_squash" option.

For an example deployment, specify the storage class from your NFS deployment ("nfs" in this example) in the `storage.useStorageClass` parameter and ensure `storage.slow` is set to `true`.

The Helm (NFS Server Provisioner)[https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner] project is an example of a dynamic NFS server provisioner. Here are the steps to get going with it:


1. Create the required SCC:
    ```
    sudo oc apply -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs/deploy/kubernetes/scc.yaml
    ```
2. Install the NFS helm chart, which creates all dependencies:
    ```
    helm install stable/nfs-server-provisioner nfs-test --set persistence.enabled=true,persistence.size=100Gi
    ```
3. Ensure the "nfs-provisioner" service account got created:
    ```
    oc get serviceaccounts
    ```
4. Bind the SCC to the "nfs-provisioner" service account:
    ```
    sudo oc adm policy add-scc-to-user nfs-provisioner -z nfs-test-nfs-server-provisioner
    ```
5. Ensure the NFS server pod is up and running:
    ```
    oc get pod nfs-test-nfs-server-provisioner-0
    ```

If you're using a template to deploy, locate the volume mount for `softAdb` in the template and disable it by commenting it out:

```yaml
# only mount softAdb when not using NFS, comment it out otherwise
#- name: data
#  mountPath: /usr/sw/internalSpool/softAdb
#  subPath: softAdb
```
