# VMR in Openshift

This repository contains Openshift templates to use the VMR in Openshift.  It also contains a template to demonstrate
the VMR used by a Demo application to distribute work to workers.

## Overview

This demonstration consists of a single VMR used by two different Java Sprint Boot applications :
  * An aggregator which generates units of work.  A Unit of Work describes a task that takes some time to complete.
  * A worker which executes the task described by a unit of work.  When a task completes its unit of work is deemed
    consumed and is removed from the queue.

## Application's Architecture

![Architecture Diagram](https://github.com/SolaceLabs/solace-messaging-demo/blob/master/resources/demo-overview.png)

The Aggregator is a singleton process, there will only be one instance of it running.  It serves a Web Application over
port 8080 where the user will create the unit of work to be executed.  The unit of work are simply dummy work unit
implemented as a sleep for the amount of time specified by the user.

The worker is horizontally scalable and a system's throughput (A metric measured in Unit of Work per second) will scale
linearly with the number of worker instances.  This process offers no web interface and the user do not interact with it
directly.

The VMR is used as a load balancer of Work Units that guarantees delivery of work.  This is done via a non-exclusive
queue to which the aggregator publishes Units of Work each serialized as a message.  The queue will then distribute the
unit of work to the workers.  While the VMR distributes messages from the queue to consumers in a fair matter, the 
distribution of work is done in no particular pattern and is affected by the worker's performance. 

## Openshift Project Architecture

![Diagram of the Openshift VMR Demo Project](/resources/demo-openshift-project-diagram.png)

The Aggregator will be reached from HTTPS request made from external users.  The Aggregator route will expose the
aggregator as a HTTPS hostname.  The Aggregator service allows the route to reach the Pod hosting the Aggregator.  The
aggregator initiates a TCP connection to the VMR Service's IP in order to reach the VMR.

The Worker processes each runs in their own pod.  They initiates a TCP connection to the VMR Service's IP in order to
reach the VMR.

The Aggregator and Workers processes will exchange information thru messaging done thru the VMR.

The VMR will be hosted in a Pod and its services are exposed by the VMR Service.  

## Prerequisites

* Access to an Openshift environment
* Have cluster admin privileges (Or ask someone to add anyuid and privileged SCCs to your project's service account)
* The VMR docker container (Available here : [Solace Downloads Page](http://dev.solace.com/downloads/), under Docker in "VMR Community Edition")
* Have an administrator make the internal registry externally accessible :

```
oc expose service docker-registry -n default
```

## Steps

The steps in this section can be executed automatically with the following script :

```
./deploy.sh <ssh-host> <project-name> <openshift-domain>
```
IE:
```
./deploy.sh ec2-user@master.openshift.example.com demo-project openshift.example.com
```

### Setup a new project

It is assumed that you have logged in to Openshift :
```
oc login <host>:<port> --username=<user> --password=<password>
```

The first step consists of creating the Openshift project for our demo application.  This command will create the
project :

```
oc new-project vmr-openshift-demo
```

Then the project needs the `privileged` and `anyuid` SCCs assigned to the service account.  This will allow the VMR
to run its processes as root and have privileged access (Required by the fact that we will mount an external tmpfs
on /dev/shm) :
```
oadm policy add-scc-to-user privileged system:serviceaccount:vmr-openshift-demo:default
oadm policy add-scc-to-user anyuid system:serviceaccount:vmr-openshift-demo:default
```

### Upload the VMR docker image to Openshift's internal docker registry

Pushing the docker image to the internal registry requires the use of a machine running docker (IE. Docker machine).
The image is then loaded locally, and tagged as a repository image.  Then login to the Openshift registry and push
the image using these commands :

```
docker load -i <image>.tar.gz
docker login --username=<user> --password=`oc whoami -t` docker-registry-default.<domain>
docker tag solace-app:<version-tag> docker-registry-default.<domain>/vmr-openshift-demo/solace-app:latest
docker push docker-registry-default.<domain>/vmr-openshift-demo/solace-app
```

### Learning the image stream fully qualified name

After pushing the image to Openshift it is necessary to know the cluster IP of the docker registry :
```
oc get imagestreams solace-app
```

This will output something like this :
```
NAME         DOCKER REPO                                      TAGS      UPDATED
solace-app   172.30.3.53:5000/vmr-openshift-demo/solace-app   latest    About an hour ago
```

The IP portion `172.30.3.53:5000` is specific to the environment and will be different in your case.  Note the
full name, IE : here it is VMR_IMAGE = `172.30.3.53:5000/vmr-openshift-demo/solace-app`

### Create the Java App S2I ImageStream

Compiling the demonstration software will require a S2I (Source to Image) docker image.  This can be created from
a public repository by running this command :

```
oc create -f https://raw.githubusercontent.com/jorgemoralespou/s2i-java/master/ose3/s2i-java-imagestream.json
```

### Upload the demonstration's template

Running this command will create the 'solace-springboot-messaging-sample' template in the project:

```
oc create -f solace-messaging-demo-template.yml
```

### Using the template

The template can be used to instantiate the system and all of its components with this command :

Replace `172.30.3.53:5000/vmr-openshift-demo/solace-app` with the actual value from the
[Learning the image stream fully qualified name](#Learning-the-image-stream-fully-qualified-name) section. Also replace
openshift.example.com your wildcard subdomain (The wildcard DNS entry).

```
oc process solace-springboot-messaging-sample VMR_IMAGE=172.30.3.53:5000/vmr-openshift-demo/solace-app APPLICATION_SUBDOMAIN=openshift.example.com | oc create -f -
```

## Template description

Templates are explained on the Openshift official documentation web site.  Templates are explained on that web site at
[this location](https://docs.openshift.org/latest/dev_guide/templates.html).

The template is used to automate the creation of these objects :
* A BuildConfig for the aggregator app.  It defines where the source code is and the output ImageStream.
* A BuildConfig for the worker app.
* An ImageStream for the aggregator app.  This will contain the image produced by the aggregator app's builds.
* An ImageStream for the worker app.
* A DeploymentConfig for the VMR.  This defines a template of a VMR pod.  A deployment will then instantiate this
  template into an actual VMR Pod.  The Pod contains all the container settings for the VMR.
* A DeploymentConfig for the aggregator app.
* A DeploymentConfig for the worker app.
* A Service for the VMR.  The service fronts a group of pods providing the same service over a set of TCP ports.  The 
  Service have a single cluster IP associated to it, and a hostname.  The applications needing the service will connect
  to the hostname of the service instead of connection directly to the pods offering the service.  The service can
  load balance connections, and failover to pods that are healthy.
* A service for the aggregator application.  The aggregator application serves a web app over port 8080 and this service
  fronts that.
* A route for the aggregator application.  The route will proxy requests from the route's hostname to the aggregator
  service, to be handled by the aggregator pod.

The template also defines parameters that can be customized :

| Parameter                    | Description |
| ---------------------------- | ----------- |
| APPLICATION_NAME             | The name of the application.  This is used to prefix the name of objects created. |
| APPLICATION_SUBDOMAIN        | The application's subdomain.  The application will be available at https://aggregator.<APPLICATION_SUBDOMAIN>.  Make sure this FQDN exists in DNS. |
| GIT_URI                      | The git URI of the repository containing the demonstration's application. |
| GIT_REF                      | The branch or commit hash to use. |
| GIT_SECRET                   | The name of the secret to login to git. |
| GITHUB_TRIGGER_SECRET        | Trigger secret from Github.  Optional. |
| GENERIC_TRIGGER_SECRET       | Generic trigger secret.  Optional. |
| ADMIN_USER                   | The username of the initial CLI user created at VMR startup. |
| ADMIN_PASSWORD               | The password of the initial CLI user created at VMR startup. |

### Template header and metadata

The template yaml file starts with the header and metadata.  Here we specify that the object is a template and then
assign metadata to that template.

```
apiVersion: v1
kind: Template
metadata:
  name: solace-springboot-messaging-sample
  namespace: vmr-openshift-demo
  annotations:
    description: Sample Spring Boot Application that demonstrate messaging with the Solace VMR
    iconClass: icon-jboss
    tags: 'instant-app,springboot,gradle,java'
```

### Object list

The template defines a list of objects that must be instantiated when the template is used.  The list of objects is
defined by the `objects:` section.

### BuildConfig

The first two objects in the `objects:` section are BuildConfigs.  A BuildConfig describe how to build an image from
source code.  The Openshift documentation explains BuildConfig
[here](https://docs.openshift.com/container-platform/3.4/dev_guide/builds/index.html).

These are the two buildconfig used by this template :
```
  - kind: BuildConfig
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-aggregator'
    spec:
      triggers:
        - type: GitHub
          github:
            secret: '${GITHUB_TRIGGER_SECRET}'
        - type: Generic
          generic:
            secret: '${GENERIC_TRIGGER_SECRET}'
        - type: ImageChange
          imageChange: {}
      source:
        type: Git
        git:
          uri: '${GIT_URI}'
          ref: '${GIT_REF}'
        contextDir: 'aggregator'
      strategy:
        type: Source
        sourceStrategy:
          from:
            kind: ImageStreamTag
            name: 's2i-java:latest'
      output:
        to:
          kind: ImageStreamTag
          name: '${APPLICATION_NAME}-aggregator:latest'
      resources: {}
  - kind: BuildConfig
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-worker'
    spec:
      triggers:
        - type: GitHub
          github:
            secret: '${GITHUB_TRIGGER_SECRET}'
        - type: Generic
          generic:
            secret: '${GENERIC_TRIGGER_SECRET}'
        - type: ImageChange
          imageChange: {}
      source:
        type: Git
        git:
          uri: '${GIT_URI}'
          ref: '${GIT_REF}'
        contextDir: 'worker'
      strategy:
        type: Source
        sourceStrategy:
          from:
            kind: ImageStreamTag
            name: 's2i-java:latest'
      output:
        to:
          kind: ImageStreamTag
          name: '${APPLICATION_NAME}-worker:latest'
      resources: {}
```

This defines the build for these application : The worker and the aggregator (As described in the
[Application's Architecture](#Application's-Architecture) section).  Note that there are no default Source-to-image
ImageStream that can build a standard java application based on Maven or Gradle.  Thus it was necessary to use a custom
source-to-image ImageStream : `s2i-java:latest`.  Section
[Create the Java App S2I ImageStream](#Create-the-Java-App-S2I-ImageStream) explains how that ImageStream was added to
the project, so that this template can use it.  Those BuildConfig defines which repository are hosting the
source code to be built.  Since both applications lives in the same repository, both BuildConfig refer to the same
repository : `${GIT_URI}` and `${GIT_REF}` (Which defines which commit/branch/tag to get).  Both applications lives in
their own subdirectory in that repo, and each BuildConfig will define the subdirectory via the `contextDir` attribute.
The `output:` section defines the output ImageStream that receives the Build output which is in fact a Docker Image
packing the built application.  This ImageStream can then be used by other parts of the template, to instantiate 
containers running the application.

### ImageStreams 

This part of the template simply create two ImageStreams to receive the Docker images produced by the BuildConfig
described in the [previous section](#BuildConfig).

```
  - kind: ImageStream
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-aggregator'
    spec:
      dockerImageRepository: ''
      tags:
        - name: latest
  - kind: ImageStream
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-worker'
    spec:
      dockerImageRepository: ''
      tags:
        - name: latest
```

### Deployment Config for Solace's VMR

A deployment describes how an application must be deployed in Openshift.  More information on them can be found
[here](https://docs.openshift.com/container-platform/3.4/dev_guide/deployments/how_deployments_work.html) on Openshift's
official documentation website.

Solace's VMR requires the `recreate` strategy.  To upgrade, or replace the VMR, the old pod must be destroyed before the
replacement pod starts.  This means that the `rolling` strategy cannot work for the VMR.  The POD that is declared
by this DeploymentConfig will run a VMR container.  How this container must be setup is explained [here](/readme.md).

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
                value: 'message_routing'
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

### VMR Service

Since a Pod's IP is not permanent having applications how about each Pod IPs address is not practical.  Applications
thus connect to pod indirectly thru an object called `service` which are documented
[here](https://kubernetes.io/docs/concepts/services-networking/service/) on Kubernete's official website.  A service
act as a proxy between applications and the Pod offering a service.  A service also have a name and Kubernetes define
will resolve the service's name to the service's IP.  The service IP is virtual as IP tables rules will translate that IP
into a pod's internal IP in the PREROUTING table.

Thus applications using the VMRwill simply connect to this hostname `${APPLICATION_NAME}-vmr`, and under the hood, a
Kubernetes ensure that iptables always route requests to the VMR pod.  The service listen on these ports :
* 443 (Web Messaging)
* 80 (SSL Web Messaging)
* 8080 (SEMP)
* 8443 (SSL SEMP)
* 55555 (Messaging)
* 22 (Management CLI access via SSH)

```
  - kind: Service
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-vmr'
      annotations:
        description: 'Exposes the VMR services'
    spec:
      ports:
      - name: 'semp'
        port: 8080
        targetPort: 8080
      - name: 'semp-secure'
        port: 943
        targetPort: 943
      - name: 'smf'
        port: 55555
        targetPort: 55555
      - name: 'smf-zip'
        port: 55003
        targetPort: 55003
      - name: 'smf-routing'
        port: 55556
        targetPort: 55556
      - name: 'smf-secure'
        port: 55443
        targetPort: 55443
      - name: 'smf-http'
        port: 80
        targetPort: 80
      - name: 'smf-https'
        port: 443
        targetPort: 443
      - name: 'mqtt'
        port: 1883
        targetPort: 1883
      - name: 'mqtt-secure'
        port: 8883
        targetPort: 8883
      - name: 'mqtt-http'
        port: 8000
        targetPort: 8000
      - name: 'mqtt-https'
        port: 8443
        targetPort: 8443
      - name: 'rest'
        port: 9000
        targetPort: 9000
      - name: 'rest-secure'
        port: 9443
        targetPort: 9443
      - name: 'ssh'
        port: 22
        targetPort: 22
      selector:
        deploymentconfig: '${APPLICATION_NAME}-vmr'
      type: ClusterIP
      sessionAffinity: None
```

### Demo application's deployments

One DeploymentConfig are defined for the aggregator, and also for the worker:

```
  - kind: DeploymentConfig
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-aggregator'
    spec:
      strategy:
        type: Rolling
        rollingParams:
          updatePeriodSeconds: 1
          intervalSeconds: 1
          timeoutSeconds: 600
        resources: {}
      triggers:
        - type: ConfigChange
        - type: ImageChange
          imageChangeParams:
            automatic: true
            containerNames:
              - '${APPLICATION_NAME}-aggregator'
            from:
              kind: ImageStreamTag
              name: '${APPLICATION_NAME}-aggregator:latest'
      replicas: 1
      selector:
        deploymentconfig: '${APPLICATION_NAME}-aggregator'
      template:
        metadata:
          labels:
            deploymentconfig: '${APPLICATION_NAME}-aggregator'
        spec:
          containers:
            - name: '${APPLICATION_NAME}-aggregator'
              image: '${APPLICATION_NAME}-aggregator'
              ports:
                - containerPort: 8090
                  protocol: TCP
              env:
              - name: 'solace_java_host'
                value: '${APPLICATION_NAME}-vmr'
              - name: 'solace_java_msgVpn'
                value: 'default'
              - name: 'solace_java_clientUsername'
                value: 'default'
              - name: 'solace_java_clientPassword'
                value: 'default'
              livenessProbe:
                tcpSocket:
                  port: 8090
                initialDelaySeconds: 30
                timeoutSeconds: 1
              resources: {}
              terminationMessagePath: /dev/termination-log
              imagePullPolicy: IfNotPresent
              securityContext:
                capabilities: {}
                privileged: false
          restartPolicy: Always
          dnsPolicy: ClusterFirst
  - kind: DeploymentConfig
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-worker'
    spec:
      strategy:
        type: Rolling
        rollingParams:
          updatePeriodSeconds: 1
          intervalSeconds: 1
          timeoutSeconds: 600
        resources: {}
      triggers:
        - type: ConfigChange
        - type: ImageChange
          imageChangeParams:
            automatic: true
            containerNames:
              - '${APPLICATION_NAME}-worker'
            from:
              kind: ImageStreamTag
              name: '${APPLICATION_NAME}-worker:latest'
      replicas: 1
      selector:
        deploymentconfig: '${APPLICATION_NAME}-worker'
      template:
        metadata:
          labels:
            deploymentconfig: '${APPLICATION_NAME}-worker'
        spec:
          containers:
            - name: '${APPLICATION_NAME}-worker'
              image: '${APPLICATION_NAME}-worker'
              env:
              - name: 'solace_java_host'
                value: '${APPLICATION_NAME}-vmr'
              - name: 'solace_java_msgVpn'
                value: 'default'
              - name: 'solace_java_clientUsername'
                value: 'default'
              - name: 'solace_java_clientPassword'
                value: 'default'
              resources: {}
              terminationMessagePath: /dev/termination-log
              imagePullPolicy: IfNotPresent
              securityContext:
                capabilities: {}
                privileged: false
          restartPolicy: Always
          dnsPolicy: ClusterFirst
```

### Route

The aggregator must expose its web UI to the public network.  To do so, it exposes a route, which the router will 
forward to the aggregator.  The router will look at the HTTP host, or `SNI` for the case of HTTPS.

Routes are documented [here](https://docs.openshift.com/container-platform/3.4/architecture/core_concepts/routes.html)
on Openshift's official documentation website.

The route for the aggregator will have the `aggregator.${APPLICATION_SUBDOMAIN}` hostname.  And the router will route
HTTPS requests sent there to the service with the `deploymentconfig: '${APPLICATION_NAME}-aggregator'` selector.

```
  - kind: Route
    apiVersion: v1
    metadata:
      name: '${APPLICATION_NAME}-aggregator'
    spec:
      host: 'aggregator.${APPLICATION_SUBDOMAIN}'
      to:
        kind: Service
        name: 'aggregator'
      tls:
        termination: edge
      wildcardPolicy: None
  - kind: Service
    apiVersion: v1
    metadata:
      name: 'aggregator'
    spec:
      ports:
        - name: '${APPLICATION_NAME}-aggregator-http'
          port: 8090
          targetPort: 8090
      selector:
        deploymentconfig: '${APPLICATION_NAME}-aggregator'
      type: ClusterIP
      sessionAffinity: None
```

### Template parameters 

Finally at the end of the template, we have all the parameters that the user can use to control aspects of the project
that is instantiated by the tamplate:

| Parameter              | Description                                                                                                                                                                                                                                          | Default value                                           |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| APPLICATION_NAME       | The name of the application.  This will be prefixing the names of the objects created by this template.                                                                                                                                              | messaging-sample                                        |
| APPLICATION_SUBDOMAIN  | The subdomain assigned to the application.  DNS entries must already have been provisioned in this subdomain for the application's route to work.                                                                                                    | openshift.example.com                                   |
| VMR_IMAGE              | The ImageStream that contains the VMR docker image.  Docker-machine can be used to push the VMR docker image to the project.  Note that the default value must be adjusted to match your environment's Docker registry clusterIP.                    | 172.30.3.53:5000/vmr-openshift-demo/solace-app          |
| GIT_URI                | The location of the Aggregator and Worker applications.  The default value shouldn't be changed, unless you want to use a fork instead to experiment.                                                                                                | https://github.com/SolaceLabs/solace-messaging-demo.git |
| GIT_REF                | Defines which branch, tag or commit to checkout.                                                                                                                                                                                                     | master                                                  |
| ADMIN_USER             | Defines the initial administrative user of the VMR.                                                                                                                                                                                                  | admin                                                   |
| ADMIN_PASSWORD         | Defines the initial password of the administrative user of the VMR.                                                                                                                                                                                  | admin                                                   |

This part of the template describes these parameters :

```
parameters:
  - name: APPLICATION_NAME
    displayName: Application name
    description: The name for the application.
    value: messaging-sample
    required: true
  - name: APPLICATION_SUBDOMAIN
    displayName: Application subdomain
    description: >-
      Custom subdomain for service routes.  Leave blank for default subdomain,
      This template creates two routes : aggregator.<subdomain> and workers.<subdomain>
    value: openshift.example.com
  - name: VMR_IMAGE
    displayName: VMR Image
    description: >-
      Fully qualified VMR image name.
    value: 172.30.3.53:5000/vmr-openshift-demo/solace-app
  - name: GIT_URI
    description: Git source URI for application
    value: 'https://github.com/SolaceLabs/solace-messaging-demo.git'
  - name: GIT_REF
    description: Git branch/tag reference
    value: master
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

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceLabs/solace-openshift-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## References

Here are some interesting links if you're new to these concepts:

* [The Solace Developer Portal](http://dev.solace.com/)
* [Openshift's Core concepts](https://docs.openshift.com/container-platform/3.4/architecture/core_concepts/index.html)
* [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
* [Docker Machine Overview](https://docs.docker.com/machine/overview/)
