#**Lab 4: Configure Neutron Networking**

##**4.1 Create Keypair**

All actions in this lab will performed by the *admin* tenant in this lab.  In a production enviroinment there will likely be many tenants.

    source /root/keystonerc_admin

Create a keypair and then list the key.

    nova keypair-add rootkp > /root/rootkp.pem && chmod 400 /root/rootkp.pem
    nova keypair-list



##**4.2 Set up Neutron Networking**

**Set up the neutron networking.**

        
Create the *public* network. In the packstack answer file we specified the name *physnet1* for the physical external network.  INSERT VINNY HERE - ack - vvaldez

    neutron net-create public --provider:physical_network=physnet1 --provider:network_type flat --router:external=True
        
List the network after creation.

    neutron net-list

Show the public network.  If you have networks that are named the same thing, you can specify the UUID for the network instead of the name.
        
    neutron net-show public
        
Create the *private* network that the virtual machines will be deployed to.

    neutron net-create private --provider:network_type local
        
List the network after creation.  This time you should see both **public** and **private**

    neutron net-list
        
Show more details about the private network.

    neutron net-show private
      
Create the *public* subnet. This command also creates a pool of IP addresses that will be *floating* IP addresses.  In addition, set up the gateway here.
  
    neutron subnet-create public --allocation-pool start=x.x.x.x,end=x.x.x.x \
    --gateway x.x.x.x --enable_dhcp=False x.x.x.0/x --name pub-sub
        
List the *public* subnet.

    neutron subnet-list
        
Show more details about the *public* subnet.

    neutron subnet-show pub-sub

Create the private subnet.       

    neutron subnet-create private --gateway 192.168.0.1 192.168.0.0/24 --name priv-sub
        
List the *private* subnet.

    neutron subnet-list

Show more details about the *pivate* subnet.

    neutron subnet-show priv-sub

Create the router.
        
    neutron router-create router1

Set the gateway for the router to reside on the *public* subnet.
        
    neutron router-gateway-set router1 public

List the router.
        
    neutron router-list

Update the *public* subnet with a valid DNS entry. **THIS WILL NEED TO BE MODIFIED, IT MAY NEED TO BE REMOVED**
        
    neutron subnet-update pub-sub --dns_nameservers list=true 10.16.143.247

Add an interface for the private subnet to the router.
        
    neutron router-interface-add router1 priv-sub

Display router1 configuration.

    neutron router-show router1
    
##**4.3 Configure the Neutron plugin.ini**

Ensure the */etc/neutron/plugin.ini* has this configuration at the bottom of the file in the [OVS] stanza. The key part is to ensure the *vxlan_udp_port* and *network_vlan_ranges* are commented out.

    # vxlan_udp_port=4789
    # network_vlan_ranges=physnet1:1113:1114
    tenant_network_type=local
    enable_tunneling=False
    integration_bridge=br-int
    bridge_mappings=physnet1:br-em1


    
Reboot the server.

    reboot

**Lab 4 Complete!**

<!--BREAK-->
