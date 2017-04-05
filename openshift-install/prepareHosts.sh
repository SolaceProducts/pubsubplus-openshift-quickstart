#!/bin/bash

source resources/common.sh

echo "Please enter your redhat subscription account username> "
read sub_username
echo "Please enter your redhat subscription password> "
read sub_password

pushKey ec2-user $@

for host; do
  scp -oStrictHostKeyChecking=no -i id_rsa resources/*sh ec2-user@$host:~
  ssh -oStrictHostKeyChecking=no -i id_rsa ec2-user@$host "sudo -- sh -c 'cd /home/ec2-user;./prepareHost.sh /dev/xvdb $sub_username $sub_password'"
done
