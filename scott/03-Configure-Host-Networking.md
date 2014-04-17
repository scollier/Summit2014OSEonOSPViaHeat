#**Lab 3: Configure Host Networking**

##**3.1 Verify Interfaces**

The server has a single network card. Run the script to create the bridge configuration.

**Explore the current network card interface setup:**

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

Packstack does not configure the interfaces but in this lab they have already been configured for you.  In the original state, the single Ethernet interface has an IP address from the classroom DHCP server.  

    sudo ovs-vsctl show
    ip a
    
**Lab 3 Complete!**

<!--BREAK-->

