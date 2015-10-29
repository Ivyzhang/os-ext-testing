#! /usr/bin/env bash

# Sets up a log server for Jenkins to save test results to.

set -e


# TODO: Either edit the variables here and make sure the values are correct, or
# set them before running this script
: ${DOMAIN:=your.domain.com}
: ${JENKINS_SSH_PUBLIC_KEY:="~/.ssh/id_rsa.pub"}

PUPPET_MODULE_PATH="--modulepath=/etc/puppet/modules"

# Install Puppet
if [[ ! -e install_puppet.sh ]]; then
  wget https://git.openstack.org/cgit/openstack-infra/system-config/plain/install_puppet.sh
  sudo bash -xe install_puppet.sh
  sudo git clone https://review.openstack.org/p/openstack-infra/system-config.git \
    /root/system-config
  sudo /bin/bash /root/system-config/install_modules.sh
fi

CLASS_ARGS="domain => '$DOMAIN',
            jenkins_ssh_key => '$(cat ${JENKINS_SSH_PUBLIC_KEY} | cut -d ' ' -f 2)', "

set +e
sudo puppet apply --test $PUPPET_MODULE_PATH -e "class {'openstackci::logserver': $CLASS_ARGS }"
PUPPET_RET_CODE=$?
# Puppet doesn't properly return exit codes. Check here the values that
# indicate failure of some sort happened. 0 and 2 indicate success.
if [ "$PUPPET_RET_CODE" -eq "4" ] || [ "$PUPPET_RET_CODE" -eq "6" ] ; then
    echo "Puppet failed to apply the log server configuration."
    exit $PUPPET_RET_CODE
fi
set -e

exit 0
