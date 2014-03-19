#**Lab 3: Configure Host Networking**

##**3.1 Configure Interfaces**

The server has a single network card. Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

    ip a
    ovs-vsctl show
    ip a
    
Here you will notice that out of the box, packstack does not configure the interfaces.  In it's current state, the single Ethernet interface has an IP address from the classroom DHCP server.  We need to migrate that IP address to the *br-public* interface.

**Set up the interfaces on the server:**

For this lab we will need 3 interfaces. The DHCP interface will likely be *em1* or *eth0* or somethign similar. These instructions will assume *em1*. The configuration file *ifcfg-em1* will be associated with the *ifcfg-br-public* bridge. Ensure the *ifcfg-em1* and *ifcfg-br-public* files look as follows.  The *ifcfg-br-public* file will have to be created - it does not exist out of box.  The three files on the host should look exactly the same as what is listed below.

Create the file **/etc/sysconfig/network-scripts/ifcfg-br-public** with the following contents:

    DEVICE="br-public"
    ONBOOT="yes"
    DEVICETYPE=ovs
    TYPE="OVSBridge"
    OVSBOOTPROTO="static"
    IPADDR="172.16.0.1"
    NETMASK="255.255.0.0"
    OVSDHCPINTERFACES="em1"

The configuration file for em1 exists already, edit **/etc/sysconfig/network-scripts/ifcfg-em1** to contain the following contents:

    DEVICE="em1"
    ONBOOT="yes"
    TYPE="OVSPort"
    OVS_BRIDGE="br-public"
    PROMISC="yes"
    DEVICETYPE="ovs"
    
Configure a new interface called *classroom* to provide external access. Create the file **/etc/sysconfig/network/ifcfg-classroom** with the contents:

    DEVICE="classroom"
    ONBOOT="yes"
    TYPE="OVSIntPort"
    OVS_BRIDGE="br-public"
    DEVICETYPE="ovs"
    BOOTPROTO=dhcp
    OVS_EXTRA="set Interface classroom type=internal"

**Restart Networking and review the interface configuration:**

    service network restart

Confirm the *172.16.0.1* IP address is assigned to the bridge interface *br-public*;

    ovs-vsctl show
    ip a
    
IP address should be on the *br-public* interface and the *classroom* interface should have received a new DHCP address.
          
    ip a | egrep "public|classroom"

output:

    92: phy-br-public: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    93: int-br-public: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    168: br-public: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
        inet 172.10.0.1/16 brd 172.10.255.255 scope global br-public
    169: classroom: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
        inet 10.16.143.136/21 brd 10.16.143.255 scope global classroom

**Lab 3 Complete!**

<!--BREAK-->

