#**Lab 4: Configure Neutron Networking**

##**4.1 Create Keypair**

All actions in this lab will performed by the *admin* tenant in this lab.  In a production enviroinment there will likely be many tenants.

    source ~/keystonerc_admin

Keypairs are SSH credentials that are injected into images when they are launched. Create a keypair and then list the key.

    nova keypair-add adminkp > ~/adminkp.pem && chmod 400 ~/adminkp.pem
    nova keypair-list


##**4.2 Set up Neutron Networking**

**Set up neutron networking**

        
###**Network Configuration Background**

In this lab there is an existing network, much as there would be in a production environment. This is a real, physical network with a gateway and DHCP server somewhere on the network that we do not have control over. Therefore we decided to use the a private network to represent our public network. This network will be setup on a brige called *br-ex* which is defined in the packstack answer file with the following option:

    CONFIG_NEUTRON_L3_EXT_BRIDGE=br-ex


###**Create the *Public* Network**

Create a public network with the --router:external=True option to designate it as an external network:

    neutron net-create public --router:external=True
        
List networks after creation:

    neutron net-list

More detail is available with the *net-show* command.  If you have multiple networks with identical names, you must specify the UUID for the network instead of the name.
        
    neutron net-show public
        
Create the *public* subnet. Also specify an allocation pool from which floating IPs can be assigned. Without this option the entire subnet range will be used. Also specify the gateway here:
  
    neutron subnet-create public --allocation-pool start=172.16.1.1,end=172.16.1.20 \
        --gateway 172.16.0.1 --enable_dhcp=False 172.16.0.0/16 --name public    
        
List the subnets:

    neutron subnet-list
        
Show more details about the *public* subnet:

    neutron subnet-show public


###**Create Private Network**

Create a *private* network that the virtual machines will be attached to. As this is an all-in-one configuration, use *network_type local*. A real production environment would use VLAN or tunnel technology such as GRE or VXLAN.

    neutron net-create private --provider:network_type local
        
List networks after creation.  This time you should see both **public** and **private**:

    neutron net-list
        
Show more details about the private network:

    neutron net-show private
      
Create a private subnet:

    neutron subnet-create private --gateway 192.168.0.1 192.168.0.0/24 --name private
        
List the subnets

    neutron subnet-list

Show more details about the *pivate* subnet:

    neutron subnet-show private

Create a router. This is a neutron router that will route traffic from the private network to the public network:
        
    neutron router-create router1

Set the gateway for the router to reside on the *public* subnet.
        
    neutron router-gateway-set router1 public

List the router:
        
    neutron router-list

Add an interface for the private subnet to the router:
        
    neutron router-interface-add router1 private

Display router1 configuration:

    neutron router-show router1
    
**Lab 4 Complete!**

<!--BREAK-->

