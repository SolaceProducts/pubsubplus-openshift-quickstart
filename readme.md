# VMR in Openshift

## Overview

This repository contains OpenShift templates to use the VMR in OpenShift.  It also contains a template to demonstrate
the VMR used by a Demo application to distribute work to workers.

## Prerequisites

* A target OpenShift environment
* A host with OpenShift client and Docker tools installed (IE. to run the Quick Start example)
* Have cluster admin privileges
* The VMR docker container (Available here : http://dev.solace.com/downloads/, under Docker in "VMR Community Edition")
* Have an administrator make the internal registry externally accessible :

```
oc expose service docker-registry -n default
```

## OpenShift installation

A guide is available to guide you in installing a minimalistic OpenShift environment in AWS here :
[AWS Openshift install guide](https://github.com/dickeyf/openshift-aws-install)

### Creating the OpenShift user

[AWS Openshift install guide - Creating Users](https://github.com/dickeyf/openshift-aws-install#creating-users-and-the-admin-user)

## Deploying the VMR Template

After making sure you have all the [prerequisites](prerequisites) met, copy the VMR Docker image to the directory that
contains the `deploy.sh` script.  Also place at that location the `id_rsa` file that contains your ssh private key for
the OpenShift master node.

Once these two files have been copied, execute the `deploy.sh` script :

```
./deploy.sh <ssh-host> <project-name> <openshift-domain>
```
IE:

```
./deploy.sh ec2-user@master.openshift.example.com demo-project openshift.example.com
```

The script will automate these steps for you :
* Log you in OpenShift (If you are not logged in yet)
* Create the project if it doesn't exists yet.
* Assign the required SCCs to the project's service account.
* Push the docker image to the OpenShift's project docker repository.
* Install the VMR template and instantiate it.

At the end you should have the VMR's DeploymentConfig created, and it will be instantiating a VMR pod.

## Using the VMR into your own application template

Copy the objects from the `solace-vmr-template.yml` into your template, and also add the parameters.  These objects will
instantiate a VMR pod with a Service and HTTP/HTTPS routes.  You can then adjust the service and router objects to your
needs.  For example if giving public access to the web services of the VMR is not desirable, then you should remove the
route objects from the template.

Your application should be configured to connect to the VMR by using the service.

An example of an application template embedding `solace-vmr-template.yml` can be found here
[Solace Messaging demonstration application](demo/).

## VMR Pod Requirements

For the VMR container to run properly as an OpenShift Pod the following requirements must be met :
* The container needs to be running in privileged mode
* The container processes have to run as root
* The container needs to have a `Memory` emptyDir mounted at `/dev/shm`

For these reasons, the project will requires the `anyuid` and `privileged` SCCs.

NOTE: These requirements are temporary and won't be necessary in a future load.

## VMR Container environment variables

The VMR Container can be configured via these environment variables :

| Environment Variable                      | Description |
| ----------------------------------------- | ----------- |
| USERNAME\_\<userName\>\_PASSWORD          | Setting this environment variable will create a user with \<userName\> as its username and set its password to the value of the environment variable. |
| USERNAME\_\<userName\>\_ENCRYPTEDPASSWORD | Setting this environment variable will create a user with \<userName\> as its username and set its password to the value of the environment variable. |
| USERNAME\_\<userName\>\_GLOBALACCESSLEVEL | Setting this environment variable will assign the global access level to the user \<userName\>.  Global access level can be one of these values: "" for no global access, "read-only", "read-write" or "admin". |
| SERVICE\_SSH\_PORT                        | The port used by the sshd process running within the VMR Docker Container. | 
| SERVICE\_SEMP\_PORT                       | The port used by the SEMP service within the VMR Docker Container.         |
| ROUTERNAME                                | The SolOS router name.                                                     |
| NODETYPE                                  | High-availability (HA) group node type.  Default value is message_routing. |

## VMR pod Template

A sample template of a VMR pod is provided here: [Solace VMR pod Template](solace-vmr-template.yml).

Use this template as a reference to add a VMR pod to your OpenShift application.

### Template header and metadata

Templates are explained on the OpenShift official documentation web site.  Templates are explained on that web site at
[this location](https://docs.openshift.org/latest/dev_guide/templates.html).

The template is a yaml document that starts with a header declaring that the object is a template (`kind: Template`)
and is using the version `v1`.

The metadata block is used to associate information to the template.  The metadata here includes the template name, 
and annotations (Used by OpenShift's web console to display the template).

```
apiVersion: v1
kind: Template
metadata:
  name: solace-vmr-template
  annotations:
    description: Creates a Solace VMR Pod
    iconClass: icon-phalcon
    tags: messaging
```

### Object List

A template defines a list of object to be created when the template is instantiated.  For this template these objects
will be created :
* A `DeploymentConfig` that creates the VMR pod.
* A `Service` that exposes the VMR's ports on a cluster IP.
* Routes which exposes the various VMR HTTP/HTTPS services.

This is how the template defines the VMR DeploymentConfig:
```
  - kind: DeploymentConfig
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-vmr'
    spec:
      strategy:
        type: Rolling
        rollingParams:
          timeoutSeconds: 1200
          maxSurge: 0
          maxUnavailable: 1
      triggers:
        - type: ConfigChange
      replicas: 1
      selector:
        deploymentconfig: '${APPLICATION_NAME}-vmr'
      template:
        metadata:
          name: '${APPLICATION_NAME}-vmr'
          labels:
            name: '${APPLICATION_NAME}-vmr'
            deploymentconfig: '${APPLICATION_NAME}-vmr'
        spec:
          volumes:
          - name: dshm
            emptyDir:
              medium: Memory
          containers:
            - name: "solace-vmr"
              env:
              - name: USERNAME_${ADMIN_USER}_PASSWORD
                value: '${ADMIN_PASSWORD}'
              - name: USERNAME_${ADMIN_USER}_GLOBALACCESSLEVEL
                value: 'admin'
              - name: SERVICE_SSH_PORT
                value: '22'
              - name: ALWAYS_DIE_ON_FAILURE
                value: '0'
              - name: ROUTERNAME
                value: '${ROUTER_NAME}'
              - name: NODETYPE
                value: '${NODE_TYPE}'
              image: "${VMR_IMAGE}"
              volumeMounts:
              - mountPath: /dev/shm
                name: dshm
              securityContext:
                privileged: true
              ports:
              - containerPort: 8080
                protocol: TCP
              - containerPort: 943
                protocol: TCP
              - containerPort: 55555
                protocol: TCP
              - containerPort: 55003
                protocol: TCP
              - containerPort: 55556
                protocol: TCP
              - containerPort: 55443
                protocol: TCP
              - containerPort: 80
                protocol: TCP
              - containerPort: 443
                protocol: TCP
              - containerPort: 1883
                protocol: TCP
              - containerPort: 8883
                protocol: TCP
              - containerPort: 8000
                protocol: TCP
              - containerPort: 8443
                protocol: TCP
              - containerPort: 9000
                protocol: TCP
              - containerPort: 9443
                protocol: TCP
              - containerPort: 22
                protocol: TCP
              readinessProbe:
                initialDelaySeconds: 30
                periodSeconds: 5
                tcpSocket:
                  port: 55555
              livenessProbe:
                timeoutSeconds: 6
                initialDelaySeconds: 300
                periodSeconds: 60
                tcpSocket:
                  port: 55555
```

__NOTE__: A dshm volume is required to be mounted at /dev/shm to give the VMR process enough space in /dev/shm.

It also defines the container's name : `vmr`, and environment variables that are explained in section
[VMR Container environment variables](#VMR-Container-environment-variables) above.  It also mount the Emptydir volume
`dshm` onto `/dev/shm`, give the container privilege access, and then defines ports that must be exposed.

### Template's parameter list

Finally, the template must define all parameters that were used throughout the template document :
* APPLICATION_NAME
* APPLICATION_SUBDOMAIN
* VMR_IMAGE
* ROUTER_NAME
* NODE_TYPE
* ADMIN_USER
* ADMIN_PASSWORD

This is how these parameters are defined :
```
  - name: APPLICATION_NAME
    displayName: Application Name
    description: The suffix to use for object names
    generate: expression
    from: '[A-Z0-9]{8}'
    value: example
    required: true
  - name: APPLICATION_SUBDOMAIN
    displayName: Application Subdomain
    description: The subdomain the template uses for its routes hostnames.
    value: vmr1.openshift.exampledomain.com
  - name: VMR_IMAGE
    displayName: VMR Image
    description: >-
      Fully qualified VMR image name.
    value: 172.30.3.53:5000/vmr-openshift-demo/solace-app
  - name: ROUTER_NAME
    displayName: Router Name
    description: The name of the router to instantiate.
    value: vmr1
  - name: NODE_TYPE
    displayName: VMR Node Type
    description: The role of this VMR Node : message_routing or monitoring.  Monitoring is used only in HA group.
    value: message_routing
  - name: ADMIN_USER
    description: Username of the admin user
    generate: expression
    from: '[A-Z0-9]{8}'
    value: admin
  - name: ADMIN_PASSWORD
    description: Password of the admin user
    generate: expression
    from: '[A-Z0-9]{8}'
    value: admin
```

When the user instantiate the template, he can specify a value for each parameter.  For instance the user would pick
the initial admin user's username by assigning the username to the `ADMIN_USER` parameter.  The name of the pod and the
initial admin user's password can be controller in the same way.

## Instantiating the example VMR Template

NOTE: The `deploy.sh` script automates these steps it is recommended to use it instead of manually executing these
commands.  This section purpose is to explain what the scripts does.

If your OpenShift project hasn't been created yet you will need to create it like so :
```
oc new-project vmr-openshift-demo
```

To be able to assign SSCs your project's Service Account you will need cluster admin privilege.

In order to do this, you will have to be logged on one of the OpenShift Master Node and run these commands :
```
oadm policy add-scc-to-user privileged system:serviceaccount:vmr-openshift-demo:default
oadm policy add-scc-to-user anyuid system:serviceaccount:vmr-openshift-demo:default
```

Download the VMR Container image from [Solace Downloads page](http://dev.solace.com/downloads/).  You can download
either the `Community Edition` or the `Evaluation Edition` as both will work.  The `Community Edition` is free and
never expires but contains less features (See the Edition Comparision chart on the downloads page).

Pushing the docker image to the internal registry requires the use of a machine running docker (IE. Docker machine).
The image is then loaded locally, and tagged as a repository image.  Then login to the OpenShift registry and push
the image using these commands :
```
docker load -i <image>.tar.gz
docker login --username=<user> --password=`oc whoami -t` docker-registry-default.<domain>
docker tag solace-app:<version-tag> docker-registry-default.<domain>/vmr-openshift-demo/solace-app:latest
docker push docker-registry-default.<domain>/vmr-openshift-demo/solace-app
```

List the imagestreams named `solaceapp` to learn the full VMR Image name :
```
➜  openshift git:(master) ✗ oc get imagestreams solace-app
NAME         DOCKER REPO                                      TAGS      UPDATED
solace-app   172.30.3.53:5000/vmr-openshift-demo/solace-app   latest    48 minutes ago
```

In this case, the image must be `172.30.3.53:5000/vmr-openshift-demo/solace-app`.

The application subdomain should be a DNS wildcard entry which maps to the OpenShift router.  Routes will be
created based on that subdomain and should all resolve to the router.

```
oc create -f solace-vmr-template.yml
oc process solace-vmr-template VMR_IMAGE=<ImageStream> APPLICATION_SUBDOMAIN=<Subdomain> | oc create -f -
```

## Demo Openshift Application

A demonstration of the VMR in use by sample application is available here : [Openshift VMR Demo](demo/)

## Using SolAdmin to connect to the VMR pod

SolAdmin can be used to connect to the VMR and administer it.  SolAdmin can be downloaded from [Solace's Download Page](http://dev.solace.com/downloads/).

Follow these steps to connect to the VMR:
1. Navigate to semp.<openshift-domain> with your browser and accept the server certificate.
1. Export the certificate from your system trust-store and import the certificate into a Java Key Store (JKS) file.
1. Connect to VMR from SolAdmin, these are the fields that must be filled:

| Field                      | Value |
| ----------------------------------------- | -------------- |
| Management IP Address/Host | semp.<APPLICATION_SUBDOMAIN>  |
| Management Port            | 443                           |
| Username                   | <ADMIN_USER>                  |
| Password                   | <ADMIN_PASSWORD>              | 
| Use Secure Session         | This field must be checked    |
| Trust Store File           | <Path to .jks file>           |
| Trust Store Password       | <jks file password>           |

<APPLICATION_SUBDOMAIN>: The subdomain that was chosen when the VMR template was deployed.
<ADMIN_USER>: The admin username that was chosen when the VMR template was deployed. 
<ADMIN_PASSWORD>: The admin password that was chosen when the VMR template was deployed.
<Path to .jks file>: This is the JKS file into which you imported the VMR certificate.
<jks file password>: This is the password you used to encrypt and temper-proof the JKS file. 

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull
requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceLabs/solace-openshift-quickstart/graphs/contributors) who
participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## References

Here are some interesting links if you're new to these concepts:

* [The Solace Developer Portal](http://dev.solace.com/)
* [OpenShift's Core concepts](https://docs.openshift.com/container-platform/3.4/architecture/core_concepts/index.html)
* [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
* [Docker Machine Overview](https://docs.docker.com/machine/overview/)