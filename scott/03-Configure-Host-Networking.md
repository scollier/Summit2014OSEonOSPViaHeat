#**Lab 3: Configure Host Networking**

##**3.1 Verify Interfaces**

The server has a single network card. Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

    ip a
    sudo ovs-vsctl show
    

For this lab we will need 3 interfaces. The DHCP interface was the single NIC *em1*. The interface *em1* will be associated with the *br-public* bridge. Lastly, a new interface *classroom* will be created and assume the MAC address of *em1* for external communications. Ensure the *ifcfg-em1*, *ifcfg-br-public*, and *ifcfg-classroom* files look as follows.  The *ifcfg-br-public* and *ifcfg-classroom* files will have to be created.  The three files on the host should look exactly the same as what is listed below.

    cat /etc/sysconfig/network-scripts/ifcfg-br-public
    cat /etc/sysconfig/network-scripts/ifcfg-em1
    cat /etc/sysconfig/network-scripts/ifcfg-classroom

Packstack does not configure the interfaces but in this lab they have already been configured for you.  In the original state, the single Ethernet interface had an IP address from the classroom DHCP server.  We needed to migrate that IP address to the *br-public* interface.

Confirm the *172.16.0.1* IP address is assigned to the bridge interface *br-public*;

    sudo ovs-vsctl show
    ip a
    
IP address should be on the *br-public* interface and the *classroom* interface should have received a new DHCP address.
          
    ip a | egrep "public|classroom|em1"

output:

    92: phy-br-public: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    93: int-br-public: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    168: br-public: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
        inet 172.10.0.1/16 brd 172.10.255.255 scope global br-public
    169: classroom: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
        inet 10.16.143.136/21 brd 10.16.143.255 scope global classroom

**Lab 3 Complete!**

<!--BREAK-->

