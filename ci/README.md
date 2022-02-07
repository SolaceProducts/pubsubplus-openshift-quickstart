The scripts in this folder are used for CI, based on [RedHat CRC](https://developers.redhat.com/products/codeready-containers/overview)

Assumptions: VM `openshift4x-test` in GCP with `vagrant` user, `crc` installed, `/opt` directory exists with file `pullsecret` that contains valid contents. `/opt/scripts` and `/opt/templates` directories exist (no content needed). Generally, `crc` works in this container.

# How to verify the VM is in good standing

Perform following:

* Ensure the `openshift4x-test` VM in GCP is in running state.
* Login as `gcloud beta compute ssh --zone "us-east4-a" "vagrant@openshift4x-test"  --project "capable-stream-180018"`. This will login as user `vagrant`.
* Run following scripts - none of then shall fail
```
cd /opt
./scripts/shutdownCrc
./scripts/startCrc
./scripts/helmInstallBroker test1
./scripts/templateDeleteBroker test1
./scripts/shutdownCrc
```
* If all is well the stop the VM. Automated tests will quit if the VM is already running, assuming it is used for other purposes.

# How to upgrade the test container to latest CRC version

If `crc` requires update for a later OpenShift version:

* Login as user `vagrant` to the running VM as above
* Follow section 2.4. Upgrading CodeReady Containers from https://access.redhat.com/documentation/en-us/red_hat_codeready_containers, Getting Started Guide. Untar then overwrite the existing `crc` command at `/usr/local/bin/crc`
* Upgrade the `/usr/local/bin/oc` command similarly if required.
* Run
```
crc version
crc stop
crc setup
```
* Fix any issues
* Proceed to verify the VM as in the previous section

# Restore from disaster

A machine image has been saved at https://console.cloud.google.com/compute/machineImages/details/openshift4x-test-backup?authuser=0&project=capable-stream-180018.

Note the machine type must support virtualization: `n1-standard-8`
