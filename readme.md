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

## Demo Openshift Application

A demonstration of the VMR in use by sample application is available here : [Openshift VMR Demo](demo/)