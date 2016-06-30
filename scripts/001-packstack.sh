#!/bin/bash

# This script assumes a single node packstack install.
# The packstack hostname should be packstack.local
# The ONOS host should be onos.local
# These should either be in the /etc/hosts or via an upstream DNS server; we use SKYDNS within the Harbor Platform


# First install the ONOS ML2 Driver
git clone https://github.com/openstack/networking-onos.git ~/networking-onos
cd ~/networking-onos
python setup.py install


# Get Neutron to use the ONOS Driver
Q_ML2_PLUGIN_MECHANISM_DRIVERS=onos_ml2
ML2_L3_PLUGIN=networking_onos.plugins.l3.driver.ONOSL3Plugin
sed -i 's/mechanism_drivers =openvswitch/mechanism_drivers = onos_ml2/'/etc/neutron/plugin.ini
sed -i "s/interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/interface_driver = ${ML2_L3_PLUGIN}/" /etc/neutron/l3_agent.ini


# Append the ONOS config to the Neutron Plugin config - though it is better to put this in its own file, its easier to just append this when developing with packstack.
cat >> /etc/neutron/plugin.ini <<EOF
#Configuration options for ONOS driver
[onos]

# (StrOpt) ONOS ReST interface URL. This is a mandatory field.
url_path = http://onos.local:8181/onos/openstackswitching

# (StrOpt) Username for authentication. This is a mandatory field.
username = onos

# (StrOpt) Password for authentication. This is a mandatory field.
password = rocks
EOF


# Lets get rid of the services we dont need (For now)
systemctl stop neutron-openvswitch-agent neutron-l3-agent neutron-metering-agent.service neutron-ovs-cleanup neutron-metadata-agent neutron-dhcp-agent
systemctl disable neutron-openvswitch-agent neutron-l3-agent neutron-metering-agent.service neutron-ovs-cleanup neutron-metadata-agent neutron-dhcp-agent
systemctl mask neutron-openvswitch-agent neutron-l3-agent neutron-metering-agent.service neutron-ovs-cleanup neutron-metadata-agent neutron-dhcp-agent


# It makes life much easier to start out with an fresh DB (As we know that any issues are new, rather than old skeletons coming out)
mysql <<EOF
DROP DATABASE IF EXISTS neutron;
CREATE DATABASE IF NOT EXISTS neutron DEFAULT CHARACTER SET utf8 ;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '02238a50d30f4579' ;
EOF
neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head


# Restart all the non-masked Neutron services
systemctl restart neutron*


