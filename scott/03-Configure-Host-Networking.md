#**Lab 3: Configure Host Networking**

##**1.1 Configure Interfaces**

The server has a single network card. bla bla here....
Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

        ovs-vsctl show
        ip a
        
Here you will notice that out of the box, packstack does not configure the interfaces.  In it's current state, *em1* has the IP address.  We need to migrate that IP address to the *br-em1* interface.

**Set up the interfaces on the server:**

Ensure the *ifcfg-em1* and *ifcfg-br-em1* files look as follows.

        
        /etc/sysconfig/network-scripts/ifcfg-br-em1
        DEVICE="br-em1"
        ONBOOT="yes"
        DEVICETYPE=ovs
        TYPE="OVSBridge"
        OVSBOOTPROTO="dhcp"
        OVSDHCPINTERFACES="em1"

and

        /etc/sysconfig/network-scripts/ifcfg-em1
        DEVICE="em1"
        ONBOOT="yes"
        TYPE="OVSPort"
        OVS_BRIDGE="br-em1"
        PROMISC="yes"
        DEVICETYPE=ovs
        
**Restart Networking and review the interface configuration:**

        service network restart
        ovs-vsctl show
        ip a
        
Now the IP address should be on the *br-em1* interface.
              

**Lab 3 Complete!**

<!--BREAK-->