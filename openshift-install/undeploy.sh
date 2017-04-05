#!/bin/bash
# <masterNodeSshHost>

source resources/common.sh

executeAnsibleScript $1 ec2-user /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml
