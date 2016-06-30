#!/bin/bash

# This script sets up ONOS SONA, it should be run from the packstack node to auto populate ip addreses and passwords

# Source Packstack config
source ~/answers.txt

OPENSTACK_NODE_MANAGEMENT_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
OPENSTACK_NODE_PUBLIC_IP=$(ip -f inet -o addr show eth1|cut -d\  -f 7 | cut -d/ -f 1)

cat > /tmp/network-cfg.json << EOF
{
    "apps" : {
        "org.onosproject.openstacknode" : {
            "openstacknode" : {
                "nodes" : [
                            {
                                    "hostname" : "packstack.local",
                                    "ovsdbIp" : "${OPENSTACK_NODE_MANAGEMENT_IP}",
                                    "ovsdbPort" : "6640",
                                    "bridgeId" : "of:0000000000000001",
                                    "openstackNodeType" : "COMPUTENODE"
                            }
                ]
            }
        }
    }
}
EOF
curl --user onos:rocks -X POST -H "Content-Type: application/json" http://onos.local:8181/onos/v1/network/configuration/ -d @/tmp/network-cfg.json


cat > /tmp/network-cfg.json << EOF
{
    "apps" : {
        "org.onosproject.openstackinterface" : {
            "openstackinterface" : {
                 "neutronServer" : "http://${OPENSTACK_NODE_PUBLIC_IP}:9696/v2.0/",
                 "keystoneServer" : "http://${OPENSTACK_NODE_PUBLIC_IP}/v2.0/",
                 "userName" : "${CONFIG_KEYSTONE_ADMIN_USERNAME}",
                 "password" : "${CONFIG_KEYSTONE_ADMIN_PW}"
            }
        }
   }
}
EOF
curl --user onos:rocks -X POST -H "Content-Type: application/json" http://onos.local:8181/onos/v1/network/configuration/ -d @/tmp/network-cfg.json




cat > /tmp/config.json << EOF
{
    "userDefined" : {
      "openstacknetworking" : {
        "config" : {
          "nodes" : [
            {
              "dataPlaneIp" : "${OPENSTACK_NODE_MANAGEMENT_IP}",
              "bridgeId" : "of:0000000000000001"
            }
          ]
        }
      }
    },
    "apps" : {
        "org.onosproject.openstackinterface" : {
            "openstackinterface" : {
                 "neutronServer" : "http://10.100.1.201:9696/v2.0/",
                 "keystoneServer" : "http://10.100.1.201:5000/v2.0/",
                 "userName" : "${CONFIG_KEYSTONE_ADMIN_USERNAME}",
                 "password" : "${CONFIG_KEYSTONE_ADMIN_PW}"
            }
        }
    },
    "devices" : {
        "of:0000000000000001" : {
            "basic" : {
                "driver" : "sona"
            }
        }
    }
}
EOF
curl --user onos:rocks -X POST -H "Content-Type: application/json" http://onos.local:8181/onos/v1/network/configuration/ -d @/tmp/config.json

