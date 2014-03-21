#**Lab 3: Configure Host Networking**

##**3.1 Verify Interfaces**

The server has a single network card. Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

    ip a
    sudo ovs-vsctl show
    

For this lab we will need 2 interfaces. The DHCP interface was the single NIC *em1*. The interface *em1* will be associated with the *br-public* bridge. Ensure the *ifcfg-em1* and *ifcfg-br-public* files look as follows.  The *ifcfg-br-public*  file will have to be created.  The files on the host should look exactly the same as what is listed below.

    cat /etc/sysconfig/network-scripts/ifcfg-br-public
    cat /etc/sysconfig/network-scripts/ifcfg-em1

Packstack does not configure the interfaces but in this lab they have already been configured for you.  In the original state, the single Ethernet interface had an IP address from the classroom DHCP server.  We needed to migrate that IP address to the *br-public* interface.

Confirm the *172.16.0.1* IP address is assigned to the bridge interface *br-public*;

    sudo ovs-vsctl show
    ip a
    
IP address should be on the *br-public* interface and the *classroom* interface should have received a new DHCP address.
          
    ip a | egrep "public|em1"

output:

    92: phy-br-public: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    93: int-br-public: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    168: br-public: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
        inet 172.10.0.1/16 brd 172.10.255.255 scope global br-public

**Lab 3 Complete!**

<!--BREAK-->

