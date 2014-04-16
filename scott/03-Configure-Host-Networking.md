#**Lab 3: Configure Host Networking**

##**3.1 Verify Interfaces**

The server has a single network card. Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

For this lab we will need 2 interfaces. The DHCP interface was the single NIC *em1*. The bridge *br-public* will be created and used as the exsternal network, though this will only be simulated as it will not actually route anywhere. View the script to see the changes that will be made:

    cat /usr/local/bin/create-bridge-config

Run the following script to create the bridge config:

    sudo /usr/local/bin/create-bridge-config

Ensure the *ifcfg-br-public* file look as follows.  

    cat /etc/sysconfig/network-scripts/ifcfg-br-ex
    DEVICE="br-ex"
    ONBOOT="yes"
    DEVICETYPE=ovs
    TYPE="OVSBridge"
    OVSBOOTPROTO="static"
    IPADDR="172.16.0.1"
    NETMASK="255.255.0.0"

Packstack does not configure the interfaces but in this lab they have already been configured for you.  In the original state, the single Ethernet interface had an IP address from the classroom DHCP server.  We needed to migrate that IP address to the *br-public* interface.

Confirm the *172.16.0.1* IP address is assigned to the bridge interface *br-public*;

    sudo ovs-vsctl show
    ip a
    
**Lab 3 Complete!**

<!--BREAK-->

