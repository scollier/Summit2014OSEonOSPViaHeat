#**Lab 4: Configure Neutron Networking**

##**1.1 Configure Interfaces**

**Set up the neutron networking.**




        source keystonerc_admin
        
        neutron net-create public --provider:physical_network=physnet1 --provider:network_type flat --router:external=True
        
        neutron net-list
        
        neutron net-show public
        
        neutron net-create private --provider:network_type local
        
        neutron net-list
        
        neutron net-show private
        
        neutron subnet-create public --allocation-pool start=10.16.138.219,end=10.16.138.234 --gateway  10.16.143.254 --enable_dhcp=False 10.16.136.0/21 --name pub-sub
        
        neutron subnet-list
        
        neutron subnet-show pub-sub
        
        neutron subnet-create private --gateway 192.168.0.1 192.168.0.0/24 --name priv-sub
        
        neutron subnet-list
        
        neutron subnet-show pub-sub
        
        neutron router-create router1
        
        neutron router-gateway-set router1 public
        
        neutron router-list
        
        neutron subnet-update pub-sub --dns_nameservers list=true 10.16.143.247
        
        neutron subnet-update priv-sub --dns_nameservers list=true 10.16.143.247
        
        neutron router-interface-add router1 priv-sub








**Explore the current network card interface setup:**


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
              

**Lab 4 Complete!**

<!--BREAK-->