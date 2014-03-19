#**Lab 3: Configure Host Networking**

##**3.1 Configure Interfaces**

The server has a single network card. Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

    ip a
    ovs-vsctl show
    
Here you will notice that out of the box, packstack does not configure the interfaces.  In it's current state, the single Ethernet interface has an IP address from the classroom DHCP server.  We need to migrate that IP address to the *br-public* interface.

**Set up the interfaces on the server:**

For this lab we will need 3 interfaces. The DHCP interface will likely be *em1* or *eth0* or something similar. These instructions will assume *em1*. The interface *em1* will be associated with the *br-public* bridge. Lastly, a new interface *classroom* will be created and assume the MAC address of *em1* for external communications. Ensure the *ifcfg-em1*, *ifcfg-br-public*, and *ifcfg-classroom* files look as follows.  The *ifcfg-br-public* and *ifcfg-classroom* files will have to be created.  The three files on the host should look exactly the same as what is listed below.

Before configuring these files, first copy the MAC address from the system *em1* interface

    ip a show dev em1

The MAC Address is on the second line of output on the link/ether line:

    2: em1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
        link/ether f0:4d:a2:3b:a0:59 brd ff:ff:ff:ff:ff:ff
        inet 10.16.138.52/21 brd 10.16.143.255 scope global em1
        inet6 fe80::f24d:a2ff:fe3b:a059/64 scope link 
           valid_lft forever preferred_lft forever
    
Alternatively, this script will display only the MAC Address:

    ip a show dev em1 | awk 'NR==2{print $2}'
    f0:4d:a2:3b:a0:59

Create the file **/etc/sysconfig/network-scripts/ifcfg-br-public** with the following contents. Note the line MACADDR will use a fabricated MAC address. Change the 1st and 2nd bytes (5th and 6th octets in the right most position) to match your lab station number. Remember to convert to hex:

    DEVICE="br-public"
    ONBOOT="yes"
    DEVICETYPE=ovs
    TYPE="OVSBridge"
    OVSBOOTPROTO="static"
    IPADDR="172.16.0.1"
    NETMASK="255.255.0.0"
    MACADDR=de:ad:be:ef:00:00

The configuration file for em1 exists already, edit **/etc/sysconfig/network-scripts/ifcfg-em1** to contain the following contents. Use the same MAC address specified in the previous file:

    DEVICE="em1"
    ONBOOT="yes"
    TYPE="OVSPort"
    OVS_BRIDGE="br-public"
    PROMISC="yes"
    DEVICETYPE="ovs"
    MACADDR=de:ad:be:ef:00:00

    
Configure a new interface called *classroom* to provide external access. Create the file **/etc/sysconfig/network/ifcfg-classroom** with the contents. Use the MAC address that was copied from the original *em1* interface:

    DEVICE="classroom"
    ONBOOT="yes"
    TYPE="OVSIntPort"
    OVS_BRIDGE="br-public"
    DEVICETYPE="ovs"
    BOOTPROTO=dhcp
    OVS_EXTRA="set Interface classroom type=internal"
    MACADDR=f0:4d:a2:3b:a0:59

**Restart Networking and review the interface configuration:**

Note: Due to the reassigning of MAC addresses errors may occur until a reboot.

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

