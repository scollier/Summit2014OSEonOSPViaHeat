#**Lab 4: Configure Neutron Networking**

##**4.1 Create Keypair**

All actions in this lab will performed by the *admin* tenant in this lab.  In a production enviroinment there will likely be many tenants.

    source /root/keystonerc_admin

Create a keypair and then list the key.

    nova keypair-add adminkp > /root/adminkp.pem && chmod 400 /root/adminkp.pem
    nova keypair-list



##**4.2 Set up Neutron Networking**

**Set up neutron networking**

        
###**Network Configuration Background**

In this lab there is an existing network, much as there would be in a production environment. This is a real, physical network with a gateway and DHCP server somewhere on the network that we do not have control over. Therefore we decided to use the *provider* extension for Neutron.  A *provider network* maps to an existing, physical network and allows administrators to manage additional attributes for these networks. This is enabled via the following option in the packstack answer file:

    CONFIG_NEUTRON_L3_EXT_BRIDGE=provider

A provider network was created via packstack named *physnet1*. This was specified in the following option:

    CONFIG_NEUTRON_OVS_VLAN_RANGES=physnet1:1113:1114

The VLAN ranges specified are optional and not used in this environment, only the network name *physnet1* matters here. Next the network *physnet1* was mapped to a bridge we called *br-em1* in the following option:

    CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=physnet1:br-em1

Lastly, this bridge *br-em1* was mapped to the physical interface *em1* in the following option:

    CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-em1:em1

###**Create the *Public* Network**

The network will be created using the *--provider* attributes *physical_network=physnet1* which we defined in packstack, and as the network is not using VLAN tags so it will be specified as *network_type flat*. Lastly, as there is a real, physical router on this network, also specify *--router:external=True*. This results in the following command:

    neutron net-create public --provider:physical_network=physnet1 --provider:network_type flat --router:external=True
        
List networks after creation

    neutron net-list

More detail is available with the *net-show* command.  If you have multiple networks with identical names, you must specify the UUID for the network instead of the name.
        
    neutron net-show public
        
Create the *public* subnet. Also specify an allocation pool of which floating IPs can be assigned. Without this option the entire subnet range will be used. Also specify the gateway here:
  
    neutron subnet-create public --allocation-pool start=172.10.1.1,end=172.10.1.20 \
        --gateway 172.10.0.1 --enable_dhcp=False 172.10.0.0/16 --name pub-sub    
        
List the subnets

    neutron subnet-list
        
Show more details about the *public* subnet.

    neutron subnet-show pub-sub

Update the *public* subnet with a valid DNS entry. **THIS WILL NEED TO BE MODIFIED, IT MAY NEED TO BE REMOVED, FOR OUR PURPOSES - VINNY, use 10.16.143.247**
        
    neutron subnet-update pub-sub --dns_nameservers list=true x.x.x.x

###**Create Private Network**

Create the *private* network that the virtual machines will be attached to. As this is an all-in-one configuration, use *network_type local*. A real production environment would use VLAN or tunnel technology such as GRE or VXLAN.

    neutron net-create private --provider:network_type local
        
List networks after creation.  This time you should see both **public** and **private**

    neutron net-list
        
Show more details about the private network.

    neutron net-show private
      
Create the private subnet

    neutron subnet-create private --gateway 192.168.0.1 192.168.0.0/24 --name priv-sub
        
List the subnets

    neutron subnet-list

Show more details about the *pivate* subnet.

    neutron subnet-show priv-sub

Create a router. This is a neutron router that will route traffic from the private network to the public network.
        
    neutron router-create router1

Set the gateway for the router to reside on the *public* subnet.
        
    neutron router-gateway-set router1 public

List the router.
        
    neutron router-list

Add an interface for the private subnet to the router.
        
    neutron router-interface-add router1 priv-sub

Display router1 configuration.

    neutron router-show router1
    
##**4.3 Configure the Neutron plugin.ini**

Ensure the */etc/neutron/plugin.ini* has this configuration at the bottom of the file in the [OVS] stanza. The key part is to ensure the *vxlan_udp_port* and *network_vlan_ranges* are commented out.

    # network_vlan_ranges=physnet1:1113:1114
    tenant_network_type=local
    enable_tunneling=False
    integration_bridge=br-int
    bridge_mappings=physnet1:br-em1

    
Reboot the server.

    reboot

**Lab 4 Complete!**

<!--BREAK-->

