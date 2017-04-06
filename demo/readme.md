# VMR in Openshift

This repository contains Openshift templates to use the VMR in Openshift.  It also contains a template to demonstrate
the VMR used by a Demo application to distribute work to workers.

## Overview


This demonstration consists of a single VMR used by two different Java Sprint Boot applications :
  * An aggregator which generates units of work.  A Unit of Work describes a task that takes some time to complete.
  * A worker which executes the task described by a unit of work.  When a task completes its unit of work is deemed
    consumed and is removed from the queue.

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

## Prerequesites

* Access to an Openshift environment
* Have cluster admin privileges (Or ask someone to add anyuid and privileged SCCs to your project's service account)
* Have an administrator make the internal registry externally accessible :
* The VMR docker container (Available here : http://dev.solace.com/downloads/, under Docker in "VMR Community Edition")

```
oc expose service docker-registry -n default
```

## Steps

It is assumed that you have logged in to Openshift :
```
oc login <host>:<port> --username=<user> --password=<password>
```

### Setup a new project

The first step consists of creating the Openshift project for our demo application.  This commands will create the
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

Replace `172.30.3.53:5000/vmr-openshift-demo/solace-app` with the actual value from the [Learning the image stream fully qualified name](#Learning-the-image-stream-fully-qualified-name) section.
Also replace openshift.example.com your wildcard subdomain (The wildcard DNS entry).

```
oc process solace-springboot-messaging-sample VMR_IMAGE=172.30.3.53:5000/vmr-openshift-demo/solace-app APPLICATION_SUBDOMAIN=openshift.example.com | oc create -f -
```

### Template description

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
