#!/bin/bash
/bin/cp /etc/ssh/sshd_config /tmp/sshd_config.bk
/bin/sed -i -e "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
/bin/systemctl restart sshd

/bin/echo "${pass}" | passwd --stdin ec2-user

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json