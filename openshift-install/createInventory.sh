#!/bin/bash

source resources/common.sh

echo "Enter public hostname for the master node>"
read MASTER_PUBLIC_HOSTNAME

if [[ -z "$MASTER_PUBLIC_HOSTNAME" ]]; then
    echo "Master public hostname cannot be blank!"
    exit 1
fi
MASTER_PUBLIC_IP=$(dig +short $MASTER_PUBLIC_HOSTNAME | grep -E '^[0-9.]+$' | head -n 1)
if [[ -z "$MASTER_PUBLIC_IP" ]]; then
    echo "Master public hostname cannot be resolved to an IP!"
    exit 1
fi
echo "Public IP Address for master node is $MASTER_PUBLIC_IP"

echo "Enter private hostname for the master node>"
read MASTER_PRIVATE_HOSTNAME

if [[ -z "$MASTER_PRIVATE_HOSTNAME" ]]; then
    echo "Master public hostname cannot be blank!"
    exit 1
fi
MASTER_PRIVATE_IP=$(dig +short $MASTER_PRIVATE_HOSTNAME | grep -E '^[0-9.]+$' | head -n 1)
if [[ -z "$MASTER_PRIVATE_IP" ]]; then
    echo "Master private hostname cannot be resolved to an IP!"
    exit 1
fi
echo "Private IP Address for master node is $MASTER_PRIVATE_IP"


echo "Enter the default subdomain for routes>"
read DEFAULT_SUBDOMAIN

if [[ -z "$DEFAULT_SUBDOMAIN" ]]; then
    echo "Default subdomain cannot be blank!"
    exit 1
fi


# Start creating the hosts file with the master node information.
cat <<EOF > hosts
[OSEv3:children]
masters
nodes

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
ansible_ssh_user=ec2-user
ansible_become=true
deployment_type=openshift-enterprise

os_sdn_network_plugin_name=redhat/openshift-ovs-subnet
openshift_use_openshift_sdn=True
osm_cluster_network_cidr=10.1.0.0/16
openshift_master_portal_net=172.30.0.0/16

openshift_master_named_certificates=[{"certfile": "/home/ec2-user/server-cert.pem", "keyfile": "/home/ec2-user/server-cert.key", "cafile": "/home/ec2-user/ca.crt"}]

openshift_master_cluster_hostname=$MASTER_PRIVATE_HOSTNAME
openshift_master_cluster_public_hostname=$MASTER_PUBLIC_HOSTNAME
openshift_master_default_subdomain=$DEFAULT_SUBDOMAIN
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

[masters]
$MASTER_PRIVATE_HOSTNAME openshift_hostname=$MASTER_PRIVATE_HOSTNAME openshift_public_hostname=$MASTER_PUBLIC_HOSTNAME openshift_ip=$MASTER_PRIVATE_IP openshift_public_ip=$MASTER_PUBLIC_IP

[nodes]
$MASTER_PRIVATE_HOSTNAME openshift_hostname=$MASTER_PRIVATE_HOSTNAME openshift_public_hostname=$MASTER_PUBLIC_HOSTNAME openshift_ip=$MASTER_PRIVATE_IP openshift_public_ip=$MASTER_PUBLIC_IP openshift_node_labels="{'region':'infra','zone':'default'}" openshift_schedulable=true
EOF


NODENUM=1
HOSTNAME="1"
while true; do
    promptYesNo "Do you want to provision node $NODENUM?" || break

    echo "Enter public hostname for node $NODENUM>"
    read PUBLIC_HOSTNAME
    if [[ -z "$PUBLIC_HOSTNAME" ]]; then
        echo "Public hostname cannot be blank!"
        exit 1
    fi
    PUBLIC_IP=$(dig +short $PUBLIC_HOSTNAME | grep -E '^[0-9.]+$' | head -n 1)
    if [[ -z "$PUBLIC_IP" ]]; then
        echo "Public hostname cannot be resolved to an IP!"
        exit 1
    fi
    echo "Public IP Address for node $NODENUM is $PUBLIC_IP"

    echo "Enter private hostname for node $NODENUM>"
    read PRIVATE_HOSTNAME
    if [[ -z "$PRIVATE_HOSTNAME" ]]; then
        echo "Private hostname cannot be blank!"
        exit 1
    fi
    PRIVATE_IP=$(dig +short $PRIVATE_HOSTNAME | grep -E '^[0-9.]+$' | head -n 1)
    if [[ -z "$PRIVATE_IP" ]]; then
        echo "Private hostname cannot be resolved to an IP!"
        exit 1
    fi
    echo "Private IP Address for node $NODENUM is $PRIVATE_IP"

    NODENUM=$(($NODENUM+1))

cat <<EOF >> hosts
$PRIVATE_HOSTNAME openshift_hostname=$PRIVATE_HOSTNAME openshift_public_hostname=$PUBLIC_HOSTNAME openshift_ip=$PRIVATE_IP openshift_public_ip=$PUBLIC_IP openshift_node_labels="{'region':'primary','zone':'default'}"
EOF

done