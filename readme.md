# VMR in Openshift

## Overview

This repository contains Openshift templates to use the VMR in Openshift.  It also contains a template to demonstrate
the VMR used by a Demo application to distribute work to workers.

## Prerequisites

* Access to an Openshift environment
* Access to an Openshift project whose service account have the anyuid and privilege SCCs assigned to it
* The VMR docker container (Available here : http://dev.solace.com/downloads/, under Docker in "VMR Community Edition")

## Openshift installation

A guide is available to guide you in installing a minimalistic Openshift environment in AWS here :
[AWS Openshift install guide](https://github.com/dickeyf/openshift-aws-install)

## Assigning the SCCs to the Security Account

To be able to assign SSCs your project's Service Account you will need cluster admin privilege.

In order to do this, you will have to be logged on one of the Openshift Master Node and run these commands :
```
oadm policy add-scc-to-user privileged system:serviceaccount:vmr-openshift-demo:default
oadm policy add-scc-to-user anyuid system:serviceaccount:vmr-openshift-demo:default
```

## VMR Pod Requirements

For the VMR container to run properly as an Openshift Pod the following requirements must be met :
* The container needs to running in privileged mode
* The container needs to have a `Memory` emptyDir mounted at `/dev/shm`

## VMR Container environment variables

The VMR Container can be configured via these environment variables :

| Environment Variable                  | Description |
| ------------------------------------- | ----------- |
| USERNAME\_\<userName\>\_PASSWORD          | Setting this environment variable will create a user with \<userName\> as its username and set its password to the value of the environment variable |
| USERNAME\_\<userName\>\_ENCRYPTEDPASSWORD | Setting this environment variable will create a user with \<userName\> as its username and set its password to the value of the environment variable |
| USERNAME\_\<userName\>\_GLOBALACCESSLEVEL | Setting this environment variable will assign the global access level to the user \<userName\>.  Global access level can be one of these values: "" for no global access, "read-only", "read-write" or "admin" |
| SERVICE\_SSH\_PORT                        | The port used by the sshd process running within the VMR Docker Container. | 
| SERVICE\_SEMP\_PORT                       | The port used by the SEMP service within the VMR Docker Container. |

## VMR pod Template

A sample template of a VMR pod is provided here: [Solace VMR pod Template](solace-vmr-template.yml).

Use this template as a reference to add a VMR pod to your Openshift application.

### Template header and metadata

The template is a yaml document that starts with an header declaring that the object is a template (`kind: Template`)
and is using the version `v1`.

The metadata block is used to associate information to the template.  The metadata here includes the template name, 
it's namespace, and annotations (Used by Openshift's web console to display the template).

```
apiVersion: v1
kind: Template
metadata:
  name: solace-vmr-template
  namespace: prototype
  annotations:
    description: Creates a Solace VMR Pod
    iconClass: icon-phalcon
    tags: messaging
```

### Object List

A template defines a list of object to be created when the template is instantiated.  For this template only one Pod is
to be created, and the pod name is also a parameter `POD_NAME` :  

```
objects:
  - apiVersion: v1
    kind: Pod
    metadata:
      name: '${POD_NAME}'
```

This pod must declare one Memory empty dir that will be used by the VMR for its `/dev/shm`. This is required to have
more than 64meg available to /dev/shm (Kubernetes forces all containers to have 64 megs only.
IE. it sets `shm-size=64`).  This is how the Emptydir for `/dev/shm` is defined, and it is named `dshm`:
```
    spec:
      volumes:
        - name: dshm
          emptyDir:
            medium: Memory
```

Finally, the pod also define the VMR container.  It specify the Docker image used to instantiate the container.  Note
that the `172.30.3.53:5000` address refers to the Docker registry, and this address must be changed to match your
Openshift environment.  If you have imagestreams in your Openshift repository that you want to use, you will need to 
discover the address by typing this command `oc get imagestreams`.  IE:
```
➜  demo git:(master) oc get imagestreams
NAME                          DOCKER REPO                                                       TAGS      UPDATED
messaging-sample-aggregator   172.30.3.53:5000/vmr-openshift-demo/messaging-sample-aggregator   latest    21 hours ago
messaging-sample-worker       172.30.3.53:5000/vmr-openshift-demo/messaging-sample-worker       latest    22 hours ago
s2i-java                      jorgemoralespou/s2i-java                                          latest    22 hours ago
solace-app                    172.30.3.53:5000/vmr-openshift-demo/solace-app                    latest    22 hours ago
```

In this case, the image must be `172.30.3.53:5000/vmr-openshift-demo/solace-app`.

This is how the template define the container's:
```
      containers:
          image: '172.30.3.53:5000/vmr-openshift-demo/solace-app'
          name: vmr
          env:
          - name: USERNAME_${ADMIN_USER}_PASSWORD
            value: '${ADMIN_PASSWORD}'
          - name: USERNAME_${ADMIN_USER}_GLOBALACCESSLEVEL
            value: 'admin'
          - name: SERVICE_SSH_PORT
            value: '22'
          - name:
          volumeMounts:
            - mountPath: /dev/shm
              name: dshm
          securityContext:
            privileged: true
          ports:
            - containerPort: 80
              protocol: TCP
            - containerPort: 8080
              protocol: TCP
            - containerPort: 55555
              protocol: TCP
            - containerPort: 22
              protocol: TCP
```

It also define's the container's name : `vmr`, and environment variables that are explained in section
[VMR Container environment variables](#VMR-Container-environment-variables) above.  It also mount the Emptydir volume
`dshm` onto `/dev/shm`, give the container privilege access, and then defines ports that must be exposed.

### Template's parameter list

Finally, the template must defines all parameters there was used throughout the template document :
* POD_NAME
* ADMIN_USER
* ADMIN_PASSWORD

This is how these parameters are defined :
```
    - name: POD_NAME
      description: The name of the Solace Messaging service to create
      generate: expression
      from: '[A-Z0-9]{8}'
    - name: ADMIN_USER
      description: Username of the admin user
      generate: expression
      from: '[A-Z0-9]{8}'
    - name: ADMIN_PASSWORD
      description: Password of the admin user
      generate: expression
      from: '[A-Z0-9]{8}'
```

When the user instantiate the template, he can specify a value for each parameter.  For instance the user would pick
the initial admin user's username by assigning the username to the `ADMIN_USER` parameter.  The name of the pod and the
initial admin user's password can be controller in the same way.

## Demo Openshift Application

A demonstration of the VMR in use by sample application is available here : [Openshift VMR Demo](demo/)