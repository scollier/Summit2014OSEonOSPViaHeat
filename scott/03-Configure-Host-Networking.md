#**Lab 3: Configure Host Networking**

##**3.1 Configure Interfaces**

The server has a single network card. bla bla here....
Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

        ovs-vsctl show
        ip a
        
Here you will notice that out of the box, packstack does not configure the interfaces.  In it's current state, *em1* has the IP address.  We need to migrate that IP address to the *br-em1* interface.

**Set up the interfaces on the server:**

Ensure the *ifcfg-em1* and *ifcfg-br-em1* files look as follows.  The ifcfg-br-em1 file will have to be created - it does not exist out of box.  The two files on the host should look exactly the same as what is listed below.

        
        /etc/sysconfig/network-scripts/ifcfg-br-em1
        DEVICE="br-em1"
        ONBOOT="yes"
        DEVICETYPE=ovs
        TYPE="OVSBridge"
        OVSBOOTPROTO="dhcp"
        OVSDHCPINTERFACES="em1"

and configure em1, it exists already, just modify to make it look like:

        /etc/sysconfig/network-scripts/ifcfg-em1
        DEVICE="em1"
        ONBOOT="yes"
        TYPE="OVSPort"
        OVS_BRIDGE="br-em1"
        PROMISC="yes"
        DEVICETYPE=ovs
        
**Restart Networking and review the interface configuration:**

        service network restart

Confirm the IP address moved to the bridge interface.

        ovs-vsctl show
        ip a
        
Now the IP address should be on the *br-em1* interface.
              

**Lab 3 Complete!**

<!--BREAK-->