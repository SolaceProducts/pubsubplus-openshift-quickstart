#!/bin/bash

# promptYesNo <message>
function promptYesNo() {
    read -r -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# executeAnsibleScript <host> <user> <path/to/playbook>
function executeAnsibleScript() {
    scp -oStrictHostKeyChecking=no -i id_rsa hosts ca.crt server-cert.key server-cert.pem $2@$1:~
    ssh -oStrictHostKeyChecking=no -i id_rsa $2@$1 "sudo cp hosts /etc/ansible/hosts; ansible-playbook -e 'host_key_checking=False' $3"
}

function resolveIp() {
    $(dig +short $1 | grep -E '^[0-9.]+$' | head -n 1)
}

# setupDockerStorage <docker-storage-device>
function setupDockerStorage() {

cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=$1
VG=docker-vg
EOF

    docker-storage-setup
}

function enableDocker() {
    systemctl enable docker
    systemctl start docker
}

# pushKeys <username> <host1> <host2> <host n...>
function pushKey() {
    for host in ${@:2}; do
      scp -oStrictHostKeyChecking=no -i id_rsa id_rsa $1@$host:~/.ssh/id_rsa
    done
}

function installOpenshiftPackages() {
    # Installs all packages required by openshift enterprise advanced installation
    yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion
    yum update -y
    yum install -y atomic-openshift-utils
    yum install -y atomic-openshift-excluder atomic-openshift-docker-excluder
    atomic-openshift-excluder unexclude

    # install docker
    yum install -y docker
    sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker
}

# registerHost <rhel-subscription-username> <rhel-subscription-password>
function registerHost() {
    subscription-manager register --force --username=$1 --password=$2
    subscription-manager attach --pool=8a85f981588ca7020158910f6fa1079b
    subscription-manager repos --disable="*"
    subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.4-rpms"
}

# setupHost <docker-storage-device> <rhel-subscription-username> <rhel-subscription-password>
function setupHost() {
    registerHost $2 $3
    installOpenshiftPackages
    setupDockerStorage $1
    enableDocker
}