#**Lab 3: Configure Host Networking**

##**3.1 Configure Interfaces**

The server has a single network card. Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

    ip a
    ovs-vsctl show
    ip a
    
Here you will notice that out of the box, packstack does not configure the interfaces.  In it's current state, *em1* has the IP address.  We need to migrate that IP address to the *br-em1* interface.

**Set up the interfaces on the server:**

For this lab, we will need 3 interfaces.  *ifcfg-em1* will be associated with the *ifcfg-br-em1* bridge. Ensure the *ifcfg-em1* and *ifcfg-br-em1* files look as follows.  The ifcfg-br-em1 file will have to be created - it does not exist out of box.  The three files on the host should look exactly the same as what is listed below.

* Create the file **/etc/sysconfig/network-scripts/ifcfg-br-em1** with the following contents:
    DEVICE="br-em1"
    ONBOOT="yes"
    DEVICETYPE=ovs
    TYPE="OVSBridge"
    OVSBOOTPROTO="static"
    IPADDR="172.10.0.1"
    NETMASK="255.255.0.0"
    OVSDHCPINTERFACES="em1"

* The configuration file for em1 exists already, edit **/etc/sysconfig/network-scripts/ifcfg-em1** to contain the following contents:
    DEVICE="em1"
    ONBOOT="yes"
    TYPE="OVSPort"
    OVS_BRIDGE="br-em1"
    PROMISC="yes"
    DEVICETYPE="ovs"
    
* Configure a subinterface em1:1 to provide external access. Create the file **/etc/sysconfig/network/ifcfg-em1:1** with the contents:
    DEVICE="em1:1"
    ONBOOT="yes"
    BOOTPROTO="dhcp"
    TYPE="Ethernet"

**Restart Networking and review the interface configuration:**

    service network restart

Confirm the IP address moved to the bridge interface.

    ovs-vsctl show
    ip a
    
Now the IP address should be on the *br-em1* interface and *em1:1* virtual interface should be functional.
          
    ip a | grep em1
output:
    2: em1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
    92: phy-br-em1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    93: int-br-em1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    154: br-em1: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    inet 10.16.138.52/21 brd 10.16.143.255 scope global br-em1

**Lab 3 Complete!**

<!--BREAK-->

