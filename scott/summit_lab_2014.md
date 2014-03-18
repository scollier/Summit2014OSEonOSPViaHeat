#**Contents**#

1. **Overview**
2. **Lab Environment**
3. **Configure Host Networking**
4. **Configure Neutron Networking**
5. **Explore the Red Hat OpenStack 4.0 Environment**
6. **Deploy Heat Stack**
7. **Configure Red Hat OpenStack 4.0**
8. **Installing RHC Tools**
9. **Using *rhc setup***
10. **Creating a PHP Application**
11. **Deploy an Extra OpenShift Node**

<!--BREAK-->



#**Lab 1: Overview of Deploying OpenShift Enterprise 2.0 on Red Hat OpenStack 4.0 via Heat Templates**

##**1.1 Assumptions**

This lab manual assumes that you are attending an instructor-led training class and that you will be using this lab manual in conjunction with the lecture.

This manual also assumes that you have been granted access to a single Red Hat Enterprise Linux server with which to perform the exercises.

A working knowledge of SSH, git, and yum, and familiarity with a Linux-based text editor are assumed.  If you do not have an understanding of any of these technologies, please let the instructors know.

##**1.2 What you can expect to learn from this training class**

At the conclusion of this training class, you should have a solid understanding of how to configure Heat to deploy an OpenShift Enterprise 2.0 broker and node.  In addition, you will learn how to expand the OpenShift node environment.  You should also feel comfortable creating and deploying applications using the OpenShift Enterprise management console, using the OpenShift Enterprise administration console, as well as using the command line tools.

##**1.3 Overview of OpenShift Enterprise PaaS**

Platform as a Service is changing the way developers approach developing software. Developers typically use a local sandbox with their preferred application server and only deploy locally on that instance. Developers typically start JBoss locally using the startup.sh command and drop their .war or .ear file in the deployment directory and they are done.  Developers have a hard time understanding why deploying to the production infrastructure is such a time consuming process.

System Administrators understand the complexity of not only deploying the code, but procuring, provisioning, and maintaining a production level system. They need to stay up to date on the latest security patches and errata, ensure the firewall is properly configured, maintain a consistent and reliable backup and restore plan, monitor the application and servers for CPU load, disk IO, HTTP requests, etc.

OpenShift Enterprise provides developers and IT organizations an auto-scaling cloud application platform for quickly deploying new applications on secure and scalable resources with minimal configuration and management headaches. This means increased developer productivity and a faster pace with which IT can support innovation.

##**1.4 Overview of IaaS**

OpenShift Enterprise is infrastructure agnostic. OpenShift Enterprise can be installed on bare metal, virtualized instances or on public/private cloud instances. At a basic level it requires Red Hat Enterprise Linux running on x86_64 architecture. Red Hat Enterprise Linux provides the advantage of SELinux and other enterprise features to ensure the installation is stable and secure.

This means that in order to take advantage of OpenShift Enterprise any existing resources from your hardware pool may be used. Infrastructure may be based on EC2, VMware, RHEV, Rackspace, OpenStack, CloudStack or even bare metal: essentially any Red Hat Enterprise Linux operating system running on x86_64.

For this training class, Red Hat Linux OpenStack Platform 4.0 is the Infrastructure as a Service layer. The OpenStack environment has been installed on a single node with all the necessary components required to complete the lab.

##**1.5 Using the *openshift.sh* installation script**

This training session will demonstrate the deployment mechanisms that Heat provides. Heat runs as a service on the OpenStack node in this environment. Heat also utilizes the `openshift.sh` installation script.  `openshift.sh` automates the deployment and initial configuration of OpenShift Enterprise platform.  For a deeper understanding of the internals of the platform refer to the official [OpenShift Enterprise Deployment Guide](https://access.redhat.com/site/documentation/en-US/OpenShift_Enterprise/2/html-single/Deployment_Guide/index.html).


**Lab 1 Complete!**

<!--BREAK-->

#**Lab 2: Lab Environment**

#**2 Server Configuration**

Each student will either recieve his / her own server or will share with another student. The server has Red Hat Enterprise Linux 6.5 install as the base operating system.  The server was configured with OpenStack with packstack.  Explore the environment to see what was pre-configured. The end result will consist of a Controller host (hypervisor) and 3 virtual machines: 1 OpenShift broker and 2 OpenShift nodes.

![Lab Configuration](http://summitimage-scollier1.rhcloud.com/summit_lab.png)


**Local User**
Everything in the lab will be performed with the following user and password:

    user: user
    Password: password

Sudo access will be provided for certain commands.

**System Partitions**

If you have to reboot the system, we are on partition X NEED TO FILL THIS OUT.


**Look at the configuration options for Heat and Neutron:**


        vim /root/answer.txt

**Each system has software repositories that are shared out via the local Apache web server:**

        ll /var/www/html

These will be utilized by the *openshift.sh* file when it is called by heat.

**Explore the Heat template:**

        egrep -i 'curl|wget' /root/heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml
        
Here you can see that the Heat template was originally making calls to github for the *enterprise-2.0* and *openshift.sh* files. These lines were modified to point to local repositories for the purposes of this lab.

**Look a the images that were pre-built for this lab:**

        ls /home/images/RHEL*
        
These two images were pre-built using disk image builder(DIB) for the purpose of saving time in the lab. The commands used to 

**Check out the software repositories:**

        yum repolist
        


**Lab 2 Complete!**

<!--BREAK-->


#**Lab 3: Configure Host Networking**

##**3.1 Configure Interfaces**

The server has a single network card. Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

        ovs-vsctl show
        ip a
        
Here you will notice that out of the box, packstack does not configure the interfaces.  In it's current state, *em1* has the IP address.  We need to migrate that IP address to the *br-em1* interface.

**Set up the interfaces on the server:**

For this lab, we will need 3 interfaces.  *ifcfg-em1* will be associated with the *ifcfg-br-em1* bridge. Ensure the *ifcfg-em1* and *ifcfg-br-em1* files look as follows.  The ifcfg-br-em1 file will have to be created - it does not exist out of box.  The three files on the host should look exactly the same as what is listed below.

        
        /etc/sysconfig/network-scripts/ifcfg-br-em1
        DEVICE="br-em1"
        ONBOOT="yes"
        DEVICETYPE=ovs
        TYPE="OVSBridge"
        OVSBOOTPROTO="static"
        IPADDR="172.10.0.1"
        NETMASK="255.255.0.0"
        OVSDHCPINTERFACES="em1"

and configure em1, it exists already, just modify to make it look like:

        /etc/sysconfig/network-scripts/ifcfg-em1
        DEVICE="em1"
        ONBOOT="yes"
        TYPE="OVSPort"
        OVS_BRIDGE="br-em1"
        PROMISC="yes"
        DEVICETYPE="ovs"
        
and configure em1:1 to provide external access.  This file needs to be created and look like:

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
              

**Lab 3 Complete!**

<!--BREAK-->

#**Lab 4: Configure Neutron Networking**

##**4.1 Create Keypair**

All actions in this lab will performed by the *admin* tenant in this lab.  In a production enviroinment there will likely be many tenants.

    source /root/keystonerc_admin

Create a keypair and then list the key.

    nova keypair-add adminkp > /root/adminkp.pem && chmod 400 /root/adminkp.pem
    nova keypair-list



##**4.2 Set up Neutron Networking**

**Set up the neutron networking.**

        
Create the *public* network. In the packstack answer file we specified the name *physnet1* for the physical external network.  INSERT VINNY HERE - ack - vvaldez

    neutron net-create public --provider:physical_network=physnet1 --provider:network_type flat --router:external=True
        
List the network after creation.

    neutron net-list

Show the public network.  If you have networks that are named the same thing, you can specify the UUID for the network instead of the name.
        
    neutron net-show public
        
Create the *private* network that the virtual machines will be deployed to.

    neutron net-create private --provider:network_type local
        
List the network after creation.  This time you should see both **public** and **private**

    neutron net-list
        
Show more details about the private network.

    neutron net-show private
      
Create the *public* subnet. This command also creates a pool of IP addresses that will be *floating* IP addresses.  In addition, set up the gateway here.
  
    # neutron subnet-create public --allocation-pool start=x.x.x.x,end=x.x.x.x \
    --gateway x.x.x.x --enable_dhcp=False x.x.x.0/x --name pub-sub
    
    neutron subnet-create public --allocation-pool start=172.10.1.1,end=172.10.1.20 \
    --gateway 172.10.0.1 --enable_dhcp=False 172.10.0.0/16 --name pub-sub    
        
List the *public* subnet.

    neutron subnet-list
        
Show more details about the *public* subnet.

    neutron subnet-show pub-sub

Create the private subnet.       

    neutron subnet-create private --gateway 192.168.0.1 192.168.0.0/24 --name priv-sub
        
List the *private* subnet.

    neutron subnet-list

Show more details about the *pivate* subnet.

    neutron subnet-show priv-sub

Create the router.
        
    neutron router-create router1

Set the gateway for the router to reside on the *public* subnet.
        
    neutron router-gateway-set router1 public

List the router.
        
    neutron router-list

Update the *public* subnet with a valid DNS entry. **THIS WILL NEED TO BE MODIFIED, IT MAY NEED TO BE REMOVED, FOR OUR PURPOSES - VINNY, use 10.16.143.247**
        
    neutron subnet-update pub-sub --dns_nameservers list=true x.x.x.x

Add an interface for the private subnet to the router.
        
    neutron router-interface-add router1 priv-sub

Display router1 configuration.

    neutron router-show router1
    
##**4.3 Configure the Neutron plugin.ini**

Ensure the */etc/neutron/plugin.ini* has this configuration at the bottom of the file in the [OVS] stanza. The key part is to ensure the *vxlan_udp_port* and *network_vlan_ranges* are commented out.

    # vxlan_udp_port=4789
    # network_vlan_ranges=physnet1:1113:1114
    tenant_network_type=local
    enable_tunneling=False
    integration_bridge=br-int
    bridge_mappings=physnet1:br-em1

    
Reboot the server.

    reboot

**Lab 4 Complete!**

<!--BREAK-->

#**Lab 5: Explore the Openstack Environment**

##**5 Server Configuration**

FILL OUT THIS

**FILL OUT THIS**

FILL OUT THIS


**Lab 5 Complete!**

<!--BREAK-->

#**Lab 6: Deploy Heat Stack**

##**6.1 Import the Images into Glance**


All actions in this lab will performed by the *admin* tenant in this lab.  In a production enviroinment there will likely be many tenants.

    source /root/keystonerc_admin


The names of these images are hard coded in the heat template.  Do not change the name here.

    glance add name=RHEL65-x86_64-broker is_public=true disk_format=qcow2 \
    container_format=bare < /home/images/RHEL65-x86_64-broker-v2.qcow2
    
    glance add name=RHEL65-x86_64-node is_public=true disk_format=qcow2 \
    container_format=bare < /home/images/RHEL65-x86_64-node-v2.qcow2
    
    glance image-list


##**6.2 Ensure the heat.conf file is confirgured correctly**

Ensure the following variables are set in the /etc/heat/heat.conf file:

    # heat_metadata_server_url=http://IP of Controller:8000
    heat_metadata_server_url=http://172.10.0.1:8000
    # heat_waitcondition_server_url=http://IP of Controller:8000/v1/waitcondition
    heat_waitcondition_server_url=http://172.10.0.1:8000/v1/waitcondition
    # heat_watch_server_url=http://IP of Controller:8003
    heat_watch_server_url=http://172.10.0.1:8003


##**6.3 Create the openshift-environment file**


**Create the openshift-environment.yaml file:**

Get the private and public network IDs as well as the private subnet ID out of the first column of the output of the below commands.  Place those parameters in the following file in the following fields: private_net_id: public_net_id: private_subnet_id: to replace FIXME.

    neutron net-list
    neutron subnet-list

Create the */root/openshift-environment.yaml* file and copy the following contents into it. For the IP address of the repo locations, please replace with the IP address of the host you are on.

    parameters:
      key_name: rootkp
      prefix: novalocal
      broker_hostname: openshift.brokerinstance.novalocal
      node_hostname: openshift.nodeinstance.novalocal
      conf_install_method: yum
      # conf_rhel_repo_base: http://IP_OF_HOST/rhel6.5
      conf_rhel_repo_base: http://172.10.0.1/rhel6.5
      # conf_jboss_repo_base: http://IP_OF_HOST
      conf_jboss_repo_base: http://172.10.0.1
      # conf_ose_repo_base: http://IP_OF_HOST/ose-latest
      conf_ose_repo_base: http://172.10.0.1/ose-latest
      # conf_rhscl_repo_base: http://IP_OF_HOST
      conf_rhscl_repo_base: http://172.10.0.1
      private_net_id: FIXME
      public_net_id: FIXME
      private_subnet_id: FIXME
      yum_validator_version: "2.0"
      ose_version: "2.0"

##**6.4 Open the port for Return Signals**

The *broker* and *node* VMs need to be able to deliver a completed signal to the metadata service.

    iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
    service iptables save


##**6.5 Launch the stack**

Now run the *heat* command and launch the stack. The -f option tells *heat* where the template file resides.  The -e option points *heat* to the environment file that was created in the previous section.

**Note: it can take up to 10 minutes for this to complete**

    source /root/keystonerc_admin    

    cd /root/

    heat create openshift \
    -f heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml \
    -e /root/openshift-environment.yaml


##**6.6 Monitor the stack**

List the *heat* stack

    heat stack-list

Watch the heat events.

    heat event-list openshift

    heat resource-list openshift

    nova list

Get a VNC console address and open it in the browser.  Firefox must be launched from the hypervisor host, the host that is running the VM's.

    nova get-vnc-console broker_instance novnc
    
    nova get-vnc-console node_instance novnc

##**6.7 Confirm Connectivity**

Ping the public IP of the instance.  Get the public IP by running *nova list* on the controller.

    ping x.x.x.x 
    
SSH into the broker instance.  This may take a minute or two while they are spawning.  This will use the key that was created with *nova keypair* earlier.

Confirm which IP address belongs to the broker and to the node.

    nova list

SSH into the broker

    ssh -i ~/adminkp.pem ec2-user@IP.OF.BROKER

Once logged in, gain root access and explore the environment.

    sudo su -

Check the OpenShift install output.

    cat /tmp/openshift.out

Check mcollective traffic.  You should get a response from the node that was deployed as part of the stack.

    oo-mco ping
    
    oo-diagnostics -v
    
    oo-accept-broker -v

SSH into the node, using the IP that was obtained above.

    ssh -i ~/rootkp.pem ec2-user@IP.OF.NODE
    
Check node configuration

    oo-accept-node

Confirm Console Access by opening a browser and putting in the IP address of the broker.

http://IP.OF.BROKER/console

**FILL OUT THIS**

FILL OUT THIS

**Lab 6 Complete!**

<!--BREAK-->

#**Lab 7: Installing the RHC client tools**

**Server used:**

* localhost

**Tools used:**

* ruby
* sudo
* git
* yum
* gem
* rhc

The OpenShift Client tools, known as **rhc**, are built and packaged using the Ruby programming language.  OpenShift Enterprise integrates with the Git version control system to provide powerful, decentralized version control for your application source code.

OpenShift Enterprise client tools can be installed on any operating system with Ruby 1.8.7 or higher.  Instructions for specific operating systems are provided below. It is assumed that you are running the commands from a command line window, such as Command Prompt, or Terminal. If you are using Ruby Version Manager (rvm) see the instructions below.

##**Microsoft Windows**

###**Installing Ruby for Windows**

[RubyInstaller 1.9](http://rubyinstaller.org/) provides the best experience for installing Ruby on Windows XP, Vista, and Windows 7. Download the latest 1.9 version from the [download page](http://rubyinstaller.org/downloads/) and launch the installer.

**Important**: During the installation, you should accept all of the defaults.  It is mandatory that you select the "Add Ruby executables to your PATH" check box in order to run Ruby from the command line.

After the installation is complete, to verify that the installation is working, run:
	
	C:\Program Files\> ruby -e 'puts "Welcome to Ruby"'
	Welcome to Ruby

If the 'Welcome to Ruby' message does not display, the Ruby executable may not have been added to the path. Restart the installation process and ensure the "Add Ruby executables to your PATH" check box is selected.

###**Installing Git for Windows**

The next step is to install [Git for Windows](http://msysgit.github.com/) so that you can synchronize your local application source and your OpenShift application. Git for Windows offers the easiest Git experience on the Windows operating system and is the recommended default - if you use another version of Git, please ensure it can be executed from the command line, and continue to the next section.

Download and install the [latest version of Git for Windows](http://code.google.com/p/msysgit/downloads/list?q=full+installer+official+git). Ensure that Git is added to your PATH so that it can be run from the command line. After the installation has completed, verify that Git is correctly configured by runing:

	C:\Program Files\> git --version
	git version 1.7.11.msysgit.1

###**Installing RHC for Windows**

After Ruby and Git are correctly installed, use the RubyGems package manager (included in Ruby) to install the OpenShift Enterprise client tools. Run:

	C:\Program Files\> gem install rhc

RubyGems downloads and installs the rhc gem from www.rubygems.org/gems/rhc. The installation typically proceeds without errors. After the installation has completed, run:

	C:\Program Files\> rhc

##**Mac OS X**

###**Installing Ruby for OS X**

From OS X Lion onwards, Ruby 1.8.7 is installed by default. On older Mac systems, Ruby is shipped as part of the [Xcode development suite](https://developer.apple.com/xcode/) and can be installed from your installation CD. If you are familiar with Mac development, you can also use [MacRuby](http://macruby.org/) or see the Ruby installation page for [help installing with homebrew](http://www.ruby-lang.org/en/downloads/).

To verify that Ruby is correctly installed run:

	$ ruby -e 'puts "Welcome to Ruby"'
	Welcome to Ruby
	
###**Installing Git for OS X**

There are a number of options on Mac OS X for Git. We recommend the Git for OS X installer - download and run the latest version of the dmg file on your system. To verify the [Git for OS X installation](http://code.google.com/p/git-osx-installer/), run:

	$ git --version
	git version 1.7.11.1

###**Installing RHC for OS X**

With Ruby and Git installed, use the RubyGems library system to install and run the OpenShift Enterprise gem. Run:

	$ sudo gem install rhc

After the installation has completed, run:

	$ rhc -v

##**Fedora 16 or later**

To install from yum on Fedora, run:

	$ sudo yum install rubygem-rhc

This installs Ruby, Git, and the other dependencies required to run the OpenShift Enterprise client tools.

After the OpenShift Enterprise client tools have been installed, run:

	$ rhc -v

##**Red Hat Enterprise Linux 6 with OpenShift entitlement**

The most recent version of the OpenShift Enterprise client tools are available as a RPM from the OpenShift Enterprise hosted Yum repository. We recommend this version to remain up to date, although a version of the OpenShift Enterprise client tools RPM is also available through EPEL.

With the correct entitlements in place, you can now install the OpenShift Enterprise 2.0 client tools by running the following command:

	$ sudo yum install rubygem-rhc
	
If you do not have an OpenShift Enterprise on the system you want to install the client tools on, you can install ruby and rubygems and then issue the following command:

	$ sudo gem install rhc

##**Ubuntu**

Use the apt-get command line package manager to install Ruby and Git before you install the OpenShift Enterprise command line tools. Run:

	$ sudo apt-get install ruby-full rubygems git-core

After you install both Ruby and Git, verify they can be accessed via the command line:

	$ ruby -e 'puts "Welcome to Ruby"'
	$ git --version

If either program is not available from the command line, please add them to your PATH environment variable.

With Ruby and Git correctly installed, you can now use the RubyGems package manager to install the OpenShift Enterprise client tools. From a command line, run:

	$ sudo gem install rhc


**Lab 7 Complete!**

<!--BREAK-->

#**Lab 08: Using *rhc setup***

**Server used:**

* localhost

**Tools used:**

* rhc

##**Configuring RHC setup**

By default, the RHC command line tool will default to use the publicly hosted OpenShift environment.  Since we are using our own enterprise environment, we need to tell *rhc* to use our broker.hosts.example.com server instead of openshift.com.  In order to accomplish this, the first thing we need to do is run the *rhc setup* command using the optional *--server* parameter.

	$ rhc setup --server broker.hosts.example.com
	
Once you enter in that command, you will be prompted for the username that you would like to authenticate with.  For this training class, use the *demo* user account.  

The first thing that you will be prompted with will look like the following:

	The server's certificate is self-signed, which means that a secure connection can't be established to
	'broker.hosts.example.com'.
	
	You may bypass this check, but any data you send to the server could be intercepted by others.
	Connect without checking the certificate? (yes|no):
	
Since we are using a self signed certificate, go ahead and select *yes* here and press the enter key. 

At this point, you will be prompted for the username.  Enter in demo and specify the password for the demo user.

After authenticating, OpenShift Enterprise will prompt if you want to create a authentication token for your system.  This will allow you to execute command on the PaaS as a developer without having to authenticate.  It is suggested that you generate a token to speed up the other labs in this training class.

The next step in the setup process is to create and upload our SSH key to the broker server.  This is required for pushing your source code, via Git, up to the OpenShift Enterprise server.

Finally, you will be asked to create a namespace for the provided user account.  The namespace is a unique name which becomes part of your application URL. It is also commonly referred to as the user's domain. The namespace can be at most 16 characters long and can only contain alphanumeric characters. There is currently a 1:1 relationship between usernames and namespaces.  For this lab, create the following namespace:

	ose

##**Under the covers**

The *rhc setup* tool is a convenient command line utility to ensure that the user's operating system is configured properly to create and manage applications from the command line.  After this command has been executed, a *.openshift* directory will have been created in the user's home directory with some basic configuration items specified in the *express.conf* file.  The contents of that file are as follows:

	# Default user login
	default_rhlogin=‘demo’

	# Server API
	libra_server = 'broker.hosts.example.com'
	
This information will be read by the *rhc* command line tool for every future command that is issued.  If you want to run commands as a different user than the one listed above, you can either change the default login in this file or provide the *-l* switch to the *rhc* command.


**Lab 8 Complete!**

<!--BREAK-->

#**Lab 9: Create a PHP Application**

##**9.1 Create a PHP Application**

FILL OUT THIS

**FILL OUT THIS**

FILL OUT THIS

**Lab 9 Complete!**

<!--BREAK-->

#**Lab 10: Extending the OpenShift Environment**

As applications are added additional node hosts may be added to extend the capacity of the OpenShift Enterprise environment.

## 10.1 Create the node environment file
A separate heat template to launch a single node host is provided. A heat environment file will be used to simplify the heat deployment.

Create the _/root/node-environment.yaml_ file and copy the following contents into it.



    parameters:
      key_name: rootkp
      domain: novalocal
      broker1_floating_ip: 10.16.138.100
      load_bal_hostname: openshift.brokerinstance.novalocal
      node_hostname: openshift.nodeinstance2.novalocal
      node_image: RHEL65-x86_64-node
      hosts_domain: novalocal
      replicants: ""
      install_method: yum
      rhel_repo_base: http://10.16.138.52/rhel6.5
      jboss_repo_base: http://10.16.138.52
      openshift_repo_base: http://10.16.138.52/ose-latest
      rhscl_repo_base: http://10.16.138.52
      activemq_admin_pass: FIXME
      activemq_user_pass: FIXME
      mcollective_pass: FIXME
      private_net_id: FIXME
      public_net_id: FIXME
      private_subnet_id: FIXME




## 10.2 Launch the node heat stack
Now run the _heat_ command and launch the stack. The -f option tells _heat_ where the template file resides. The -e option points _heat_ to the environment file that was created in the previous section.

    cd /root/

    heat stack-create ose_node \
    -f  heat-templates/openshift-enterprise/heat/neutron/highly-available/ose_node_stack.yaml \
    -e /root/node-environment.yaml


##**10.3 Monitor the stack**

List the *heat* stack

    heat stack-list

Watch the heat events.

    heat event-list openshift

    heat resource-list openshift

    nova list

##**10.4 Confirm Connectivity**

Ping the public IP of node 2

    ping x.x.x.x 

SSH into the node2 instance.  This may take a minute or two while they are spawning.  This will use the key that was created with *nova keypair* earlier.

SSH into the node

    ssh -i ~/rootkp.pem ec2-user@IP.OF.NODE2

Once logged in, gain root access and explore the environment.

    sudo su -

Check the OpenShift install output.

    cat /tmp/openshift.out

Check node configuration

    oo-accept-node

SSH into the broker instance to update the DNS zone file.

    ssh -i ~/rootkp.pem ec2-user@IP.OF.BROKER

Once logged in, gain root access.

    sudo su -

Append the node 2 instance _A_ record to the zone file so node 2 hostname resolves.

    echo "openshift.nodeinstance2    A   IP.OF.NODE2" >> /var/named/dynamic/novalocal.db

Check mcollective traffic.  You should get a response from node 2 that was deployed as part of the stack.

    oo-mco ping

**Lab 10 Complete!**

<!--BREAK-->

%PDF-1.4
1 0 obj
<<
/Title (��)
/Creator (�� M d C h a r m \( h t t p : / / w w w . m d c h a r m . c o m / \))
/Producer (�� Q t   4 . 8 . 5   \( C \)   2 0 1 1   N o k i a   C o r p o r a t i o n   a n d / o r   i t s   s u b s i d i a r y \( - i e s \))
/CreationDate (D:20140318031451)
>>
endobj
2 0 obj
<<
/Type /Catalog
/Pages 3 0 R
>>
endobj
4 0 obj
<<
/Type /ExtGState
/SA true
/SM 0.02
/ca 1.0
/CA 1.0
/AIS false
/SMask /None>>
endobj
5 0 obj
[/Pattern /DeviceRGB]
endobj
6 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 9 0 R
/Resources 11 0 R
/Annots 12 0 R
/MediaBox [0 0 595 842]
>>
endobj
11 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F7 7 0 R
/F8 8 0 R
>>
/XObject <<
>>
>>
endobj
12 0 obj
[ ]
endobj
9 0 obj
<<
/Length 10 0 R
/Filter /FlateDecode
>>
stream
x��Mo�����+x`�ݜ� ��l�!�a99���xg���J���m�6��H6���d��������?}�G��ߊ��_�S|m~�Y�7��<�)��u/�u�s������������ǟ�W�Ü��믫����W����������_�������f���V�����ï�������f�/����2��x�V�C��a�ͮ,��o��y.���ڮҝ�v�z�����|U����������M�m����ْ"��.ط�n~������������Nlt���m�)ޭ������r?��������W�W*\Y������-�QmO>>��]��,��SW�A�q/=QwW��%��}�n�~N���jUw�z��u��/<��g��gd�������NWv!�v.�O6�܆�w�����?یY�3���pg���~������O�z]�Q�4�C0�ԝ՜������Vv��s*�,;Ղ�g�bZ�y(	�������!�=�m8�:|F�bT����jb&��\-��V]��o��w,gA�,�H��_��k��k ���nxiy;�08�Y7,9l'�ׅ��ۇw�C%�k��0����!�q���)�t5RHς�5���}���g�>��^©�2�û�/	�A����mP��A�)O���C;y_i�3^{��!�WZ	��5�W7�s��A�Zr��/2A��zL�z\�:i���$rP�,9�N�oTd�C�C�����C��傮����m�A�����-@�6��ˁ�Er�هv��B��߅b�4\�m�9���Le����ڕt����_���]U�r�Q���QTK��A��*�n�v�h��A>�3n� ���V'��@�h�u]�&������UK��ɿTV����rY=�(NJ�2MH�tr)H"
�A:���W��������~�=���w�C�7��3��N�d�W��Y��S����-wx9�贃����!:�nD�;.�W7Jbp��h;���&pz1p�F���;N8c�	O����=6<;��²�i �6�a�#0Z�&�84J�Ի�`�z����x4�P���\ȉ�S�w�Ԛ��$,�8���@Z��ǐ*��=h��~3�sT���
�����c��&��>d�������[n{H�}W�<���E;�4����
W�2�{:�����92 ���L���<R��"B�p	��(��pf|/	��x-���&�>����T���~�hA����_m���y$���`��#���p<�_�jAS0�'9�6�����@rA������a-���X��Ŵ���o`�u��h�����E	y���!�]��C��� �`����ᕙiI��ۅcxPS��Z���<L�/Y��eZ������AOe�S��"��N�rg�.c��Cv��G�?=�&o\�/�`���AC���Qu,��R�j$�8����#����4��Fg�>x��D(c]�f�B���w�i�'D�nb��5H�!������#3�G5�t�Z���i�A��dF	\�hS�q!�;�fzuT��E��={'s�I�C���|���7<����.�}|�&Qs&&҃��.���tը��To��f��(�V;��̌��2d�9%ܡ��r�@Ĺ��yN�40�@D�)������n��&HJ�0Sqh���'����B��n��YO][� W�w�D�&b���0��W]o��!��?3������qH�M�T��ھr�"��$�Kx?�C�����d�����������)����t~4I�׍�����m�1��-���E˻��]������u�a�G��Qz�0e���ǭ���t$%xq�X6��̳�8�	�(0 �q&~m��|���DB?5)1[R�!U�-.����"gׇw�>���	B�L�LFr<�#f ��wL��0�
���L.���(9(W+s]���?R�?t"�-f\�c>��{R�^HjD�ɀ�C� [�P׀Z�@G�Hv�=� ���� T֙����9��f&aK(�i�I���`�H	$0��ZO����B/!=0����scR`V^X�UW��ǂ𠑡&5��n<�L�|4nՓq��h�!�
�,�t�)̝,�RͦP+	�ٿ$ZTn��� �Q`��}i&��]eU�НYL<<ɱJ����(��Z�FQDv0�:̆9����X-���,Ǎ#�{��m��bb3��k��i��ӧ���&"�:cM����tVwH�t)E]ǐ����Ձ7q}����xs]>3@}���TY�I��x�H�dl�.�)�mg�[LR���uŠzy���h��U�v��Q�# u���tV�P�h. ��P&��P1=¹ �K���] Q5�+�T�bqzq�ؿ��v�zO.���j� ��cD���5�
9��֏~*�ik�N=Ns��`0%X�娼N���zq�p�������8�?,FtNN�t������I:]O	}^��)�RF::X���������A��.G���6�ymY֏PT:�K���񫍐2d�&0�l��M�>]��8k'uJDc������r�I��M��޵���&�E=�.v
}iY���'願��fv<� x:Ŗ7�e�4�D�p/�4RuN!�-#s���R��_OɆl�T]��4�.�2�$(}�@cgq����8?�p���������1��,΃��F�O^�,E��G��Iֵ��,2�\�m�"j��B���u�fɎ��C[Fh&�_��Fՙ�:&�!"|]A��T(��߰���_)�r��1j<�<�������u�SC)UWl�Q�)@��_S�T�����H�Zw �#��`��ג��pk�bjAP�M���d��5�e7���-���O^pm,XX�iz��
������w��3�5�ޑb�9�3����}�$�M��#�z�����rP�w�i�7>��L�ʒ|�8IX�M���0�m��[��c;��D�`j?~�ǣf�R�?4�jS#�RXvç�t#'��7�o�Mbb�J�Z����+�:kcȞ�8ݡ��Q�7t\��8��zTOh���>�\{�B�#�.ےON��5d�R`'Rhn��O�茥�������yh��C�c�I�Y.�Z��r)>���R�+wU��,�I
���$J�k3� 7����O��o��Aw�m׸|�"��$b���B+(�	E�z&T���AyW�"�j}o������싸���[w0��t������:-qE�
,_	5$u���a��Lý�P}�HA�Gzj�Ceq|#2g85Ϸ�t����U����[�y%�v��$����U�Bd/�����?I+C!��~5E�k�1�$]���*�!��!���	K`iD_��r)l,'���>�%h��24a���ñ�*����3�ε]���I�m�S|��eR
�b�"R=�y
��a��)���'�,���P�qbgJ�?�5�L�vo��w�_��YQ�G(jy��
a/�Z۾;?��{����7e�� ����m򷂘��)>�cp�_��q�꓂z���=�$h	J�!9�����H��_��f��]|kZ.ӠB"�&��*B����m�^�ٍLZ�Z�7�����*.�
�4:U��:�T���H��� �u��[��><�)wR����9���]��8�(u���!��p��0@_���bz��kA�O~.#"���p����n�G 8��m0TCe="笹p�8W[�yE�d��]�~��,�u��5
ek>�W�¢O�endstream
endobj
10 0 obj
3858
endobj
13 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 16 0 R
/Resources 18 0 R
/Annots 19 0 R
/MediaBox [0 0 595 842]
>>
endobj
18 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F7 7 0 R
/F14 14 0 R
/F15 15 0 R
>>
/XObject <<
>>
>>
endobj
19 0 obj
[ ]
endobj
16 0 obj
<<
/Length 17 0 R
/Filter /FlateDecode
>>
stream
x��]K�#9r��W��p�~ ����n>hL>>����=��2#�)��*k�z��U_Kƃ�`���O?����~�����s�v�����R�/��?P��c6�����o��__���v�6�����Ǘ�/������G{����_�������\�>|��C�Y��O����F��b��W\����ÿ��������֔��K_��?��V�;=�k��ѯ��Ce�Yw,Ƽ���y��R��r�����R��k�B��X��L��R��}Q)e�O��2�(��?�bME����N��l)��Ž�xm)��&�SE�J�H)z�J��?N���o��	?��)�}��WZ]I�"C��};P|�����{J�Hꦼ�U��jT:i}���ʪ�T	�h�.�rqF�\BI��s���u�J�>_�q�r(1��}�8Ʌ��J��C���1ٖ��6Q���?�剟�G�)�IR��=h�?��T�m�A��|g8�dC�1�.�`�Z�h�g�Lޥ��=T�ń�P>�&�'�;�6�_P�u �j�6����p���p
u���#�}u\�U�6�"C�p�p>�&|�R$��)oPb�OLZ+S�.�+���'�x���-�XJ�hF�)X�������	���J�>1�X���4�eJ$8�'ތPd��?�	?'���S�DR7���D�:�*�Pgzs���C�h5��L1�'&c�TBԑ��d�ʩxo�O$r���Ң�P-E[�z�(Rt����ω�#���$�����'�-�:sc8]p�	N��`PIW�9ʆӄ��D�|*9���`J��
��3�Hp��E���4�|8|�R$��)�}b���}��	�>q©7�Q�pE�sR�Dm]�K�x5��}b��`pIS�Xe���+�D�2%��D�oF(R7���ĉ�'�O$��)��'N�s�H�R5�Lo���FT�V��G��Ē�TrN��%W���8�'���QiQ~����"����Ǉ�������$�����'V�fjd���s�8�ԛU�
Κ!��(N·ӈ��3ä9Q�65��p��0�.8�'ތP�>��	�É�#��'Iݔ�v>��§�7�D�3�Hp�ͪC��uC�KQ_ה�z	���l0.f��I5�����>�����x�J$(S"��O$8�f�"C��1�H�9q|�R$��)��'�֙OdT��"8ӛ�#�ǔ9ZM��`<���N�u�[�O��j�>�@}"����j�x(�
��D��c���'~N��'Iݖ�v>q0�X�p0�F��D�oV�p�.9]�(N·��\�yO}�V��f�p�f8�8�'ތPd(N·�G�)E"�����'=��j�ĕHp�	N�YE]���sE�>"5q���+^y�>���̧|dM"��F9A�q~F��D�oF(r��?�	?��r�(N��)��'�֙OdT��"8�[P��&Z4V����'VN��N�O�x�vi�ڙȅ��H��C�L<m��m���k�-�����=�8J궼��gS�u9X`8]q�	N�YE�܀)�A�p"8N/�W��(�A*>6�銶��3�Hp�������p���{Fq��My_���{�h������l7i���^����~�&�����ϕm���Ѽ������C�?;��_�r���o���׿��og�� y����O|<al�>a�p`�@���]���F���c�4d���ˇ�Q���s�(���:zџ�F��~���_���i}OA�?����ܘ6��s,h��Z���wh��Wގ3h�;j ^�n0L/����NB;�B^n���B|�k��2t]v\�m �ʠc0�۞.`N��n��~����Dw`>o`�v���k_?53�	g��5>TT=�[C�}��
&"Gi�:���x?����z~�]Gz�E���	:ę�EyLa�!�^o-������R��yAO�:�i��?�;1�DW&̘�C[4qi�s�HkD�A��������y�� � �aؒ��*�U�d�ȡ�V���[���e�y�n� naPm��܏r�+�em�aYܽ�vW������Э�'1��ض���6�MrO�o�� Ƞ�~d�k�ֈ�Vl�CF�	F�ڢ@�����l�#��X�-�Fa$j��Mn��g�Wn�aq���d#�>�Z�)@y��`%u�E��l�{w�^���I@�ѐ'9^�^�ʴ�bL���k>9�f ؂���xT�O�WZ�8H����'�}�������YNw$���2٨�0;;�m%q�늲_k
y��od�]�-�����w<dW=��'�5�c�cK���7����'�`f;/�Yd��Ą �Y�T���bRt�����7� �CV��]�΂u����ٝ������e��!����k�����`���4
�͜Lس+w���\5�U���n��=��(O>�ԑڒs�r
�!��.ح����C���d���|��:��l�ه���ǌ9jg.����&>����ޅ��NpѳLGkg�`w
?�J_�>N�ۏ\�[30rY��/��|�"*!P�l[�������3��^K!uN���N��, ���3�pn}�Lb1�t^Y�s#�&��F&���n-S��i� ����wf���8��_�?%���2O��)!�g�R�<>���n���v�&np�`I��j�g�q�-ǚ�8yc�9q�(�12M�_,i�r�<�Q�Ǝ��}��"K��xM���W�+���=��ذ�-�#�ב�z��xG�n���R��i����>i��-���d���]��<�❔��#M@�����DϬ�pV���uEbrRֺb�?ZoTU�-C���.G�)~��U&�����w��J��U��#G���/a��D����%{n��C���?R�!���O�H�7��?~:��J��1<{���I'J��c�j���9q|�R�$u[��Y8�]�{Q"�[��`@#>H˨d�P�����+:}q�d���(�ĄsM<(\��U�:չ4qAA�J+*�SC��UZ�:?�T"J5Ap�	���S���n��Us���4W3f��6:L��-��y����m�3Ge�a�I�	z7':�ow,���`�)z\-��;�����<Do��i�U9k4�7��QVG�-�m	�f�u�3C���8��g1Jq��h��I���uIWR.�W��d�(R�xk�So���{B�Hꦼ�3�yW�^����?L$��ũ��⃴���g����P��	� ��P�S��hb~M���uY�l�c� �x�o�(R�ib¹&>qO(Iݔ�{�c�{����E)��(DN��g�:vОT�r�[j;��s�/���:*�u�op5�稝|%�G~�ͱ�,�+iI~蕮�n�I���-���\L�5mr�T�A����y��r�����>aOrC&�;��S��!�k>�^�zw�m����bZ����n�����S?��h�]��^!���ű?�Z�{ԗ?�[���.�Nc�g%��y���C��Y�;G.v��{��g��#\p��ޭ�7���)(�QZ%��j�궔�Z�9#O�<L�'4���P����h/-�
BKطs^�	gn��	�gu�-ש�,�ժ�L$L�K�.�nC��H���K�:I�uY�6��[�"J
�C����@�ͳ�E|�P���%�+�h ��}��.���w<���Ciy��lg3�ٮ����C����	�^�WRtkI�S��w����
k}��uJ�wb�`�����8M�Չ�.�A�>��y/��Q �I�@���Cw�y͜ݜ6�䙟R�ꕆ���vT���f��S@봂q���� �&��H'o����,�x:N�ω�1����s�LHoxjZ�"�<��r^�cF|HX���?F o���l���r4ÛA�����m4ҳ����ww*��$g��o��� 乧c}�I��-��k�z��og�{�JZ�T��o���w{���zYP�K�79v��)����U�xzL��\�K|;sA�Ԏ4�]�ooZ�@�]�u,{��k�m��J��R�' ��1��Iюk��������e��&�e3��K��o�d�\�L|Z��Hy�q�
�t��F�[��jl����	2������B�m��i�i0<u5ma��Ѕ�G��2q-��煭�*D���M�c���,A�jV^V�×S_���$	��l��7�p���pTG^���y��[ǵ��=��T��p6$���l8�./�q*����4�^�&�� �V�]p 3�j�2����g��}�#�0_��kp�p|fV�&�+�'.� Γ�!k`�@�{�!����aNd�;����킓{RB�  h�*j�æf�8Dd3!?���z�=�r��\��T�2Z��=�+�h�Jɦ����?���*nT
��Dqc��N����i�}�)sԪᖈsC�A��ڱ���	n�����H)z�\�a�2I�7��?~:�S��,ų������@��G�)E"���~/�S�֌�b8}��ւ�̼�
q#�_����(tU,'t	��1Q��w�#�>��Ļ(s/T1!r��Y�C �A��zN6{��8��=�|/����!"�E�HL�
+0%wr�E�<�+����Pu�X�C�3��U)/P�"�����;Pt�!K1B�Ex��v�S�է^�w4#�IxY�T���w�{�8T�0o�3�+�ē�!o�������W%�F�5�F�_)>T����u&]�阼K��g�P���5�.%ėh��^9k\�GJ��J�1i�&�E�g�8�IM(2t���	?'�O����n��=?G��l�w�i��y �x�hcf�ˀp�򵰪0�H�����uu}߭��n��J]�A(��5̞�ċ|Bx�����Wa^�2M�+��7N8�ao3�5��D�&������f�@e�>�F�V>Q*S�:�+�XpM�@�x.��Wޞ��T>���ޚŎ�j 4����J@r�@^�l��|��GG�j��䎴d�v�QE�vu���⤸`�����ڙ�9	�K]���K]'�4����N�K	}�	/Ie�sJ�	^��>:s$�*B]��ek'�����g��б|�4���N�t�4I궼��N絓3���{�N���$�{�+�|��Z�����`�g���Ľ��3�����>�������˃KG�:�ia�5sD��W(u�N�^wv�P�{}V�*�C�GkB�-��:w������}h����roH�T���V��PE�͝��ք4�Вm?��}����n��P��7�sa������t^��ܢj����_�ݤ{�C�kz�����2�U4�{��b��WG�DNz�7�����:9�7e��4ZpAV�<��t!�*';^:y#�f���Y$5[g�r�3��|�C+4�x�' }�h���\ę��$U�-M���;��\*v��gl�,�o�<h�D�����V���{���l�ʛ���{����*�wk奠X�x����i�K�e�{M��rѧ���N=�y�/n�!.P�\�E~�T�;�3��U�.�+�z�+�yj�c;Z^[�쾋AvoO׏/L<��#�p�� ���Y������s��w��L�؆��m����A�G\f\��|�Rލ���o���)�0\!�EEB�?�Z2�D�g�v�ZWQ���)j��}f�.Gq�U��rn��A�cvGJ�$��	�N��6�	�6�	N��	E���c��G�)E"���~�|?o����M.w�2S���^��ͷ�.#���[����=�v[�F�T��ߤ�~z{�9�j�N����3�{E� Y����&�Sᰤ������ب����o�ߴ�+�b�ǘ̂C�zX��8ԧ�z5P�v��J��5��%��}��!���(�����b���-�آ�Xw.b��vO�d���(�-��ȓ�vi��|B_���dE�걜��v�i��b�Gkx@��Ԯ+�B0�_)(kut�Q�tHQ}���)�h�-��JP.�p�A��)���>�MPú�yp<����t�h�ʩ؊����7�ψ���I��P��,�A�95��{Fq��my��<�9�P��W7�y�)E8R*�M긓�iy�y�"��h���4Č-�,�w0��%�+=w��ӊw�������7*��l���=��������Їendstream
endobj
17 0 obj
6227
endobj
20 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 21 0 R
/Resources 23 0 R
/Annots 24 0 R
/MediaBox [0 0 595 842]
>>
endobj
23 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F7 7 0 R
/F8 8 0 R
/F15 15 0 R
>>
/XObject <<
>>
>>
endobj
24 0 obj
[ ]
endobj
21 0 obj
<<
/Length 22 0 R
/Filter /FlateDecode
>>
stream
x��]M�$7r�����C��0hF�����뵱(-,������Ff�*�=]�U��~�dD��A2H~�O�����~���/�sx����'�R�/�꿟���M><���������~����髈�������^�?� �|���������_�����?O��?��)٬J�'ѯG���U,�{�u�k���~��?�F��*kmM	.�ԅ������:����J7}��_���:�A���bH�������*a���q�g�g,=*�M
�f�Tt)�j��J)��?>�`��ޘ�xV������*�g��J��kCxB<&e}�ٞd�UH����X)�9`����i��)(�BљL�WZ]RLX"C��=?!��92�i�%����L2��� �z"�UHU�K���$]G���	娡Rs�Z��*�{7ɞ�-6�����Ck�>�夌ɶ��p�V"�s����>G���c��R�����˟�;���M>�՟W�SVޥ�Jߝf�6y�b�Ƴ��Mޥ��%�(�F���;5�w'��G�$Se�	�����iF��4�;�!券'�2Τ�O%2�u������=��Z��p�fNtN+_t��;pƉ��9gT��,G�ʅH<rN�.R�-�'Ή�����AN��v���N�9pƉ��A����8�9r|�JDK-ڻ�D��8��
8�SQ�bG=�jR�=����D�U�ՀJ�@���@�e`(��~k%":��Y�#�g�D�Բ�����,�?��;�8�D���jմN�Nz�ӌw�	�DR��9���j�#�N3�u�g�8���P֝f��N����R��ޏ}"���r'�8pd�DÆ%&�f�&='�씋Z�b9�{�% '��UIkt"�̉�3N�Jd�\?Ɖ��D�Y,�h�A:�DV*2T��o�fj��s�P�֜�SfE©��rN�1��3G	r"��Ǭ�0/C��[+ѹ~��6}���Gn�Z��~�X�Bp�fѝf�q"��f�Pd�(f(�N3�u'�=Iq9%�Ċ�A}�ӌv�i�'l%2�u�ƕ�;5�i�,�Z��~�-)����8�D��͢�JS(Gi�OZ�.N��D�Y���Gӟ;��H�:׬|�k(s"��6�m�c��9>k�%����q"Hg��J����DҰ�g�-Ɇ�ŉ��4"'�9��*�lGG�D���������P
�JDt��r�����Xb�Բ����hi�M4[�i�'lV���&�Qwݩ�;5�����ȉ-�؋7��v�i�'l%"ʻS�yw|�KK-�{GN$�.9��͝�pΉG6�Q�v�:cC���j(�81�B�;'cT�'i����U���Y��9pƉ��A����9���9�i���Z�wωM:�D,���o���U�d�SZΉI��x��s"�W9e���`���ü�R�oP"�s�xWm�{|�9�Yj��;rb`����N3�9���fԠ�v��DYw��;n�Q){������N*�ӄ3N�Jd(�N��xw|�9,�h��81�\�]jL܉�3N�,g
L�qb.�	_'D����D��Ģ>�M�(S�E�xj�l=P�D�'l%2t��DЇq"h%����q"Hg��J��VL��9j�Tj�'m�*ɔn=��f��!'�]�~�Z��20JA��9:Տy�9r|�JK-�{?N�MA{jO�;�8�D���*Js��'v�iƻ����JZ�K���t��)�N3�u�g�8���P֝f��No�C�h�E{�ǉ�����-� �8pd3�#j	����C4S�'&GK�dh�|�i JLQ�H!���r'6�sbÑ�Z����8�9r|�KK-ڻ�D��8����p�:!��pk�8����D�cr��D��	��g%6�`��Z�z9���Z�����^n�9>k�%6K-�{?N�MA��1��;�8�D���|���8ʺS�ywܫ�6�q"5yS4�w��ӌsNl8�_+���;5�w'�g�D�Ԣ�''��9���y#��Y���9I��$����Ͽ>}�S:����`^�^���oO�T�d�_�|����<���'S�&�$6�G�7?��<���#�"����	��!V�z��^���\#��BnyALC�P���	T8
1~d�\Y!���G�\e��&	���L����+u�7m�v�=mt��ž43h���?�<F1�L�q��SC���z��ޒ��rK��0�������sb���B?��a������,�}�gΣ㿿��]W���<��v���s�</w4���t���R����OD������ɪ��\��>�b_�=`�O�6B��J��D�ѱ�<�×��~��Vz�lﺾ�u�-b��*<#��u{��2DM{��B�e��'�R.�eܖ�R.���/�ň65���v�t �<�ܸ�])���$u
nnr��fլ�F�2vh�)t��%�_��p܈ވ�7�e��q�K��]�\�24+���]1o+}`z����}����0������ظ�����T�">B��i�b�0���тC���b�v+��9	�E�������eܦ�� Z�h�A�t�÷;,�f\Q�eS�ٖ���6' ?2<X��)��=��5����z���[���K��̡m�p�[Ͼ��4Wq4�A�(���`g�6*Ťm�(��Ʀ������J9S�Xb������hw��J#�~�s{En�=�iL��vS�[\+A�`�[@$�%����>~"�;"���.�e-�
]�ۓy�� ֥*��I��m�A���k��9� `�<Wp��A��S"����sg���.1�Noitf8��i����h$&w�Ve>�Ӻ�5/ڔ|��g�~}�
�#W4=>�����F������t������u>;m����w�����#əeS�<'W#��s�AO�F�Ze�ׯ5^�Դ�:�X��^�7Z%�x���?�*f���Ub�|�aqn(T�/f�V��o�l����Gޫ�ξ�%�sCJ��"��Ƌ����}��b�����n�x?l!l��)e������[H��h���Y#�b�\dOL��Fۼ	yI��s	v 9��X)�Y��J ��VH����Z�4��ৄ��s2p�����'r3x<��_Oc�&P~G]�R_�h�8E6^�̕q�Ø-\A�W�s��J�������	�o#�>�fPZz�ȡo���{�7�*Y���-�!��+��k[l��.�.D�~�6�o�UNͿ�u�}�"��7]S���*efW�:n�ڑ�6Lg�B`n�3.q����K�o���Xޠ��c�d}<߸�Q^��!VzŒ�x]��%����p�G�T���������!��)|!�6�_��S2�H<܋ODs��s�F7�sS�F^�_mE}���e=J4�q)b8^��~�j��&Z�ݎw�a(6&�}[��p?�fv��ߥ~oÊ1���1�l8W�VA�pw�U�d�'���J:�RD/6o6l�#o�K�D�ל)�m�9���R��� ���ڙ�sR7���vI�44���-t��f���o�$9�t�1Fכp��ʇR�C��pH�Ϯ�$�U�|��l8���WL!3Y{z}�F̈́r�s/�3c{�#p�)[�9]��\ �u0�)c��Kl5_��q��~2��nw-퐙�D���\��R��{��<>������s�(+��j��?��LM����k~���腎s���R�=�[�:�mw����D�e�����۟�r>����aFG�m9�i���h�}����(��W����hQ���M���0��]�~e�s��OM{殿vP�������x��񚄘�rߔ!��ȷx�F �lc�.#~dx�j:�șpG9wʐdb�z.����ǐ��yr��~���q.��F"���$�$BP�-^}ʏ	[Ec�u:�^/������r��|Nj��AxwIx��Ix�$$���Uq�bV^|kʛ�a��蔊=�a �3���qO��@���Ç9Wp&�N�0
 k�����?	�S��n!d,�_(���鴫�دU���BH��2����n��Q��K�n�J&���.��(�N)3���s�2�2cy�9�2�4��T,&��S��ܼ'Vy��7귫n�i�S���>.gR�R3yS?2�EU7rb�uG9�i?�� 5�4��W���5�����Sp�pfm�\15��A���K}{����D�����&Џ�D{��g�~}�
�#W4}܋wO#E^=r��F
�@!��b!��~�B,�QA�rh�x��x��"B���?�v�ɳ�~]��呆�s#نSK�K�y�3[^:I�N䈃/�V���zooH���Ңa���S��O�t��8�%�A�py��f�r�t��=V�����{*������yV!F�?2�.�`]�������CJ13_�Eek)J�j#�fB9�C"3���F�X�=�V���?��3��Κإ��\�'�FL���/��H����݆]��G��Ҁ�H�^5����"�__"���X�������u�����5��� ���y�5;�FO���cqoCY��B��Iz�k9oCw�B��J��'5Β�C]<�.�n{`G9wJw�մ�=��.鮬_�Hj���g�*5�$�ιyb��BA��p�U�)��e�U��)����U�{��������p__�xI@>kr��2>�+!��\2� ~dxp*SL�oG9wJ�!�z�y�]���ڋ-T�3��EJ��$�m/*�8>|�gCPu)�S�I�æ�G�G*.��_8���(�Ny6�xz��ٻ�ٰ���=	�ܼ�4���;iB����
(-E����25g��'aG9� ?�lUȩn�t��*;{ځ���ʄD�@�Yۨ�w����dr�����PP_���o�ҹ�c����_C��B��M��D�i����qh�������D�3�]��7΂~\���$^����դ�Yq\!䳘~�w��?����W�L�w�V��AF|H�fB�*�.>�����D3�_��Xy>'#�sE�6����)�3ڨjtRNk��+����8�'�N�K�qC?z�B�������?Y�>��p�TJ���-7�E��d�K���)��֯��L���,S�!��:׏e��>G���c�`�E{�Y��*n�����=C��'&pbL�"�q��s��o�)�!6J�ڵG�ǻ/7|tʧ��N"��{p���xy�=?�<>�3~�u����I���\k��'�0݆�C��F��M��`䷧Bc��Y'�^�2E��eޭ�(�,�a��3V�z:�i�6�h&��8Lg�ʘ���S�h�R�e�JN���5N�hM�,Dk5_��q���®w�nXW���O6��t��Vg�ٷ?MMҊ�f҄-N?~D<�\	&vY�k8��A��S��k��4����%����b=Qtf8�vV9FW��[k�l�O��0���j�{�h�l�C� %�g�~�>3��#W4}�y���z��x��D�g�!~�'�r��͊�E{�h/I_���O�~��9߸���^�c}����?w�D��F�-o2
.j�[0�X��tA�&wa���P���+�^<�K��p%,)�<K�'�M��^���A3��.�̷+��O�+t�ͫ>���Ԥީ&�^5gF�i�Y�X��_�k���� 1b���t�/侴�qBm12DQa��BQ+��2�ޛj#�~�=W���4������b�������o3�&B{�����0�f�iI���ҧ�/|�=�2a��)?U��q�j�}�%쒽�M�Ց.�����2�/H��r�(e�^�C�-A�oi�3����SV�^6�~�S��]^ŗ�ovƓ��(+	VHk�o�t^�'GUG�/��KP������\�r7�<E�l�ZIM=gy1�3�`��%�B�~�ލ��<����=�\����+8z���Ɇ��_g���*X)c<oX�_�+}��n��$$[��NY9����/�e�Eg�?>�������&e���r��	����PK?��mM�mx�Fi�L9�E�*�l	� %�Tj3�P��8�&vu�D���c�$�ϑ��P"Zj�ޏ��Ӿ\Jf��ˌWq�H=�>7W��)��z��B�!^u��J��[\����Y!T���4q1�ڨzÁG�OI-�o�P8Fl�+�ê��_����à�5�Nl�ơ�02������{�rd�*��K������u2u�m���(���ԫ8�� iU���|�*�Tr�j#�fB9�cT�pf�L����&���<V�L�غ����8�J��j���#G��r��7���%��(�.��31�����%(V\�4��ۆ+#�.ATZ��8ͯ�8~����/W�&s��Wª�F� �n�Dki a�a�ӽ���d(��"�+�Y44��m}��+"X]�, ~dx�*��J�^�*�r>Hh�ɑ����mg?�"EQ���~VQ|d]f�`ֶ���M0�Q\��E������\�}�T(�}��g�~}�
�#W4}d��Stח�>Rt�y��~WS�ʼ�uI*�LR��3�Fdw�ͳR��)�{ 3��G�*ܹT,)XVF��Y�ۥ2��)�M�X�H�MB�������?p.k��̛⹋���N�y�"��u.L�#���+��.�N��A�q3�n�R����<b<����qq��endstream
endobj
22 0 obj
6741
endobj
25 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 26 0 R
/Resources 28 0 R
/Annots 29 0 R
/MediaBox [0 0 595 842]
>>
endobj
28 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F15 15 0 R
/F7 7 0 R
>>
/XObject <<
>>
>>
endobj
29 0 obj
[ ]
endobj
26 0 obj
<<
/Length 27 0 R
/Filter /FlateDecode
>>
stream
x��]]�d�q}�_��L��0Xk)@�� �:�a��(~��O�Nϭs��s{f{g{g[B�����:U,������y�������>�����kJ������G��Cu���ׇ��=��������x��|���w��?<"?�W�����_�o;����|����>_M������l�&7��v�k��>����~XS������B�}p%[\]�WwZ�u˿��/�=��ۡ9i'�p���z��HX�fj>�s��(=�h]I��C��:�[��ͱ�R����CN�8�K���+�yw���Z\���b��-�|�� xj�gS^�^�lM����$fg��)mk� ��� ~|Hb��l��h�u��\P"�п���>G�U{���ڴ�G��լ�����bQ5��n�]�q�b��)EB�H��e$OE�������^Ml-�nP�v����@�b����D8�%���Q}���� ,�m�>��S�5��=��s�>9i��I�>��ٻH?ߧ|(�X���/���9��N+>�ӊ��v�ŝ�A����\c!wR��I��NI<5���	m��գ?Itp��Iq�$��6�=�9Qt0՗�"�ĉ��9�L�>��h0���-s��c|p��D1�I��NV щc��A�p�D���@"�k��A�#��(,�i��u�D�
8�[0-��=�2�|��1':�*b�Ȝ�\�٘DA�D������(Ca+8n*ѵ<ʪϑ�U{���ڶ��8�O��Z'wZq�D��͜�&�k`��Iqv'��� �9�;��H<A�iŉ6���;)����=JKm����X���diDřG6+2��"��1b���X%B�7pb�&�"�O�X����� *ʃ�8s���f*�е̉�s�j��R��9Q[gND��P�Ӹ%�ܘ+GYt�Xe��X%�&ۂ8�J��d��.�?�ꃣ��ษDD���(�>̉�=JTKm����(S!�ar�gNT٬D$g�K#Dɝgw\�(Ȝ/ĉ����P���N+Μ�8��J$��Iqv'�W�Q"Xj����D!j�ǹD��6�Ši��F٣#mŘ�}� �s	�9���25[@N�=?�n��J�8q"��f �еĉ�q"h��R��8Z'N$��P��]m��X&Ρ�Ȝ裄Yq�֘e>J�,�4#'�]�h-�G
[�qS�����QV}���ڣD�Զ��ǉ}*��ͣ;�8q"��f>X�c˶1J�8���H�JBN�h�E��iEwZq�D���@"��N��;�j��R���"'�H\j��	��̉�#�I�/)��� *S�4����2�sb�D8�*�"'I����J2@i'N�$���9Q�aNT��R��9Q[gND��P�ӸUSZʁ��gɥ��J୊U$��[�P��ȉ`�Y��Q��V�. ѵ쪪s�j����ڶ�9Q�B/� ;�ӊ3'*�l&��t�5fJv�܉��9�O�ܫ7��iEwZq�D���@ ;)��;�j���ڴ��81�H,IN
 �'�l&Q^�=�of *��b�C=1�l:����R1��oQ=1,��� (��̉�#��DB��'�>G�W�Q"Xj��'B�ĉ$Jq�����
�X�PO)�U�OC=1�d�,���.�?�ꃣ���ษDD���(�>G�W�Q�Zj�����>d����<�ĉ�#����ٔ#��N��;ުK��}�g���N+:�ӊ3'*���Iqv'�W�Q"Xj������).$;�;+��Ί�����J�FF{�5�4��(�V�gN�b�K(ĉ�[��e�I2@yGRq�D�q�X%�����U�wV�Q"Xj��㾳����(���q��o[2[��S�QZ����91�T�6YO�v����Pe��Vp�T"�k�x�U�wV�Q�Zj��W�w^��B����ü�JH�%wR��	�h�Mb%�Ď6��0A�iŉ�c�H(����N��ڣD�Ԧ��ȉU�҃:��̉�#�I
k%�|G��B~�D��:I�f��(�ȕ�����Z�+d�� N�8��Q��q�?�DՇ9Q�GNKm�{�Dm�9�"C)N�&M&8{�h�5gq$�o��e͚�t�'�]�h-�G
Z��DD��gqV}�#~�%����}EN�z�,'wZq�Dő���P,����N��;���B[��R���޲tp�'NOݨD�8v'�ٝ _�GNKm��z���('�:�'N�L���!8˨��l���ľNJ^��%��E�>�8Q����utPDřGNT����#N}���ڣD�Ԧ�N�։I*�T��M:�S�eD[l����$Ykr�U��$k�,��D��.�?�ꃣ���7����?e��8�'�Q�Zj������[qj�FwZq�D�����P�WFɝgw<K��]�ĉ}}�|i�;���N+Μ�8r�J$��Iqv'�W�Q"Xj��W��&�eY<Ea���S�2�Bͥ0���:{,�ɸ�ώ{,��^k�e8�z�.T��:��^������m�H��?�DՇ9Q�GNKm�{�Dm�9��	��÷���,���-�y�c�V����X�J*<r"��G�}h����7��G���G�W}�#~ҞN���ڶ�9�'�9�q�p�D��v�Z���Xwҳ��N��~&-٦��T�pJ�i��̶�xf[%J�g�ɝ _�GNKm��z��)����=��G6�(o%����7���I
��$�5�6�s���Zy�%g�T�.� *ʃ�8s���~*�еĉ�ϑ�U{��ڴ����:q"IE�R�ƭ�s�~D[�\���e�!JC=Q&L?y���Ck�>8�ȉ�
��JDt����s��(Q-�m��qb�mi!�ѝV�8pd�ekIH!0J�8�ൟ�i���Ѿ�wZ���V�9Qqd?�H(����N��ڣD�Ԧ��ǉ��5� 8q"��fE���-����OK.���%in�C=��h��d�%���sTO�p�D���@"�k��A�#��(,�i��u�D�
8�EB�s�vD[K��D��b!���X�����D�D������(Ca+8n*ѵ<ʪ�q�OڣD�Զ��ǉ�'�-Jf;�ӊ'l�'���!8Fɝgw<_�oTO�hk�r(tp�'N�$J�8���(,�i�+r�Dbk[-C=p�Dő�$��j-&:��POb<T?���M+U�'��Lu1V*� ʃ�8s���f*Q�s��Ü�ڣD�Ԧ�GN�֙Q*2��4n򋾸�L)Y��ۡ�XJY>�C=Q�cr��z"����B}p�����HDt����Ü�ڣD�Զ��ȉ2��v�-��tG6�	�z��L��8���2��L�L����Ei}t�:��	gNT�L%"��8���(,�i��qb�Hl}�q(� N�8��Ć����j �`��ꉒs�\�5��ϱE�'ʂ����|��4��'l	]�G��_�G�`�M{��'�T`(�iܢ���lbT:ֿ�5��zb�?;i��`�Z��Q��Vp�T"�k�x�U�#��(Q-�m��qb^�\��t6�*Eosf��Iqv'��	.�@���V�&w:��;�p�D���@"��N��;�j��R���"'J$�Q&�PO�9Qqd3���&�� ��C=�6'x�'6/�ŢTO�M�"&� (��̉�#��DB��1'�>̉�=JKm�{�Dm�9�"C)�v�P�df�֣��PO�ŏXEꉵI��w��v����Ped(h�M%���QV}�U{���ڶ�9�'���`gw:�̉�#�ɄJ���L��8���_C�zbw+�ɝN��N'�9Qqd3�H(����N��ڣD�Ԧ��ǉ�"��T�C��'l�R?���T����C=��(xLq�'�6=l4��-��� ("�ĉ���DB��'�>G�W�Q"Xj��'B�ĉ$
p�˲�#��2*!�\�zb�^�"���(	������.�?�ꃣ��ษDD���(�>G�W�Q�Zj����Ķ�O�Ztp'ŉ6k�Kt�Qr'�ٝ O�4KFG�ĎV�Y�iEwZq�D���@"��N��;�j��R����]a����P |�+�	�[�l?�dk�j���"�[��3ۂ��1�iɰJ\��6Q����{q�[�V��>�o�+l�g�+l՞�
[-�i�鮰���0�
8�[��	~D��%#N̉B6u�pxX;�L�!�]aj�X��Q������J$���(��w��ړ��R����]a��x{M��w��8�
f�	͗Ew�Н'ʏW�ľܬ��΀����8��-_OEw��	�'�I�Zj�ާA������-�8��L��^��x��׻u{���y��GQ;~���=�[���_~}H�Z���?�`m��t��on��}X��@]��@�� ����0���+�Ǳ�3m����ޗ3k�5�v����~�'���� A5�o��f�s�M0�d�ij��»i~~?��8a�#PԎ~�lc���{]���e׵~t��;M�r�c�ht�vj��t.��4����������%f���l�I�i�&�F3O}�@���?��ĜGw��hC?�z��,q/Z{���n�H#�����lt��%�#�;�.�m�m�q�%'O��u��#��ʍ]�m��w9�_��؍E�u _-y���8�?�qS ���;���G��
�F�{2#����i�g��ӏ���]�BN�/Ň�����)�N����hj��B�,Y}M�����%,;I)�<RJqYiY]�oF<oZ�e��o�Zd��g2 �g2��'���Ub�FX%���?@?�>��,��\�y� J%"��d�g��L?}�=HKm������u�B�q�et  �n����9���R�Ű��1�0;�1��cS�e�	��1�d�	�#0��n�r� ��~��L�S���;P����^��4r�K�z؝���1ϓ����Y^�@/�Ŏm��I���v�cÌC9�p������0�L���������+�r���Wb�M�i~���䷧�ZD�g�q��g��-�iZWN��[�|�����wW>�c��F0K9��|ڶ�4��=��9�X\im�_	���_ʌ�g]��J2E�/����YҔ����roWd��B��"<��r�-�D'��j�쟢�6��F���Z�DB�,ھ�粆'�NڣD�Զ��k�em��2��gm���8C�7�\\#�X�����fs x�]�	w��:�ׄ/��΅��X����l�i%6Ym��ۘ�ՔGL���&E��Ưvӕ�λI�5wF�|w��Wt�5=��h�ٸ�����>t�4���D"l6�@y�	��?�Ted���7���|+;ַ�������D�+�}~�r��(�eϵ|�5m_'�'y�W�l.�Ǉӛ�1'��}k'k�$ʁQx�q|��l�����~�$.]��,>�(�i�5���8�*�Px*��N�'LOڣD�Ԧ��k�eM���#�cM;%�S���M|�ݼ�^|�����������d:>�kL�Ϭ�nt�9��&��K}�5�5
J�����N޸4}���K��z�jr��M�yB�+��w*��S���yU7ul���Z�
�I�gH��þ�����:��I�	?
�o�+�:�}�&
h_�N��`����	�74��(qy� 7I��R8����{ثDB�kz�^�^�>i��R������ipy�i�{��N��3t?��#Iϋ�BG��E2h��{7���uS���1����ᘯee�����g,����7��6^�iu��s��g̋�ݯK.�ś�����d��.����,g�fhL�'}�h����u���=7]����{���3��F=����J_�����w&ı��6�ֺ��K�Ei��4�}�&�P\a�-��,/l!�<f��rc�M�{%G�G��U`�4�F@i�8�{��J$t��{U^�����UKm����]ֽ���W_Ϻ�=i%=��y�4���nf�B�����h��˩���h��ަ�?���~i���vݾ�9�k����-�j�c������L|kR���Z�]�py<Z�h俶&F��-��봈/d���Ox��+Q|$&���ɹ~�_��(�Y�9�*$����,�sd|�%��6�}��K��wx��8�6�,>c����}�O��~��f}�܅�[��M�_w��*�����|���x���=z�i�K*�壻9��6���� ɝb��a��p�|���ŧ�S�3�?�`����4�p��F)q	���/>�s�1γ>�J�t��h�q�G	�6&�݄��yql�wM_�n�˙��5W��b(&��>�_���~�i��5�����t���3��X25���~�/([b�Zf"Nz�������-?"$��s�O����l����k?v�k��>����k�\�O˵��
ћ(��#�]�+y�9�c;'�oU�yޢ׹9͗�3�d���8�	�A�T���_���0����_0EWLq1�2M6����B����ki�O����S�S:r��F���\�L��ϡ�ә���q�.����4zf�/8};�1�E�K�Exn��2_�8~~5eٟ�'��r�듋���oE�i��/���+�]�=If����s��	��8�$"�9�y'I�;��T�h�hjYҚ�~�x�b#{���IM����Ւ��64��y�jǦ�V�[��T���Oя��M��<����B�����_uLm쮐o��/��~8���O��F�\�9�cO����VÙb�s==S��ckG�qg�*��?ا�8��<s�?�p��-��-��n�{�[�HIl�o�@�l�/zV���lR���X�3�'�?�(ڛ�l-��L�)��Vp-&��gT��]��oŔ���[(��7t}�� ��ƅ��k��?@�@ �T�W!*�е�;+�>���j��ڶ��@�c��G�o�����g������ߌ�osV�V�,ͽo0c�	�Mʒ�$�c��0��aB�� ~�KK�X�yׯ�	-�,hO<B���hzu����O���[��D<���K8�Ĕ�K>���S�S�9eQ�S�������92�j��R����,Kʒ�=e9�����L���{��~��Ն�VM��K��oy��U�A��o��j��&����˲�͡9WͶw@֯}�Kx3b��i<���B$f��_���P~	Uq~	UqT Q��;ЇÝj��N-�m�{�[�]�����6�>��m��>��H�8��8?杞���@S?vw�.��벻76�t��og���N�.�Ғ�g/�=S�ݯ8���U6ɻI�s�&����5`�
p�N6�r��X#�ٴ*,Sy;-�dJ�9�N˹��=ڊ�i9W�j��b��d]qN���[%����u��ȸj�R���'�K�^o���v�UH�����ig�����Y���3��������&x7)K�?�[,��8m�a��GZ��!�tH�f�N+ޙ�c����q>��p;��h\��4�N�R�)e��H��?JY@�#��(,�i�{���ޓ�z;�^�Xr�f�����ӗ�0� ��N�&;�r�#dSCI�".�!�:3��<�.�!�k��bd�+Lɨа��,�8 /�T!Ѻ�@�������-m�o蟢w縣8F�H��?�;���%��6�}�;K�i����~���}c�V���F����-�rvQ��[p�ӕ67�|��D�ݮ_p��+��:�n׋���������} u�o��qX�`��:I��qk���r-��|ǃ��-I�zN	�k�=J��?3����M�0�����A!9%�!��kIyi�d\�I�%J���m���S��U�)_2M�H��?�WA�#��(,�i�{����$D}�W!=y�cFTAvk>_6	~�y��]�t��*u��7z��Txj�&GgS?Q��>�*��)���
�J\�!W	B���R�BZ����TJo����R)�9�r�ؼ�1�1�?E9b*�Z�X��q�T}8b��(Q-�m�{�|���1/���0Drn-����0v2�i�h�V����a���s�M��V��yn��7l�93���k�\v_	a�.�ɧ�#O�6�Y'ß!uȮ�O�߄�}X`��>��46m/���e0+��c#p�F�y���f����'J���	��;I��a_�z<)L��f�g�MCF��3e8N�yb�x��y���<m�����s����;�L�0=~F�k.[r&f'럵&�Zv)#~��
��ɛ*$�i�GYȴ��f���C���BrKۀ�j��?�s26ǒ���?Eiq8-�eH$t�-A�#��(Q-�m���pY�r�H~[�\���Bɿ�ڧ}a8�?Y}��|��5�R���<�&1��r�A�W�����\j��I6�_�I�$e�W&_O�m�{�o�Ǫ�s�ݗ�.�\c�L�4�������Ա� ���(7r�����'l��='�#��򺔷���b�G��	շ����TJ�C�o����6S%��'T	w���az�K���'�$�;ӯ��(�oE?�>+Ni;��p�DB��Q���I{��Zj����}I�}�����霉u�&�L��_9��ҧ6��z�ʾ�s��is���͵������LK���~�(;������'Ng��3��<��o�r�1����{��K����XQ^endstream
endobj
27 0 obj
8816
endobj
30 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 31 0 R
/Resources 33 0 R
/Annots 34 0 R
/MediaBox [0 0 595 842]
>>
endobj
33 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F7 7 0 R
/F15 15 0 R
>>
/XObject <<
>>
>>
endobj
34 0 obj
[ ]
endobj
31 0 obj
<<
/Length 32 0 R
/Filter /FlateDecode
>>
stream
x��]M�$7r�ׯ�����V3#>4��F�ecQZXރ���U����bVM�tuw����S%Ɉ �d0��?��������O����i���_wZ��O���~@��}6y������_v�����{.���ߟ����T�����_�O�������u�o�N����y���d�*���z����E{O���Z�߻���o����֔�©-��?x�JѤ� W7��k����A�-v_������~�榩����k��k�B�����J)��j��(��1�!1XE�(�jV:yR���Z*Kǐ��?��מ��+��c�*ْt({��D�G��Z�6��.P�B��GĽ���b�m�{���FR���XV�����L: �<��ʫ�к Zpʘd��Qh�Z�XҁƆ��gܩ���9�F�����a6MԬlKG+A����1��<�Az�4���j���#��m�A��ym����c�C��Z�h��_�>�RN�%�"ek]F�?��|�4<(����2WI=_k�N��yF�����hh��#�d0�4o�FD����n���7�F��e�K^�u���Lv�p�~�#��:&9��w��i�jj@��kN�V'E����ΊcKF3��8�A���Z����h��4ؤG�M-�#F(�#�i���nE��C$@M���4'F��7R����h5��g#F�7j���4���Z����ヵ�s�y���ijY߷#�j^���i�-�|F*�\��P6�[��xR�k�"�b:$�J?�&T�	g�8�\���l85���	�Yz�a�Ԣ�oǉ�:��Y�ȍ8�D���|����h��\ �;N�4I$���ÝJ%�h'F�y 12#6������jd��>�6y'��X#hjQ߽��J��"֊�p�KU\Ի8j�b��81RI&��qb4��Խ'6�`�P[(Z9JA����ǭ��9p|�kl�Z���8��7����N�8pd3�0d��ʇS��p�)��8��N�{1�&T�	��pd�V#C�pj8No�c���E}ߎC�diC�r#�8p`3���i�X��}"���sbԤ:ꬮ�#y��mf~b�D�&3?PfD�'l52tn�D����Yz�5����tƉ�V`(��n��"��J��hc���&&�S4�Ĩ��&��D���i�aV��R�n�FD��1+�<����AS���'�\�;Y%��i�'lV;�O��f���4��p�+���XQ�J����ӌ3N�jd(N3�'�g�F�Ԣ�oǉ�f⒍s��8�D���h* ��z�QRF6�Ή�M*ZAΉ�/��#�BL�ee�F�pƉ��A����8�9p|�Y4����tƉ�Vd��3�Q�J|����
s�s"�5��9'V<��EN�@���@fe`(,��j���>>T�<���Gn�Z���81Vw7��/� g�8�Y������Q6�f�N�'*ś`�S��꥞��ӌ3N�jd(N�+�p|�Y4����qbvQYKrxnD�'l�]RN{g
G���|f�9���_�`8'��F�ZX"'�T�H�}�2#�8p`3���s�'�<���C���E}w��3Nd�C��V��zP�z��#�,�Ģ�ʞ�V�9���s�g�D���i�aV��R�n�F@[���A��ͳ�P#hjY߷���4���p�qƉ��U4�h]�(N3�'��r��zv�j�A��ӄ��4�6�ʆӌw�	�Yz�5������h�ֶ�n8?ci8����{��q��"K���f��|���xV4̌fG͚��\�fF��7�57OGZ�}n?ci��3�&=��ijQ��K+���`�x��p��9��y�f��'���=K�;c!<��7��D�kh��V�(��m������<�s�IzV㬩e}����E��éE��K��4E�Be&ݡl8Ά�1k��s���b8�P9�N8?yn8���9��	p6� ��g56M-���Hs��6G�\��c��w����-�?^w,wč�ʻ�s�)8O�<�,p��W�i%�5e��)�hn_C��<?��l)��8y�Q����ЎYz�4���Ɉ�\��,�~�f!a~�c���qu�?}���s����moN�x�}��F	�T��/� �����F�M@����|ꁟ�O�Z����q;D��B��?1}�~����aO��זE����+���;��̻�����e��gړ���=C�4���hi�i?6���'�	c�)�=!�7" ��]��]�F~�E���-a�^����q)ӘC��G���lНlL��m��&�U����'�PzCL�W���'��ΎS���\8����A�g�������}���2��x=�֕�Z�!@�N����y���"���:�����:cM4��k���/N]�EB��)��v�I��>�6�h!���r�
�䊑�{c�]q�t<�[OV�e��#�1�D-ÖJi��ܐϠ1�DӅ��H�@��#L�"�n� ��:e���U�;e��|^�9��q��l�����_�@8�'�&W�2�aG��_z7���oG��4�!H+�K�/�lL*W���'Bڇx�h�eCш�����s�ا����(:S����	��X��k��f��0�5~�W;[e}o�Z7ٰ�8�g�F�<6��$<��vqَqB~�{��Z6�p�;�<���֐D����.�l��*�&� 1�X����]g�����T/��=7�wFYI|~���c9�xo�ҍ����&'b��l��6Ő�؈�����\��L�Z�ht�N���.8ߝD�{w�]�����>��Z�,�|եB�P�7υp}C�?��y��O4|O�r��_X1Պ�r��8os���}��/D���'a=w{1y���^|-i?�>�;K���aN�ޅ9s��p�?Ftd��c9��/l�56�FRʰd�����A��Bi��J��z��c.�I� /߂��ː�9��~�G� {)���N��.�/É-K�W6�K_��ɽ�����ãQ4���m^,g�r>�,䲣Y(��,�!g�2��8�vc����'S��g�:�[*�9=�jŤ�2ž*G���)��fP�h���)��s0]��*��|P5o�/�A����.���"�r%��"�l'�1fnю� �3���T�jt�Z����Ԕ���/H�Tg�uj��Y.����X���|PN�)�C8^�{p���T������]9A>�m�5���A����~'|�}"=�a��*�V��*�bp���%M�i� ~@�fE�!�P��[+8+���xg��/��czj��X��$�G�i��Y;��HS����� �)ã2���+��F���'&3䊤��Q��F|���+
\iq�b�[r��r��o�_3[�j�����^ո���ϔ�t�L��)�\��0��e��,�΄�Ƀ��'du�����3�쏙��t]�?>2㇝*9�M�]T��_�64y�J�(d�E3�2�*SR}Lk�;m�Z�İ}e��g�G�w�p�
nYvZ�p�e������������H�չI�ʭ�s�]�N�3�<���"Z�j�\��D^���Ul��J��O�+����=}��po��|^�i�ܦ&�F�K�_�o�)��f\��e���徔�K����uE�A�Էf����P����g�/Ɖ�ț�}�����/DҰ��
�v��
R��.��i [1�+�#g�cz�䟽F'�S����J��z�0����N{�Y 2M�Dk�}��Rϝ��NuVL�ba9\#,\Mb&����}!��wq��D��N��|�1�̄"���
Ջ�ҵ�;����N�s���ң׿R�Ov�_�����/���=�b;Z�f��ϗ{��ޒս���ޣ;��q��޷(����c�c߶Dי�\굟���D���[H�[���;)�ǗI����ҳ]�[&k�ú�$.j���ub�+R�-8���y����r�KN��Ä$��z`Ínqt�dGR��H
�+R��\�9s�"/M
�bC����d���ɊHv$,%��o�i?�6������_b���h�Jޢd���sw��r�2�7$
�q�L�"���!��dTw���|��W^W����������%y�n޻Sې�u˵=y�\^(`���ȻIj�[L'W��y��~y�!w�(c<��i�!m7f��]��$$[�>��>�x�u<X��`���!~ؙP�Ę�&e����dt��h��B(��P�;��c-�A���� ��!�����bJ g1%�w�N52^e�{��ݫ���P#jjQߏ��SB�qk�}�; "Ȇ}\���K��{��M��5B�(�q%��E�C��Q1ˊ�SC�2�޳��E���n� 6�c���(�LnX�l��E��+r��ҍ�B�;㤂bpž��y�Hc��7�.}J.���a5on�k�9'� ��ǂ�������JT;�����<�V5r�<r�x���g��O�lR:F�G*�ƻ�����t�!b�r���:\,���OA�7�-qT��8.�Δ���:�:����3<A�=+C���C˗�|��8w�q�O#�8��]��ܰr���D�r�5�pm�x��� �'���'�_��Yer��EYm�!y�n|�R�"������S�!G� ��XD�}ϕ���oT�SI�Eg�cC�ȕ�s��p��u��W�|)�Oz��O��S�Dq(>o�)�������(�KL]��U�y'>ե�c�7{�����W��c>�[2g7sȆT2�3��7��v�l'��D,D���L`���/L�4�m�����ɉ�a������'��-�}
��vN�k�Ige����e��xZ�~`�5*�L�sWa�r>���a���p!>���*?v6�\���6�C�Ì��طxԏ}����߷H�)W����oa�WS ~`�K��m�\��X�u:�Ӆ���F��u|<�ö4⏍��>6.���=�%�1y̺>:��""O�d��Iy*�=Xű�w�!Д�������+�J:��/(�s.���i۫�M�A!�Feu���lT�8y��G<*�Btz�56�`���BC�H�H���������U^d^��x�r���f�Y��my>�ے�C�z)�,J�73f��,���߸M�M��	�-���*Þh�8�HٱA��q�[I(����J*(#�?���IԴ�jY�輽,8�o��j��3qm3NU"o�_~���@6$��5��6�`���኏�v�a��}�iC��W�P1�I(���@�h\����J/R�Xzo�5&�"o �q:�	 �0Y��U���%�mɡ>�li���Ϟ~`x0�Ӣ1w��Wq,睬��VS_vN���FՄ� w1 g�֪b�0�Ӈ�<��odO:��;��;=>���?���r>n|�ż��,����n�oy7i��І��aC�/d�Vf�s�k���OZ6$g�gqj"-%��u�Պ��L-�D~�>�����3Mҕ���f��c{l�^��CD�� �� �L�G��տ�\M4S�K�óQٛb�+�8��N�KC�6{R^5��y�GD���c�:s�`���b����; {��w��c޾�y�\�� �m������M���\�;�F�1�? ^�U6А�܁Y�Y9�ı�!�P�h:�����5kן+*���C�i�~`��Ѣ���M�ne0��Y�q+�٦FGz��2�>@��@̐+�>">�cV���c6�oѰ�C�p���!Z|��=D��t��5�~��bX6�t��_dd��k;��-�=�9"FED��29�-m��c�K6�ȗ}��f����<o4,�̫s���nl��jg^n��{�������I�e���VhA��/VR����Y:����/��3��.�]V��s/�mhH/����ę�����JT�9�
��x]�.�:΋G1�	��Et�8�K��0�r'�$��9LS,e�8�jx]xCVۡ)�φ/T���R~���WD�?Y�f�.�/������8St��;�5}h�.^6u�e�%��5Ak���.1��攥��?1R�1e��8h�u�{E��0��kg�dtM`�5o�r͋I+�%L o+��-�F����Y��}�o�����e9l��W���zÐ��k��v��0oԽ�+7�2��[�K��f��rc�N�s7~�y�T���^A���%��oH�W��e�v�
�y*nU�����֮y��r˝>��0�2��;�N�P�;��e�.�������/���C�Zendstream
endobj
32 0 obj
6386
endobj
35 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 36 0 R
/Resources 38 0 R
/Annots 39 0 R
/MediaBox [0 0 595 842]
>>
endobj
38 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F15 15 0 R
/F7 7 0 R
>>
/XObject <<
>>
>>
endobj
39 0 obj
[ ]
endobj
36 0 obj
<<
/Length 37 0 R
/Filter /FlateDecode
>>
stream
x��]ˎcGr��Wp=@��� �ɀ	���¨�l���Y��I��=�˼�XEv� U�"33y"���?�������/?������/?�XS������~B��Muu������_~z�������"�_����^����G~��/���m��鷿n����9|�෗�i��B�n�WgS5��	������~��?m�F�Z�]K!���~��|&&�}��F��ݿ��3�`79��i��	>l��?_~������,���g�+)�ڭ6���K�͔R}�/ۗ��q6:j�KN޸R�wT�/1�XB@ؙlm͖���d�jK���`�!��7Pip�ۚ2y4�W��K2��fk̈Gc����5
�{}��"��C�\[�%�f���6���7�lv�6�A9��kt�1��l-�Ů2�t�?� ����S��T�j�@���@f�b�����p����>n�Y�-� =��:��n�_�]��ɰ�.��е,�Ov�����]���J-�Si��l}��Eϙp�sf��Z�SM�����7�f��s�{�I�)S��H�;Rn��s���3��L8�U�Ӧ��Ť�7�Wg�� g�8�&ٽ�"J��J���]ة��QlG�d]�60����;4��f3��nƑ������n�g��Iz�5uTߒ���9�a�Ht3��F^SȞ���\���_h��8�u��PcB��@���@fe�,�5r�оW<[�O�#�͚:���]w�k�;M8�>���m16�0�u�	�iƉ�R!g��{�'��;M��N�)pƁ��FDyw�)�w'�'�F��Q}_��K0C�pƉ��E�M�����BS#��!���qN�1)��`���KW�oF�g�8���Щ}�A�-�'�F��Q}N��'�Z�� gv�&�-זkT+�v�c �PP���o�]r"�ۇ�By���PX
�m�ѩ}�ʳ<[�O�c������z��]�92r��i�'l��l�*B�u���	�DD�j�ȉ��i~���̨�N�8p`3����;�8�N�O�c������'�B}�*�Ň8�D���hZI��K�%�SM6rN̕���ޡ���JCN̕�E-���=�̈�3N�jd��>Ɖ ϖ��P#j꨾'B�Y��P�3�+�$F�$ �Z[�s�k5qN��ԯ�GN�@���@fe`(,�6��ܾW<[�O�C������'vW�js��i�'l�Q�՜+GYw�pѝ wT��;f�j�.�j�9��4��;M8�D��͠F���4�;>I5�����z�X��lj>r#�8p`3rCC�׮ED�`N{�<u�VK�X2��B��"'�H����(3"��6�:��q"ȳ��$=��:�o��P:�DV+0��n�\�[D#��)�sbɁ�F�R8'�L��F4�A/�>�ʃV��R�ns��N��V���r|�k�5u\�����
��Uw�pƉ����'|_~�(�N3λ�k�y���򙦜.��4��;M8�D��͠F�Bw�qޝ ���ASG�}=N$�5�,�<7"��6���ܲk��ԝ�ZΉ����x��Xi,�r����HsR����@ eF�q"��fP#C��1Ny����ASG�-8Jg��j��ٍ~�qUbLY�	�Cm�k�E�*b=�k������D����򠕁����\#�S���gy�ܛ'��YS��}=N��K���4�6��j\�4)�(�N3λ�����zbw�}Ȣ;M��N�8p`3����;�8�N�O�c������'��L�Q��V�q"��f-ZC���*c��
M�[�B��8'�J:h���B�n�i@�9PfD�'l52tj�D�g��Iz�4uT߂�tƉ�V`(�Q/��e��2G�)rd1Nl��9�$9����D��A/�>�ʃV��R�ns��N��V���r|�k�5u\�����
})&�q"��6�h�jR�(�N3λ��敡f���Q�s̕w�	�i�'l52�u���	�Iz�4uT�#�t���3I�=�B���@}��;✸���.��BK��#p�q����X�U���Q��E�����]��c�Rp����p��R���#���{#d��h�y���`�5��ag`*M�h8h7P#6}Aԩ�C~g*���.o�=��\������
]�y���U�~q��y���J����׍������ň���/���M���/}�= UEm��"���+��W���z+��; ̀��;^����݈�]6��Br��S�)#�E�e�����O�-ଜ?J�gz�[���L�u���s�o�8D���x60�]�e�o�1��&wc1���D��!xWi�9������b�\�t�d�7p�{ek��[+U��Q�7 �[�73o�֭��ְW���VI*��@�����������Q�Pƍ���k�L��{)�g�W뤀
PzU�����Z J ɮ��'�py[e;�9���qp�r�ڱ
�p{�r��(a��5���=�՝�M����*���b�z���2~���,��,��a����NiL6LkLJ��Z�A���?�C]��W|EFNݰ�p������z/�+�K�)���*
{۵�[��+����a^4lE���]�щ���L�2g�BccY4sɖ�B��;�x<��t�R����N��È�����&fPS�PJw��>��g�~��}�!���ƫ��0=�"9�҅�.��C��[W��!~�t��Fs�4��%�]	1ķw��~AɉE�%�� ���������mw�FՄ� �;j3Δ�MJ���ah�Z\v�僧��O��c�5h�q9��i��Z�וV�4��:���~1�9ɢ�Vg�'T52D�nO��Q_�nۋnԇ}.uG��ex�w�'l�|�r>����O�
f?��[��]��:�$�� �R��]z����t 9d�-�K�-g�+���v����ܞC41�Z��F�
�-�2<җw!�٭�yP>t4H���I�I�-�'D5�S�#�k�����
�S�*��+�U�"|baIQ�qS����݅�>�����J��o���1���ov�i�r� ��~��?	�	���� �a��l� S���va��Ě��/��@Uɯb��_�L-�+�U�Qah�'�>�\�>�t�R�����rB�g��cc4�s_��D��(�2��HkK����<h�Mm��{�؇��!���Cb:l`�g}�zK=��7�5�jG����@��2�_�H��"����<h|�����3>>d|La}|�2I]���6ƛ���n�;�+b�C+��:,��p�=1�d<���n����P�"�-�aR������yPbv���S{2�C2sY�\�N�,W�4�)���x_Gѝ,C��T@X8�|1k�UR�RUKPf���4��G��T8�V��d���g�+oʨ�_Ç�p�do������5�~���w�S�-"�e���1�X��K8��1�,	��g@|Ȁ��m�W�
w�k{�h�3B~�y�����5�������f�2<4�)Gqob�r52�7���L���[��������p��w>^�953;�eV<���;�<s����{��V�������2<я�U'��,�XΣ��֓���<C�#���y��]�T̤>�\�|��z�Ȕ��YyR���v9}l�-�s�y]h�0X���<hd��o��Z����"����U�-��n�[�1󊻠ó+b�vA�b�$��k�s>ߞf�3�m��;��79{�aķ���⓸��c9�J���M��"�4��4�ϸ.�hv����b9�}��[�jͦ���Ur��T�u�o�[}����s	g�<*�Ƙ�U����c�j�������K�Of>�����ʾ���X��Y�"�[����j�MܧXı�Ge��qk��������3.��� ,�W8/�$6��|?\_���_�[zr�D��{�/��@���J���og�~���e�֌���+�o����,.e,�X�a�O԰�O�.���9�C���%
��}�i�P]�ߴc(�\Kj=m&�dr�zra�Lt�d�X�llߌ�r�А�>�W=Rp�gܒ��Y��a��d�t�g��r��~r^�;?)����g���Я�܏P _��9�<V~䰣<�poéᄃ�I�gT��O�+K9���&�w�aT���K�,U��.�Hi!�++���A'�^~D���?��:Y����7��u)�@�m�v��qS���Bd:�tl����aEJ�ʸӔE��zy�����.�J�l��R�%���N�4|YX�~�_Q~�r�(`��ma�~�+*����T$����*O���p�cixzV�0EYd�S!���O��sc��s���A�E�k����FT���¼�TR�fc�&S]D��ᖼf�ۿI]6��P�.��5���ɈoN?&W�7�q,烬�A�����U���q�G5a9�C� �Q�}�,o3G�q�Z�x~��	.ِ�i�i���1?������D���b[�7��>~�j|�ix�Jo��{\j�z��0F9�U������I��"�2.CW�.��5����9LhU�eY�
`,�p��?KS���'T���_� �'��)����-�c2}ץ��8��A"�'��(�7���K&��C�i;�BL����v�P�d6&x��'��&����g�`�f����\����H�;��1��R���T|��A�V��vi�n��iƾbc,��;���-ћ9j���p�-��6�g���S�QGd��-�|�#l����a,WOun��|E^v�V��=_�zvo���53U��X���\ܗp�x�U�#��;V����8r"���EjD9��ũ�9^�UsY�H�FQ�ʋ����r��q�y�s��_8��l���>�Jq1ԏ�q1��w$:�\���w#���%����r���xoiL7�̞�l%�b�s����c����E\��I�$z�0�m���E�����Tþ�p��.��o����N���Dj~�
�b�a/Xs�`�����c-�ϊ��.�ݳ?��z�º����1{�LmȔo҉4��_ѫT'R�\�^�t:~p����u�	�������0^�"FaM+��zu2Omn�ɫ*T~ũ��W�S��Ѥ�*%�n�܆w7N�C)Y~ū�6�ɨ��.U��[[NTC�P\u�g�2'wȵpÆ]`��+Z��!�j�R��o�w�J6-U_w/�hlL�Pķo֤�O�=�E�� {�p���&o|�
�G5a9��8�Q���Xw�YZ��.��Oݥ��-i�%W������y��6��|�N���ɬ�7��ӏ3_�v(@�Y�Ǖ��z�^=1�v��ݳ���s;j��ޖ�8��A�ו��[�l��%,���b6���E|�pO�PlH�3�"��|�`v���J(�[$=_�y�xP��C�Gfߒ�oJ;��R"1��U[O�*[8�exr&�Z�H_��c9J;4~���'�<"�D?=�5�s:|Jk�Y�az�h���Ϡ�j�Iܵ��IWE�C�/�'Y�D��\�M���)�2�o����"f��8��$r'���$��$�>V��6ϥ]�����q�35������i��˵R���C��8���ϛ)����iˍWe�WC��f��ؤ%��B:��[��U�Af}R�P�Z�_��� �^�S>�Ԇw?�a��q5�}ab�B��X���o^���(��,�X�A}ʤWctV�'��9�pQ�/���p��f<@]f(}-��J�J��fB�a�����8ߏb��e�}3��BC.H����H#���Nvj>�8k��ó��tp:�w͠���&[�����>��t�ON@9�Чz�s�Mݳ@}�R}���)|=���y��Li����.�&��wz�.�^s�i�J�J?�ds_9���3�aT͈�!�I����L?�DcWB����\8M�Ysi ��x��m1�mx�GSBr�m�ƜLud������+�g��A,�a�52tj;��l9>I�5Κ:��� �{�h�sК��E�fohm�+�~�,�S�,��N鬳u�_�,9�Xq7�6��W�p=�.̊���Z�y�5�j��ޕ�ϣތ��'#g|�p�L�)f���c9d�	؝��'9�hФ؈����!� Δm�iRj%+E��<�Q���Cm�4dՖ3��5�-?.��8�-0��Io�e+���B��O5��ֵnC}&X[��i|�;s������
NHK8��Ab�٧x}��P�y���X��7e���w�K�$��&�L�P���zRcb��3�[�Wor�.����8��A����O��j���:�[�BٸP]$�Z�q��314[�h�ـD���&m�L��ǰ�g�`�f����\�����@����ȁ��Y^��XE+��)N���ݳ���)hT�-��j�/J\�>�Z�Z�z��Y�y\�����k��9~�k����A������l�*ӑG��O��5� @�?����u+�^�p>ц=@?�5|�g�/^�R�]�]z��N�fj��4m��hK	��zFMZA��PǦa�B�tU����0���(�����+scC]�Aw�߫fe���VdG�i������}��������;h�oޏRd׬�$��c9d� �Ә�z�<�hn]�؈����ap��`R��8�z҄�Q�~i1�� yio\�T�7����o�@�}����d^t�d;��ժ��cAj�za�|�ұ��0)�Ҙ������%Y�~�h�,�%���fX���n�ڛپ�sr�Y[MMŷ����5�~\Q��/�X�	��\���H�(����[��bJ��yę���T��h05W�yTfO�����<��B
dp�q��oF_�@h�I���g��������١��c~���Fяu��N/���S�E~D��:�|��N�����꒙z�x_���n�D� �+c�������o��x�ﾡ��k�͹�N����E.��� �	0�	V��Z�L�ν�mm9�������<�mR���k��^�s�}Ѫۚ�+��P���6��$�w��AB�=>!�N;��Xx����8��ڽ��X1����~Ya����oo��endstream
endobj
37 0 obj
7118
endobj
40 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 41 0 R
/Resources 43 0 R
/Annots 44 0 R
/MediaBox [0 0 595 842]
>>
endobj
43 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F15 15 0 R
/F7 7 0 R
>>
/XObject <<
>>
>>
endobj
44 0 obj
[ ]
endobj
41 0 obj
<<
/Length 42 0 R
/Filter /FlateDecode
>>
stream
x��]M�Gr�ϯ� ���0,)Ҁ�a�1ky�h-,��ߑ�=�/"�&��=�&5 �<VedFF��������<��??~����?��`���ϡ��Ŗ��o�~���g���OE�^����~<�pB~��o�����_鷿����_ί�~{ȮL������&�)U�F����ÿ�p�;��L�gk��T���䣛lp)��to����W���9��ˡZ*�;���z��$,U�J:�����)�cre�i
uʹ��g5�h'k���"�U#��H�dr ������L�%���>�|�6�Ev<N��lb=� ���!Y�P@�Ҁ"U+VSBB<L�XS3�$"���� 8��8�$��P��dceZ��jZ.�jX�2Z{M��T�A~�6�dCD���=h��G���'�O�dJ>�D�ԏ����4S���)2{	$�����sDZAS��n=���!5��r�f��-����L�L)9���}.�L�N���92�����:'W�����$�7&�j��'T����'�k�\��`=iޢDD��,���|o=Hd�Z׹���\g=�rJ�w$��� G3v���9�'�w����M�$]ǘ=�;J�yJ޹lY7v�wc�9v	�Kd�R?F��N���(4��oA�P:#F&i����TC�������c�#O�	�ɒ���@F�]/X?��{�J�~�]��{������(�kj]߷#�f
�D)ʝ��"��g�M>�P<G�;u����tI�[@@eDn ���;�|�%2��Sǹ;��%��V�}CN�Ը����;�9��,��S��z���OA���l	O����M1�|6�$f򋐓��;�;��;�l�%2t����Ή��(4��oɉ�tΉ(���*y.ϙ2�)�`]��*i%�`'f3Eo|��b������^F��R�ߺDT��� fi���z��5���r"�B
��wZpΉg1^�|�%r����q�N��gySZT	-!+�iA�;-8�Ď#�u�e�q%s'��֣D�Ԫ�oǉ��Qb�5�N�q"�81��zW��(�1rN�hmr���� ^�XJ�9�9��)��N�u"���	p��Х~|���s���z��Zշ�@���������TIT�%&�5��9ѹHZ��TΉ�Q�b>Oß$v�`�P[��e��B)�o]"�K�x/��9��%vM���v��L�M�r�g�8Γ)h�9:�g�ܝ:��	p꣐l	ȉm��C)��q"�8��ܩ�ܝ _Z�AS���!'&j\�9щ��qd3�k�9afh r�	N,4�m�X���d ��_��i����(�ĎsN�8�Y��Х~�{{8'�֣D�Ԫ�%'��9'�Td���^��Ύ3e�s(�i����$8�P�����qb������^F��R�ߺDD���^����[�����}CNl�m���}�sbǑ�(h�D�3%w��sw<L4c�s��%Zr�.w����;�l�%2��Sǹ;��%��V�};N��>�=�'�;�8p`3l��#GI5�"�aN;��9'��͠��}�L(�l��|�'l�ԏq"����� 5��o��P:�D&
p�oT1kr3��J#��'�9��q"���2���D�ԏi��z
K�~�]��ȭvi�Q��փD�Ժ�oǉ�R���JwZpƉ����`���̝\��k͵�8��|�!V�N*�i�'l
�� _ZQS���'�te�.Ҥ�w"��G6��� �R��d[��'����щ���bL�2N̡e��) ԯ��;�9���~]"C��1N��0N�֣D�Ԫ�'B��Td���^�L�|�9Y��Rv�[�Q}��D���yƉ]/X?��{9J�~�]��{������(�kj]߷��f
��\�;-8�D����L�;%�:�ݩ�ܝ �4@x��DB��5q�p���qd�.��̝:�ݩ��(4����q"��S�'�8p`3���H��Q h�0"N�s�!P��9��"�0�MO�i���� e�8�D���@"C��1N��9��%��V�-8Jg�ȤC���eڊ3���ā@'�9�B���Q�L���֝A/X?��{
K��DD���^��9r|i=J�Z���8��B$���8 g�8�Y�3m�����Sǹ;N=�Jvlݹ���;u�+��6�e��q�N�/�G���U}a'ZC��ɤ(�|�jD�H����zě��`o��OqJ��6̥�{Q�5��|kࡍ'4��%�.�4D�-)���G֞���rn��X)|#ݓDDqkF�5�mw[Z�����}�ğwo���~�?�m�<��h]�D��n��??����A<|��`O�O}�����.S#��r�'jp����=��'���H�0~��*�p_�S=>~��}UŇ5�Ǧw
�ϕ�i�k�Q@�k����W�U��^<����O��2,#�W>�@ܮ�� �LJQe�ч�R���|E��iTSe��m��"~�M�Q��� �h�W�7gsv�h�O�B��56#]�,㒺�--]q\3�$���⬤�1�w.� '�q�g�LDY���qŤ5;ՙ��E�m��:��)oЈF!Ӌ�ƊZǆ'ݿ�;հ�ƫ[7�D]��Ԯ
3�'��8��~���L��P��1��-���H�M�2 3v]��;*f�$u��+�WA{ٖb�������-��Q�����M+7P��s��H��>C54�?I=+)����6����-� 1ғ��c�8��<��1��anL�T��z������ǚȎ'��a�4�j��A���y&��'�Ϲ���v^�h�@�s5ď!M�{>�ɝ���Q�h<��Sw��;����T�E�.��@����7ԯ�<��q�s�8;��Hd(��c'��ԝ8Iwn=J�Z��[ε�\�ɕ�H�.�M/�����q�������%O��/�9�ܔEc�B�!�#^�G���G�Hx�bm��w>O���|�+Ee�P<��p8��x�
gb�x@��M&d��a��u��h�9�v���[$"������ٻs��Z٢�u}���̢6�M:SA���U`nF�^�r"���D��O8S�2S��w�r���ڞ���l�g��� k���*��oS�"���u���Y�Ԉ7r��j�މr�	ХF/�I����[�h��5�q��&
j���볁��}��*C�C�׆Rt��!_�D����a����b�*������ؤv,�"�S:UF��q~k�g��Ê���~2�Nt�X�|�T(4���ڄ��!�Wã�it0�|�5z�C�(mF�63<M��%:�ؒ�mG:ԯ�,�������ЋD���fv,�6����֣Į�u}���sI��d7���MN��ȪЭP������qF�/¼:vѣƘ�e�a�J��+�c���^ڱ:�ƕ�V���+/1���<�۶����R�6#~$�Lm�~b�[C�xoLN��J���p:q<�pO\��|�U�XB��:�s�_G���q>�t\�%?Kd(�g'��t�8�}n=JDM���mX9+�nѝ�
	Ag��������BT�y�&P	�a�e!ʙ�����>��n,������U�(��i�T�<�������x��.�9�2Z���]z�Y���xDG��X�a������>�qA�e����x�}��Bm��I�x���,�����;u�y�X6K�պ'&���I�^�#t��Z�����ʨt��q�s��h���_��z7������T��d���v>o>��l�X�~���I�������y?���CՄ� 31����D�͕�$�f���G�lS���~P��v.s?�+�x�/���=���p}�Ťfgjb�ց�����d<��8�����]�v��sS��~|u5 ~dxIS4�̹,g�r�Z���J0�Ŷ���CAo��GॖG��Kj�GQ��]ȳ0�M�D����1�l��N~���[�B���)�vͬG���v�>Nr�8���;��O7bp�E$�u!��O�X
��L�a�%�X9�l�7-Hd} W<2<N�ג(H��g�~}��h��-���w�_@ߊ�/����"�Z�Tb�G�gQW}c��3e\I�w��
˲�w���I�v�O��i�Eη�8�x���U_�C��cn��US)��R��g��(�KTߖk�s��#�v�8#�<|%��t�v��Q��q����~�η-s]b�D��>:���(۞8K�ήp]$2.ee�¥���s�Qb�Ժ�߶g�QFtq������0�Ѐ�Tގ��U��GE��d��8r��[�O������"k��]0;�P�Tl6ܰrAh����ۥ�>���m���B`n{�;N��sN�Y�x�4�oW�����va�ہ�ہ��ҾY^(���ClG��~e�3�lp��%�Hd(��n��ہō��֣Į�u}�Χ��~�)�q�W��˽�}r�|�Z�쩉����S��b��J�Ԕn|1���]��&���v����p��׹vg�Q�"�j�q��R>�r��n$�g��7*|�ˮ ��4������R,g�k����(q�+�~�|��d���+���}j~��>��ƭ8UU�^|�����'b�Grne�L������DP��N��>H;P�4��}��H���vU�zªeUY�K�.�2Ǽ�`�m�Z��qV�+��[�e)�	���+��=��Y��nӄUL�q�bݲ���7�J>�����AD)8��Q>��BW����̙l��}z��s���է%Z�Yv�M�W�9B��%��w���G���T]d�WW�JS�Q��lu]TZV�<6�;Q�_�6'=9�OE��]U̧�t�u�t����j8�+�]9H�~_QCɁ�Uv h�JNRC��uy�� 5��Z�7������N�r(��'���S)&ۃO�lCi���`�C�Ο��a���R��	���X:==��O�ػ&��M;���'
{��������;��h.��t�~�d�8g��������yS�s�]��e)�oL �S�o~��ܮ�@wn�bhw΁;�|c2s���g�{,���٬�s���T�;�'
{����ڝs�Q�Tnt#���6R#����l�ދ�HiOx�����6RÚ�T/J��F���_x�wl#��p�{���l��׶�J#�H5�h!�a/ο39=���K�m�~/�Fͼt�����(���K�kq"�}n����I�Ӵh�ԭ6��x��$M�=���K?�Dpk&�(�J�hO�~�ߵI��ǉ�h#��I��M"�5�ȆwZ6�$������I��f)�����3����/���6��6YB�M݁IT�M�����i5H���dաIT�M���4-���R�I�z2�j�$�7�R=7Э��.BT�� �}�z�7t?���N�w|���.X�T�I������>B���;M~��S�L��رu�.�w�΃�/Q����������fI�r�|;���&���0��4���i"�[������6�|&|�����^4>�p�|s�bZf�P��7ό�7��]��ƍǑG�U�w��Л|j���Dߖ����θf�y�#�Z��l�u��.�x# �Sn����6լrY㛃6RW];�$a��z��m�?�7��wś���zx�����u���A�~�����H�y���6���t[�o޾���r��_Wv�î�u�x{���6��G��6+�e�ܾ��:�����������o7�zAㆳ��f����7����v��81�"�Voq���+��/3O�>s��?F޼��Yj3�z�^�4�@l<�hS_��q��Iޙ�zOX�C��͇��h��ŗ�#��W3�v�Ý���|��{>�|�z�+%j.+�1�xϿ���c�{��	'�Ե����}�����A
eendstream
endobj
42 0 obj
5970
endobj
45 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 46 0 R
/Resources 48 0 R
/Annots 49 0 R
/MediaBox [0 0 595 842]
>>
endobj
48 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F7 7 0 R
>>
/XObject <<
>>
>>
endobj
49 0 obj
[ ]
endobj
46 0 obj
<<
/Length 47 0 R
/Filter /FlateDecode
>>
stream
x��]K�#Ǒ��W�l`J�~ �i4��4�{0��.��Y���GUDF#+�HV�[��o���wFF��_����������_�����Nuѫ�?���O0n�tڿ�������e�����2���x�������������7��?�m�_�������/���&u��'���Z�ԅ��\���w�����a�KJ������?�Nb�6��=�W��]���&�}�0�5v����3K�R8�3�3�=tN��I{sgb���w��.�d���a��rZ{�o:S6zo����j��.����!ܪԥ�SǱG�l�J��ьV��$osޣ�!��ᇝ�T�Y%0�:���1D<#F������s���{4#��$�_@ S70��s"U`����S@U�8�[2��6�LQ���|�\�*U�U�<����!i�hFD�>B-����i�L���ohF��#\F�9P|�=�Qj��='~�R�R0�y5��:�(�l��ӈ�"���v��{��1Ee�h���$�(Q�/�	�0}H>�c3�"�ױP�-�i�{u�`�0��p��ǣb3��Ӏ��a�hFL�Iz3&6�D`>�n(Nl"5�7�*��&(���D�sg�s�P���؉�ÌAi �WYa&"�0��&"Y34#B���MD�9P|�=�Sj�ޅMD��HfE
�o��haI�0+He�6��TGa�M��	?gl]��0��~0���£ ��1:��p��@�a�xƑR��^�&���=�t�N#Nl"5�x���D�F��Ӏ��mL��M��싚�Ӏ�4��&"Y34#Buq�Nv�fĔ���z61d���e��pb��Y\�qb����e�����T��&Fp(р�:lc�|����>B	Nl"5C3tX��h?���VQj�ޅMD��HfE
�o-z4gm�81*߻d0��&Fz�B�6���P�pY(<
��8#F��QU�s(���ь�R��^�&��:+[Ɖ'6�ؚ�@y �u�B���`\>��=�3l�P�-�i��MD8�fhF�u-(U'���VQj�������΄@��pb���Y�����v���&1���"<t�I/ChF����#a�R&�8��#���8#A�����s���{<#��$���F'6�̊-Ԉ��d�$�´o]�D���Fw]T:hOl�H�>L-��el�(�o��G�<��@�a�xƑR��^�&��Mڹ4�Ng��D�ck��x�2E�:�8U'���*��#6A�<S�3���S�8����3��ӈSuB��{<#��$�׳��_Xȩ<;#��D�#k�A}[�z8�(W��5�lG<���`e���(�(C"�&"��D�#k�f��e}�&��(>�͈)5I��&�щM$�"�p·�y���9��W�<;�N5�Et�M��yGO�Ì�.h}�Zh?���B�Q߆	zY���a?��G3"JM�{=�؋��0S�'6�Ț�(l%гs�N^��3�.`�x����:]�R�.8��G��X��:x�Nv�fĔ������4�u���mR���&3�5}o���o��[���o{}��;����;�����췿�����i��o����	�G ^b��P��_�� �i^7�F. ���-�}��c����1���1ش�����-�}��0��:��o|Y���^��4���FU��Rd� ���E��k�`;$�+1���R#rܜ�ՒQ�J��Q�Q�e[T��Ix���f����F�w��oo%{�${�U�gCK�U!%l�r!�#�K�v���f8e�`d.�Uiw�d���s�>���c*��u%PR�K���"���._����~�$������1��?Sg�i8�R��͵�C��F &��Y9mE@�b6�ri�C8����,đ#��U=���e�8;�3=�ɿ_!Z�&=�V�3+Za0g�B�s2j��)vsa�Δ��#�!�;g� ���0l\�ٍ=�ܳp�y~f���=������\�s\t�\��E"L0�Q�;	&����k)�z6,Y�>��D..�\���|.M�Щ[	]�:Tl�u���e�1�;Y�&z$gCA�WEK,&mqIbĺ�Q�ҥ�����)_�ֳ~t��G͌����w,"`Y �19"X#d��
Q>���&�j�h*�	�G�j�HM��D��#�*ah��o���p�s�9��d�d-s�Y6��;7|�r~Ȋ��:#�r٬H<��EێH�pJ�MY˦�X	ێx��^�~Iv#la����:f�f�~L��FW4���`|�T&ƬI��S<��M4>Yt�U ,k�[v�cрl��톋��$OorR5[�����$K��|�Lb���+��ˏlTi�&T�b�8>ɧ򭔅<H��ly�R�q��"pFuqPN9fc�1� ��WL+�V>aW\}�!�b�G��Cd�g���c���Q��|�^�%�e��9�ot�G/i�칥��M�ob�"u���K��_�ě�XW�7�"z�̖O\��\���
��.��[�����L��T9=��%�Y��9�F�e2$��ʒ�>b>�De�b����� q˶��Y�`FV�꒯Tdwye�����2}O[�����U5Jy�r!�����g���kֻAg�)Q��"�+��˭h��HIC.�
�?�u韸`U5d�*�}����"���K��R����R���YR���g׹�b���q�p<�+�.���N������|��쒒�Z����m�c2�q0��׷Jo0N�mᓰ2OѾ��n�(�4s,4f���ex�q�����=gq����ق<>4^��u�����تP���}.��gh,@��K	���=eA��,��.s 3�Е��l��G�߱��r��~��t���k%f'����吮r![�2�T����
f��k��	0�^#�+�y9�8E����khc�6&,�����{І�rPԛ��d�'	 >�aN睥�K�q�K��;��:`Qߑx�	�c���}S4�����A�� ��&8�[��͈8�և��!�ș�>b�w �ߵ�pB/�t�^�c�5��|�i���%,�N�Ok��I��*����j+<�S0�7���d
TN�������'�{=�<�٠3���FDV��ݖ�yN�b������w���r2��b��d�k��\W/�R�H���U*��|�X|{�E��\��S��7y�V�Un���z�]6�Q��;>j�ʵ���2��w�,��9�zk�٦61<KS˻��qņGO������s���dK�)V�q�'��r�*��Y�J6x��D��}ϭC B�NgF2Q@���r�VOfIL��
^#y�w8,����`[�H��$,6R���>a}E����Oz����Ȯ3�%��&E���Wd1�7�Z%#s�#*sr���;���L��^�2�����}��ƒ>ml{|�˛%�&�����Jn�T��߲���o��c��Z#�amn`U�mn�"ǿ�O�-�_�#��:h�w�E�Jo9e�\�6�1}D�j���v5��IKc��5λ�7����%J�ym��cC���.WS��K�㬆��>7�������QW���G+���1�+�)�7U�O��
�A"S1 �J�۝����S3֘<v�<_o�m�M/���\CE6y��=�7�;n�!5�d��6$�����͔�.�\^'�ڐ]]�-������`�7[z��R��sV^���Ǳ����y���x߮���)�0!��?��`��Ҳ�iYE��!��jC���H2�������d_���ebӗ�����E�r��p���.>���]ߤF{�g�W?<�.�R��g��<I������$ӹ]t��d��`��C8!��R�9D�������]�|�]�ѩX��4w�C+���G��w��'���ӏ.����!�X6���L\v����V�ࡾ+���u�}����;��ƃR�.xM�N�y��I��cP%�x���)��Y�qB�~@ﬥ(�6h{���a8�����|P����0#�ZB_Ȇ#gv�Ѡ���/�3�i{�iY��N���c�9>�6�8�D;��r�>̬������gy�V������x���ԓl�K��}r�7jv��:�B����ⷓ?�ʗ:/Ot�Rh����+�W������vh���-7���=+�v�4(���N�/�"3L��ר�v#�0�/zsMV�5=o�xE���ؤ���x����������ޞ<�` [X�a/��kߋ��NȮ�Y��5���1ㇾ?P��V1`\���9�����������CxT���{��x��1�=�1����L�{�>���� �\%!�8ь�G���~hu�=�Sj���UҽRX�Ri7T�ܲ�y�[6���9��!8#b��.�������Ptx���#LS��-�ܩ���iJ��`m�f�ȵW��]�~w�/��S��3�A�U�\%����alE���y1Xce|�Z��ܴ)���u�b�mo���|P��<�64tz�w+��M�B̢5}5�|]��P~����W��loRo9����o9^W���[vCf�����_)��vQ�>�ug���c� x_�l���v�j��cʦ�Sè�@lp}���vI���n��v6��3���\_���7�47�47�8�6�H�a}$��s���{<#��$�?rq�\����ۻ���_M_��Z.3o]��О9�(�벾�+cR�&Lz�PY�j�EoL��g>_ћc�R"���֯Rw����)���Ic?��h��d��u��'n��8+-��oyޢ7���H��M<�V<3�I��Q��s�)�^tz��3[��[�Y탺�	��-*�"�D��\�/+�*z�ܤ���vo�l��ܨ�x��=������A��gc*�@�{xy߶�j��T#T$�DS�b�� �u8�����F�K��d����tݩ��8�*-��L4�^(�e���E�n�ml�|;r�?�x�� ����*	��_ΰ�㦊� �r�������\��(��^��)�V�'S6�2kߙm0F=Y{;��D��'�BA͊ԃ�*��o���
*��J�7%ߠ���#'S�˖�f�����v�	X*j�*���b�h��I�K���ױ�p��eu�r��Ld��<��!�ӆD����/�b$���5�.�`�����ƌ6�-\gq<Γ��C�q�|�kXJ���mc�	��qT��pB����m��z�hm��5�ع�r��5��i�"m�V>�Ϗ֮�7�W�l�<+������r���e�RV�ȫcN�$+�f�:�|��C].���ۗX{�m�#�V�)`�W�52�22[�;N|����ww�蜆�340a*�@qm�Sټ`G�<������Ք~	6n�v}�	��;�EG�1���~\`��n^�M(��:��K�`�dƁ3d}�Rl1rf��_ߕ�3�}[�[V?_-�óT�[�=���V���pfP������/��g�endstream
endobj
47 0 obj
5568
endobj
50 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 51 0 R
/Resources 53 0 R
/Annots 54 0 R
/MediaBox [0 0 595 842]
>>
endobj
53 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F7 7 0 R
>>
/XObject <<
>>
>>
endobj
54 0 obj
[ ]
endobj
51 0 obj
<<
/Length 52 0 R
/Filter /FlateDecode
>>
stream
x��][�#�r~�_�g�y� A {/����!�C0'���lds��S�ZͯX�aK�3��Վ��|�b����,^�����s���������=N��A���Ϯ������l��񏇯���>�J���p*���<���ӱ��#�ۇ�O��������������:}�>��C�Y��'ѯ{���U,�{�u�k}�o�a�'�C���5%�p�����cQ���WW��k?���pT���u������I�\7�����g��&�h�.�3&��Y7��R�6:��1e�7& �U&�b�.��r%[�:eMr޹���E+o}�)�n��]�w �X�m�1R��~�>�>���"E�1�Jk�K�	%"���� 8�gx�$����H=2��ա����B�z.�Z@G�tA�ͩ�\��Zѓ�cq���9�U���Le�p���յ�M"��Ǭ��VNʘlK��D@[�X+�>{�7�A"Xj�޵%~�ܩ�m�A��|Ν���Ҏ�ܩ��k�5�=_��K9i�h�s.�d��i�;wj8}�9zW]u�H��m��	�;��ޝNxu�@�R��SSh�L::�I"�ܝf�s��7�A"Zj�ޢ��D�ɹ����F�q"��f&e,���$(з�Db½?�W'�ؿ 'ZMj�`4�}@Y#�8p`3��й~�A�=�g�A"Zj��'B��T`(�Y�Ĕ��(	
�j�9єHV�ZΉ�$�ȵj��.X?�ꃭ���]@"�s�y����s|�%6K-�{;N�͛�;[�N�8p`�ڡBL��Ae��p�N�"�l�AN�����Y�ӄ
w�pƉ���D�2wj8w'�g�A"Zj���q���\9jވ�3N��zz�k�<G���$��9��k��<u��J%��'�D����Fl8�Ć��D���c���9>k��R���8Jg�ȤC���)�����T�KȜi��.R\r�mp4�vV�D�����`+Ca)�nM"�s�x+7}���G��R��ގk����N�8p`�ڡ}���̝��	�\p�NGA"9��&T�ӄsNl8�Hd(s��sw|�%���':K�+S��l�3N��Y�)E�m�(	�D8�s"%����HQ�DE댜����倲F�q"��f ��s�'�>{��ڣD�Ԣ�;N��'2��P��vK��'GI���D�h�(�9���9���h�FN�`��Z��20�v��������s|�%6K-�{;N��[[��N�8p`�ڡ�Wr��Sù;N��D#GAN����sZ�ӄ
w�pƉ���D�2wj8w'�g�Q"Xj���q"u7UL��F�q"��fD��s�hRUMg9'�j:����=:�ȑ4r��a�Le�dPֈ�3N�$"���8��s|�%����q"��8�I���I���-��j8'��D��9�S7���bg�����`+Ca)`���\?��M�}�Oڣ�f�e{oǉ�+$����(�'l�+[8b��Q�N���p��V{Y�\�B���;HC;w�qƉ���DD�;5����(,�h��81j�
2Y��ˌw{,3��)�bW�������b�h��g�(�d;G�U�%i�k�P���pƉ��ݑY"C���=���ciڳ=�f�E{�{,�t�ǂRq������iiB�Q�:�l����x�
�]�MP>P$�bg�����`+�����$":׏�rӇ�4�Qb�Բ�7�c��bpF�ӌ�=���n�v�R�bG�;5���I��b犦X|��iF;w�qƉ���H��P�N����=JK-�{CN�~�H�t��pΉG6+U�K�q�>�B?�S5Fq�5�Ĥ�hF�����*��e�8�D���@"C��qNl�pNl�#'����sb+�s"JE�j8��E��._�J�fP�sb�]��,��D��u猜v��1k�>�����l�&ѹ~�U�>���ȉ�R��ސ�+�\|�ݩ��lv���:��h�N3޹�7�'��\Q�VE׹ӌv�4�6�e�Ը����ȉ`�E{oǉ���!���G6��P�����n{����H�����\�ǔ�zb&6�洅�| e�8�D���@"C��1N}���GK-ڻ�D(�q"���pl��
�8��;^I�zb&ΉV�ҟ�!�
�k���.P?f-Ї�20����$":׏�j�g��Y{d�f�e{oǉ�+����pƉ�#�UV��Q<G�;�x�N���C>��Ċfkt��iF;w�qƉ���D�2wj\��	�Y{da�Ԣ����\׹�}7��q"��f��"1�'�H�p�M�<��Cy�I~ǉd$e�qb��VY6��7b�9'6ٯId�\?Ɖ�Ϟ��(,�h��tƉL*2T�Y�yE�u+9R��n��+C{ol;g�jɦ��X�.X?�ꃭ���`�5�x>q�o�Ϟ��(�Yj���qb�
����g�8�Ytu���yb�N���U�f��X�#h�@w�P�N�9���~M"C�;5����(,�h��8�T�H6�nQpƉ��i�B}�'��Fe�s��c1Zg���j�i��bgCԣh*g;q�P~r��Ǔ�M"GO�c���9>k����R���8Jg�Ȥ�	ꆳv��b=GIu)v{,�)M�	N��D��
��8���.x>������� ����$2�T?~������=�o�Z��v�X�BL�����i�'���KP�"�8�ܩ�C��xQ&u!'�L���iF;w�qƉ����&���N�,7w'�g��8Xj��S#�z��e�8�?�+;+��=�]��z��_�<��������3��Rǿ����4 }��֟�y�������| ���@8��v��'�3�!������ ���R�/�W���+�"�Z����Η!�7 ]PQ����(l(Z��H�;*cL3�Ǿ#���n􄰻Toؘ^�L�omG���k��q������Wvx��bE?�8��0ɐF���st�o蜟���r��M9k�!sH:No�Bp9�Z=$߾oJj=�b�ꊪ�^#�����~%8@�C���7���r�����)�����x2"�\>nn2�oauѷ%y"Qd�[�����J����K���2f2ѧ�����GO����N�5~��"������Gf�L	*�S*��L`�66��=iҘ�M��t�'^k1w��=�Co>��s��4�.�]�O@k��K���Y��&�j�d��'�G<EE��[�|g�|c�K{���z����k�C=���3Q+r�RwQm�������q�͆����w�v�Rb$w��O�1SL��Sh�bb�v	���zΫ~]Z���y^��+r��U)�-Q��La"���3�O�ha<F�!pfz�����̰O�W�攎���k�Ct�=�X�m��p����y'��c4T�S��畷��ʩ�~A�`�?�8Z�6T����fb��(��,%��V&�`js4��2P?@�B�!�h��������oɽ/ɬO�#Z초�2|B�1.�,E2�i�3�d�ϯ�(�	=t������Djq�q9&�և�Ŋ�����]��������c4f��Q�]�(���%}!zڇ�b�^h�"L{d��{g��Q$1�x��1��U�����D�-v���f�,l�<u3I��+�>D;���W�7X�ߤ�,4�xQ{�� ax�ޢjbIi|�c��_h�ؾb)�V<��o>��FI��?�r-]�dx�B.���7W�S��I�=`�#}�������~Ss�-�5L��r�F�5�b�pH�bt���D���E�|fϛZ��珉3���B�Q�1�(ó2��Y#�&�uH]]���5����p�x��t��PH1�҃B��.m�=JK-���:��D��)�Z�B*�7������ˮ"l=Ѯj/����+��~�A�cy�o~��	�&���7�c�5gf�8�淠�PN�C��߯8*G�q�5�W�g߶7��`]S~�3�R�kVJch�r���U�%�E��l�4��cF��u6����q�}��^ S�F5�uQ�@gvX����p6X�eʝ$2r߲������g;i�����}����\0X���(�����]d�gG��O�nZA�q^.�|Ϝ[���N�;���iąG���/�-���z����c2�*K��9��Y�'%Ϝ缽�Ȋ3�b(OV�_�����!����Ia�29�ۭ��k�����8�����=�&8���wM曢�5�G�N#�y��in�C�$:
�����~e���|�.K�$���w�匆��].�I{��Z��}>r��"^y������Loe���)b��V1�vg�����x����dq<^�g�bd�b�j��$1m���_b�җqŎҸP��ޢ)������D�B[Q��=���Ǌ���\���-Ǜ��p�����)<s|c���<C��x����g��og���8�CxO�x����R���8���@73�~7�X�}$�$}xml�6� �����P����y��0�(��U �je�N��&�l�p�hx��I"C��<�:�b��e;��(�Yj���E�㢑q��}���x˘����l����DA�b�H�2�Q�TE��m��C���/��%�HAb����>�HJZ��7��'*#
6��>�:��]P�S����}q�eة��E�2��x��iy����;�+�!�rHJҗ����G]�Bo��w����[����[C�'��n)��S�������ljW���v�7)�����Nf�}�s-w�{#�'�q�ክ#gz�]s�iH_҆c톛�+NB�˗�\�cF8ӛo���)���N�ؓ]q�y<ȏ��;���M����&�F�8n!&,c�nyi���	�o�����;�xθ��P�6�s�x�ל���5c�~;�昉�q�t/(B4�x�
�n�xI�f���d����x�-��������S+b����5a����a�#�˸�"��+�����_ѧ��|e���w{������rc3�[3�9������x=�]o\�=��CY����,�d��b|�m���Pw���/�<É���r1��5L��5L��e�^y__��Ѡ�{0s��0��T\���5�h��ŧ��N�h"�Q�;��~e'� g'� �,�M"C���\�M�˿i��R�����;���WR���~s8�ݯa���%��/��h�z��c���Xc<�y�3���M�0a�0�]�z�k%���/f�������_�e��z>���C͡�����[���X�u��oQ�k�_�}�"���S���C.����M��=O�ox��r�)�$܀�$܀C��X��ћb9�T*�^<x�V�bS�<	w�N����T�Ĥ�*�yc0	7�lp�2Ɔ�kԚD����8M��Ӵ��Ԣ��8�_{��M���n�O��x��t9��+�+�Й�{�-�w�]C��H����ȳ��	�x�9�^kȗ5����<PXux��~_C����86��r��M�vVR���ֆ�UV5Wܡ[�^q�!L��Y�g�FC��,���9��=�!n�U\��Ro�����Y��sB|�`�V+G��u����7P�C�pԩlRJ5�6����h���P6�����K0�Ĭ���j����V g� �C�:׏��>���M{\wh�Z��}�
�)t{�U�>����3��E+	W�J���8	"�O�1S�vά�آ����O�x����V)1�I�I6��~�L�Ety��w6�7���B;� ��b�q\��øzE���S��C�q��m+:L_�׺N�e�t�|������@��2SI7�(B�}=<��C�M��{���KW��CU��Z���_~����}�J�w1��BD)$��Z��OI�E��S=�c9���
���&'3�uV��b��F̈́� ��^Ù�U-j�ߛ�Wc�~�7Ǡ�K����ѫ`����P�e=�H�v�델q�����B��x6���9�@��h�L�8��w�>h_~�חn^u�.�?��"�pnp��Adź��E��o�����h�p���^��ާl;�<�c9�d|���;�ޔ�b�W�&gҥ��V�lS3� ά]T2!D��lhp3I�CD/$����1���1�Pbk�_C�Bؐg4�߇��i��3z��._	�h��?��'�ڵy���x��V�s��+.������,W,ѭ���8�1|��>W�R�����ɜt�	h��.��U�q^�B�+�2�=�g�zqE'Zqp�򭁩����O#�L'�︈����Oe��iC��)�V,�>>S���~���7���ڇ��s��M���6w+�K7I�&������1|h���/z~���9������R��tr'�-�N~������羡6���g"����6�Z[JP>9�-��8��8\�.%��S4��I���W���QE���M�a�Y��Mh����m@��l�ٖ=�O9z�۲}����h�E{�gW���_�f���W�_�O�'g�ɟj�����>�^L�>�_��2R�׵��áF�3Wl~�^��'���q$v:?�7�w�>�?[�endstream
endobj
52 0 obj
6594
endobj
55 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 56 0 R
/Resources 58 0 R
/Annots 59 0 R
/MediaBox [0 0 595 842]
>>
endobj
58 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F7 7 0 R
/F8 8 0 R
/F15 15 0 R
>>
/XObject <<
>>
>>
endobj
59 0 obj
[ ]
endobj
56 0 obj
<<
/Length 57 0 R
/Filter /FlateDecode
>>
stream
x��]ˮ9���+�.�,��`���� F�E���]S(ȅq�b~��R*3���`ҙ�)[6`�{ ��8����������~���K���_R'/���7��U<�|>|9~9|<|��~9\��|�_/~�~� ����������o������?��w�|:���	���UI�O�ڌ����ÿ�����)��Z%gܥ-��7��R��Ruhn��_u�����;*�pL*d�9���ï���m"����ϰz/r��y��G!�qYN��&B��@�t�N	%�R��i�BLZe4	ec�9B�6X-��� �3l��n����k�V���5�����ψ�.7�%���R*���F��{9@|��	�c�a�@R��~�#2�r�:(��D�R�]���Nҫ ġ\B\n�tչV�����H҅��W"xӥ�k��\`���`���P*����!:�ky��	�C�a������i���9%���ٟo�S&�	s��n�K�}�n��nț����G��fQlN#��	�F���GXc6B2�4�%���9�l�.D�lWRz�kD(2���4�c�a�@R��&Jl�D�MRi��8���L�F
.���<B�T��`�[k��*^F4ĝ�6� 'Z��:ϷP� EJ8�D�65"th�D�ĉ���F(�Iy�JG��jp���-r�s�
4Im.����T��k0'Zkr��6	r"�h���2`(X
��X#D��!-���J��=�HjZ��qb7�TV�Ҝq"����-T�:b�Ӏ��<��!BN�Рu���9haN�8���@�E�4��9|�=�JjR��qb�zq�Yb%q"����)"�� a�u��݊r_�AX��R���"�����eQ�l�P� EJ8�D�65"th�DПƇރ��&�]p"(q"�0��޼P�f���
�]���AcN���fsG '���!i�� -���@��5Bth��CNzj����z�ة7f��Dͩ�'�Y7���&j�"s� 3��r����" �ԣĜzq"�����i�s��{P#�Ԥ����d�ȋ>
g���,��</����h��]�FcNTRy�C�'f<��AN�h>�C%)���Ԉ�k�'���0>��%5)�A�Q��� ���'��,^�nw)/-1'��,�h��s��p�ZKȉ@.�}HZ�?Hˀ�`)HoC�����ڡ?'��5IM�{=N��]4�Ps�qĉ l�(���c�Ӏ��,�����3CҶ0�+Z��G�p�f�F�Bs� >��%5)�^����y���9�3
�V|V�X��\��O��{�O��%h}�����?�.������R������3����G����g$���̇ї�ҍR��r��'�����4e�AhM��5~$��zK
����,x��� �����Kk>|�C���P�C���Qtn�X��L��M��|E7�Uڛ�����U'���J�_��F ���rQ��b7
U�;�G�="���Ut�fy���t�]Ἄ?��g�3�W�N�l=�r0y�VIw�C���0���������c�eUV�M9E#�g"*"�
~;���Gl��6�_r;�u \hٔ���e���(� �GUe����h�Zf�7_�� �Sa��F�Y����Sf�Y[�OĬ��T��\�ڻ)���dQ�%f�}&�""�`�f�2�@x7=i�.F���z�PUv��^+�Y�n( +S"=���b�c)�~ǒrSi�e)5����]�%E�G�����
[�4�$���s���2��՘��&�Pjp����J?O��V7������Y�4��
%⑖e�~��0�J���M!��Ȑ�@���Y�肶�V� )���4��#ED�J�Ҧ�ΰ���hm�
��x��5�b�����*�����L������敽��������m��HK{ץgM�Zj��o |;L�,2hJ׏*��eU�!�3z�w;$�%<L��+&b�<OP���p-Q1_ϓ|w?����F�%��	����rC� ����6��f�� ����;���\լ��f�ʯ�+�B��u_Y������C¢�oK� ��{���HJe������ķe	��L�h)��xk���'H-t1��B�MȔ��>��HC�TU����oxU�jy�aB��s-�?�4�ӏ�j���W2t����Ye�>�
Bj�Mvpx?�H�'��0�����Qh��+X���iBEC<���N�TbX�'���*�X��kZ��ŝ&F����+D��x�hu{�󝖘F�џ�ѹ?z菛@CdĒq����>ˢ�;��Ol�����#Æ4����<���C1��;D � K
R�o�+;�PJ)�X|ԙ_���{y�r�G$�e��J
+ut&��U�`R���T��J	�Sƍ�Ǩ!���+/�m
@^0�p-�ܲ�:�1���[@�F��g�O��Gϓ�C���5"\0�. ����5��������?Pv��^7�M�]��\�f3�8����b�:�s+��EQ	P�Pю��s�_��P��J?W���D(oU;�$�O�!��%h�L� =U�M�[�e5�QR�N�ɋ��3��&9|�>��A�ϗx| 㵖Q���QRٓiHb���+b|��D�el�t�E��7*C~���w2��ѽg>7j�SC�7?�子N�o~n�gM�7����OcdGbS"���݃�8�ˎ�8�ͥCi~P�B��n�P>x���ֈ��)��a��6�^5My��;�<ϊ~%a��˩�?�S���0�M\�m�o�ݩ�4�������p9��}oྮ�\ݰw~}��7t'��G��d�W�Wa��/�Ű�߿���'�x�|'9��S
�;b��2m��N2������N�,���+�7ڕ���*[`H���s:9�
ġa9A G�0B����n2�k����=��ݬ.x�"�z-����T���P��_��ސ��ֽn�偈�@�ĸ��Ӳ��¦���z�ڊ�.[ϩpzg">|r���4�!x��s-�\�&i؇��m���>JE�/�F���}c�QH�N�K��<`D;���U����OJ,���>)!?�H���a7j�h:�}�[���v=/S"~g�4�Tۜ���֫��;�գ�.���{(B� |�����	�)	#���p��pX�w�/��绫�LLG�>�p}���>�]��C�l�L����F�z��Z��w���B)ۭ�?�s�h��O�I���v��~��<���i ��nC��sxNt�W*1�����;�6$d�_�G���+�~I-�}˂�!�����U�[+���Ė��邳���Ea~�>���h���|���E�����[B���˴a�?��$�H=^V/���Z���Q��1F�?�W���4J��^���;� ~B��"i-�*�9��]8�oT���:�R����.zYJ7��TP�H:@Gk0j��S�6�����7"��E�`���`�F�w�y����v��o�����Ƈ)���O����N�Y4�/?����[1��[l��Z��}�f���d�z�얊����1f��XKҝ�Fm�f<o�e��'�����5΍�9bU������xn���U?UԆ�$�"�@$��TRř#�t^��{�1
�'jg���Ѱ�`��Yr�g��	�CD���ZW��礥3�ѝ*�<֜2���pd�.G�+��%����q����oK�g�S+l��� I��=��gs��X�m�V9��X��Im�h�^�)�ե�i8q���Yq�3�uI��X�������6��[q�λ��������6&�����{J^^_�&�{�*��n��!$�A{�G�6���6�6.��Q�m��!n��݆M�N$�ˇ��k�l��l��g�۠FUE���eh�eVJ(����jͣ?|���FRq�JC�g�p	1�5n_�d�hat��*~�<�S�,xs)��}�+p�#.|��.�5�0N*��~0oF|n4���?C=��z˜����k\�S1A�^ES�c�+\��]F�X�1S}�l�Z����q�=@ ~?s�m��ݹ�ӈw���e�K@������i�ĆP��.%�lN&ý���}+� �k�{�~��r~�(�[��P�0��v�O�|��A�ⷊfެYҹ��3���p"u��y�����n+�mH%]!�HV���7�J-9fk��5,y��w=a������Z�:���I y��zK��
B
�M௓ GY�M�������,/��M/>��7��X���M36t��E��>3��E���gb���I���r׉w��ח/�A<�7웒{|��4{>R��.�]?��" B��xa���RN��$i�!xQ�E�������ì�.wV�|_��k���IaVa�����'O��.��X�6���^1]W,6g�Y���*r��QUA�D��u |�r�L�~&����$�Մr`jK�������^���L�d�S@TavL4%���_�4����'J�;\%i��^�E3�
�cw�"�!noŠZ��s�6���u�x�緛�X��L\A!˟��_�Mݿ7�,W$��i,�[6<g��o�p�U�N�����ϻ|`��2��7t�����*(��a�on=�Im1��ܮ��]���Ə���w��<�!�TNf�D��t�܅��7\aMذ^���G"��+dK��^.�iY�6̩�u��Yu�`��@�7�i�����������-S���~�I &�W)��NxHVxR:_��3�⧃6"����VD����>i�%�� r'|&����������|�?��ȕk���(��3���������} 5"thz������F �iy�����{_����@�'�M���?c9🯐òJ�r��Z�rerS��%G)��I�H�k3P.y��mE�e)=q�/`1�|���~J�4��g��v�G��z���Eߖ��L���y�r�ܺ���X3���:L�R[����Tw�`XF����O:.״4�^W��;��Ê� G��A����]�F����&��|u��͜FO]�q��&�YV$�os��&qs����J��O��~�#�!���I�-W�tH>��G�-e�U�k�D��2�����y{�m��e��;ݔ��F�nR�����ߒl�^|��(��*6pf֫���I�lo�Ů���rЀ
Qy(즏�v����5!Ud�6���n�G$X�+N=�T;����i���Z�5��.�y���J�6�N�v������-`��r�F�T�ٱ>�Y����bAXa��G��y=7F�y(��D���kU�b����S��l7�x� .���L|�]=Tt���,���>hU
e�CVk�h�!�W�����Ze��1�5�cn��n��X6&��ڕ��J�v����������t����r��*��IZ�qY��}���_8��ے�»��E� ��!�����:�&7��r��w�7)�U�/�p���i��B�8",� �HN����0jD�17�=&�tIU*���4J{��Z>��!���B\y�MC�?Zw��id�&=Zv�gL1��� X!
'1�P����R�L���n:3��2>�kf�����YP��h���F�����;���a9��L��wo�M:e���s�2���~=�&x��wO�j��=�h�P�!�Gx����7�O�r}�|�V@�蛚o�kx �|���9x�>��t/a�q�;)b�����pTΓ�'�Z�3_[���'_�v�׻x�\i���s�K�Z�D���/L�/	f�2���'$e��)i ~¸
y5��)Ip�|$�F['�� ]�����?X**%���C��
gST����Ο"Y�Ūќ��:�����K�!�晞���'�_I<�YW�8��fI���.��`�q��'.�^�۲ss7��j)����YtV���.�H�$�:YQh~�UVC�w��۫j�[��@-���;=:���Y@�[���I��L:>;��c�y�����FVQ{&{�F�]١���os�w���<{A�G��!IK��k����o�)�	��->#� �J����o���)endstream
endobj
57 0 obj
6193
endobj
60 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 61 0 R
/Resources 63 0 R
/Annots 64 0 R
/MediaBox [0 0 595 842]
>>
endobj
63 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F15 15 0 R
/F7 7 0 R
>>
/XObject <<
>>
>>
endobj
64 0 obj
[ ]
endobj
61 0 obj
<<
/Length 62 0 R
/Filter /FlateDecode
>>
stream
x��]M�9r�������o�X@�H|00>>�;65���o�*�*�2����*u�u?e�`�E�#�?�������~����잇�?���U���߮���r�d�����?v<���K��O/"�/����O?�?�_?�k���v������v��寿��~��T������j�O*d�\����>��O�����K=�JZ����c]��?�W�:�Z����������:��X�z��9���߿>�V�8�M�0�7�3/>(�M��ι�QvU��ec�`9�
�(��1����21e2����mP��'�s��'��"��`}�ढ%Jy�J��݄�i����g����g�\�SZ�c���=�����=�?����5uQ���"�:�:�^{�<V���R�J͢���V�NN�6-Z�\`���ˏI��� ��]�B���%2���5�b�iz9*c����s�=ׯ�e֞}��Z�Jd���������R�ҡz�����q8x5���@�5�W��1�j���`�mQ���鄋��pRŲs�C�TbZ��N
�i��p�e����]�!cM�Pb�6�鄋�t�ϭg%rM]�7t�jNL�q���o;��'2��Y�<P�-��WκpT��œ�w!��3e�.��91�ҟ�[Ҽ�t"�Nd8c3Vb����p"kϾ�O�g%rM]Է�D&��ĦT�Po�-(�+j�XJ-0���)�8"j91ST�9�1sNdza�k�����2c(.��+����=�V{jϾ�O�g%2M]���8�vo������4�'2��Y5(��m��	É��U��r�X�"��v8��v8���،�ؠ�p:�b81��zV"��E}_�K��R��T��D�7��p�f�еK�\8Z4�U��i9�hS�I�Qpb��
�&�9��N��JL���Ц�p"���[��~'��4��Z�Y�iꢾ'2�'6�2�bx����lڨ����o9����)��Xp�|0F�Ozi�Ǵմ��2c(.��S��R?�˧������ē�.��z�XM!D[#%1�NxÉ�l���Yb�3*�Û��q�L0�qN<�)�2��A�pz�Nd8c3Vb�����f8�9��z��LS�=t�/�1��s�L0�y��@�E�?V����O_K��ݷ�v�@s����O��l��ݷ��������ݷ�=���@= �+x�
��`π9 �{^A ʊ%	�, M����[1����΢��������>I%I5�:j��	�ˍD>5�W> ?a�(�kW!��\�B�
��7c����P9��� ��O�0�L��z��l��m�/T�e�ف��2H�f�Eaԍ��R��}?�yNR�d{VE_ނU��V"t�rS�1�d�W*�e��_c�B��A[��`��^A���c�+}%/��P� ���A��K�s���tU��-�ƴ\�Z.��ef=�ݩ_qAx�3i���.���sv�|��<�1-�_�`�N�m��$Y\�C�F-_��nfL�.���n�5|�ϵ��|�O�鼕.���9���R����X6�`'�Z>a͹s���L��nW������e��Ji�SCj;�D٫&�n5�n�ʗ���Q��z�؍��N���9Y�e���aF�e���Q�4��)+G>�
K����h�tm�nh�4j��Hkvg&Bf���#Ci�\q�O4����Ij;N�E��ȋ�yi�f��Q��bu�q䣬�t�̀X�%s;|g{���~�v���0y�N���,j#�T��R
<A^
������d8��I)�r�
����4�J��'�=ɂA
<aP����bʝ���{v#�����C<��o��,��{���`���<��x����⟡��K��l@Vf�����G�!��i1X�/�>�L��B��	뢱�@�8i�T�F�?������@�3�.�Mr��}���j�nAFxš����������ջk��_P_�S���l�:ȀR�o!����}�>f����l���bS+A윻Z�nY^ӱ��{�����.�!��E���p�*l����]�\N���]+fJ��d��V��Ο�g��gDf���&�I����v}w���������fZij�9�ӆ	�Z/�w�+�$;��Ȱ��g?_�tt8�/A����5�9R�K�T5G06�#�aT�	ub��	ø ��~*�D���%	0����>���ȹO��
F;}�ٟ٬v�AW���0������&.�ף{�}���	r���B<���x߽ι���r����bXM���~h��T'Z;ڜ(�|���sNB����ˊE�)$���Ч�5��?��O��0�}_�?��W*�Ӹ�L�^�+䡲/3'66��[���ch5�ۯp��0��ńJv}!�I�H��(:���%����i�nE@Cz$;��~����@>���F	5+�h/?,�4�&N5΢�`[f>ݹњ�+Vl���H����J��E�owowY$�/�ނA����nV���Y��}���-Ec�\���|�]�KW��5�)nٍ'F+�)y�[�QvF�i��q�&.��Y��=t��F٤�2�-Z*L�yj��i�W�\/���5����M#��ӅJ�����+r�xS_m/�jS�����6F�����Y
[��g�𧊑�n�ܞW�+�1z_E���,�����P"1H�p.�����(�d1�bL�V�ė�Դj"7��A�Ȧ*�^1�$�]�ӛ�_��@r&4���1i5�qV1)G�Q�����U��z�t�|c8��QF4�^���~P�6)��ٔ8,yL�
�Y?H���^��m( FV4�#��@�M92{e��S�ҥѪ�b�ӯ3��ץ8�����F�F9����.~p�692�|�����lF�)eh���PX����[?� ��K7&��[�J��h���	s�+R�3^������)O	���F+�����a"����2���ù����qvH�M��(�ͽq��%� �c�F� C���A��y�5p��^j���ҙ��"]��D3\w�렧@(��es9�?�����-�wʅ�q|��6+�bb�n�r6�Տ�~x�~8��Y��e&\O��o�C��Sw�!����w�N�OI9˟Q���7���aT<�p�c8��Q�iL��Qa������f������є��}&�����i��p7 �9 ҉���sXg�P��(v}���>�I>���~2�@���YE�΂��p.g���:k��`�����*�����,���(�Ct���*P��H�7xre4jw��'�3�s9[�b��Rq��Aś�bgS1�ȨWtV��8�����.Ϻ�/��^1Bt���)�B9���=ǃ���Hy�9[%<�髢��m��b�Ox����M���tE�Ҍ�6�W|��ߜF�6*�sM�T�x���xU/�#q��r�J�!�ܧ��A�ۤ�<�U�~܈�t��������T�ȵGKX�N򩺧Z����:�*[��иk�،��>�-��8!S8dh�qޘ�3|��V+)g��1�s9[�n�׫���<�����fAf/���D�+��ꇻۜ�������w���2Y
�F��}�;�b�&�d�Q��٨�!�=e���u3vA�����|����������8K4r��TG�hY����uQ��v�ɜS�k�-��^oXK�;���\�V������k����~A�}	h�x�]><�}M�)�L�5����`-r|��1(�|�nv�N�p.g�n&ꃛ������ %��O�03�±�ύ�^p�0B��k��wV�y���I~.�_9'\؟e놜���w�*&��!-�����=��}�g�l�!���Q���*�z�JŏT��wz �b��0y����u��z�@�[0�)w8E��=ǣ�g���O�9ek��a�$?�����F/H"ƈ�8�������.�..�:)�]	�*���G	��op2*�I�N��\�V����3�λQ.���H_ݫ�f$�v7�f|K��Q1����h�*���@�5��y��7��Ǘ�geFq.g�DkC]b.S��n�h��d]$Z `�py��W_�Wmy�TĚ�b�Wd�ц����HD��(��^�@%TW6�h��H�B�����2�(;�7�Ϊ�s�A�)���������|�^����:��s������A�#GZ�|!qK^!��h����(���z��ihf�n�u��3�qY��=]�G_͑�Iu�7��G��s�3��+.����D@ _e��~F=H#��J��|�5C��\�4
*l`U�sA,(x�j^��B��%_������KF�LX�Ν����Q��5>�.�~�ϻcޛi��U���Z�耵��'�=�p̖L����������	�8�s׼�!c�h?�ѵ{���G�ĵSc��L����J!��"U2,��y>c	H�à_��K]Naи[up���I����Y���`��!�f�.�?�����*�zx?��'�qܧ�n1؟��0��>�{�G��N���m8z�>n��X
�9"<U���)�v,�;Ҧ�E��Z��b0b��q��;.�݊`s߆(�Z�r��B�=��yƓ�U߽,��3�D]�|�Q�,�m��a�J���y�t�ѻn��W�'�T�΅��r������I�M&�<�Q��y'�F+�)y�[�EWt�=�l�s5q9�J�X��'�7ʎ���W�Fo��킨���Hv�WQ�㎗x���v>?��6��g�e@H������x* �r�x{�L^iG��7g��T���7x.2]��cm�8��NHs�Q�R��F�G|�жF;.�a�Ԧ|����u���XW�;�F���+���|���5�V��!��_��/b|�9sg]�҅|����Ԛd��1|��ƪ�u�YŹ��27�X���uo��C#����ۀ�S&s�*7H���+�׿��^.eD����ׇt�+N��v`�W02��iBh(�?_��P����/��+`��*4���<����J?à���/�8�z�(?�_����6��X���'
_w4�ʔ��������ޥ$2pGq.��z|J�c}�;��#�WE��h��h;(O>j�X�g�t]�l� ���*<����X����;��m�xG����ذ�X5�Q�՝ξ���T�ܳ���fog/�M�|e�4^Ӂ���q*;�ٗ�h	�_��1�`����U<bu�F����#������c��!�	!/YL�@)�,���\	L�����]�8��F�5ޟ��d�]�j{wg��|���\i˾D^�EG��u�R�xҔwv�>oJ��#��Q�Rtɗг�KB�T��[�j�����J,�����s�������� �٤��آ/�k������zV"��e}���ULz�a�������տ�a�{wGh����g.�@b�Q�ۤ	��[X~�r�Q��gQ��/&݇?��=v�<�?�Λendstream
endobj
62 0 obj
5575
endobj
65 0 obj
<<
/Type /Page
/Parent 3 0 R
/Contents 66 0 R
/Resources 68 0 R
/Annots 69 0 R
/MediaBox [0 0 595 842]
>>
endobj
68 0 obj
<<
/ColorSpace <<
/PCSp 5 0 R
/CSp /DeviceRGB
/CSpg /DeviceGray
>>
/ExtGState <<
/GSa 4 0 R
>>
/Pattern <<
>>
/Font <<
/F8 8 0 R
/F7 7 0 R
/F15 15 0 R
>>
/XObject <<
>>
>>
endobj
69 0 obj
[ ]
endobj
66 0 obj
<<
/Length 67 0 R
/Filter /FlateDecode
>>
stream
x��]M�c7rݿ_�� �����v�,n �A��8�@3�3���%��9�+QR�ՙ���;�X�"�X���?���������������_^̒�9�ٵ�� �®ز{���o��^~~�Y���˧&�_���__�=6�rD~��/�������?���o�ϟN_o��Kve��O�_���5�,��7��������U�a�b��5�x�����)�%�P�ww��k�7�A�	1�]�vW������*֮-%������%�cr�`��sq�̔�]�	ֶ����E�h�����@��eR,��^_ �qq�$/��	OK)v (�%9뚺�@_�Ӏ�_�t+VSBB<,�XSs�(�޿��A�=�=H�-_e��eGh�Y��D��2��&�l*�`�X�]��(t�G0{���5�S۟�D���VN�
�?��Cc��[��	�Q����ј�>{�A{��ڶw�_� RSINFМ�����c����hS�,If_�o�9�s����6�|At�����LȮ����8+�2��t�������f�%!D���%"������8h�T�6W#y7�� ��5�	8��H����ר
Ѽ8��50�X��d�A��S-�!�d��f��u��p�A����DD{��A���=JKm�{ Fh����MN㖗**��OhYJ0�{&Feuމ��/KtY�@b�`��Z��2��v�����Q���_�G��R��~1���|�Q�ӊ-����t�0J��qv����.G�ZB�np��iŉG>�ew�8���(,�i��q�k��,^ʃ8q"��9��*S0s�әl�!|#\Ƴ�P)4tI���!/�p�D�1��	]�ǡa�g���=JKm�{{�,�T;N�V�,�;!ZEj	52':a� �YÜ�d��i�$�����B}p�1t�V�. ѵ<�]�=��(�[j�ޏ��6d�!��iŉǘP� e�ܩ��N�Y�B�b��)������N+N�8�~] ;u��	�U{��ڴ��8�Q�����p�D��ͼqK���¨G��y�Do��b�Ĝ(&Yd�)�"'z+~Q�ϴ%�p�D���@"�k��A�=��(,�i��u�D�
8�[�]�hbT��xqh�Do�XE�<3'zų��9��Ck�>8��P�
�[����?�o���(�[j�ޏ��6��-at�'N���X	~Jf�ܩ��N��lbtȉm�K�f��N+:�ӊ'lܩ��N��ڣD�Ԧ�ȉmwR���#bǙ;�l&�y�.�Uж@Ԓ�81ˏƙ��/��*q�!�$3�� v���̉G6�	]�ǜ��aN�ڣD�Ԧ�GN�3'�Td���]ڦ�F_�)۲^��f��l�*-%=pb�*1K����Ck�>8��P�
�[����?�sb�%vKm������Z|T��̉G6k�M+Q03%�S�ٝ�%Vg�e�����R����V�9���f] ;u�ݩ�]{��ڴ��81XQ��h�C��6��Km�g4��6�Da���2'W��$	91x�[��@9�q�D���@"�k��A�=��(,�i��u�D�
8�[Z�79YF�H�-��6�Z��-^BAN�`��Z��20�v�����Q���_�G��R��~'���|�iŉ6�N-���9Fɝ:��xms���.Qж��NeCw�8p`3�H(�S�ٝ _�G�`�M{?��(犄�� v�9���f�� y_,�����P�"�R�C>1���Xj�|�읖�}ȔO���̉G6�	]�ǜ��aN�ڣD�Ԧ�GN�3'�Td���]�2/&v��!�(����e�'�"�'�|"����B}p�����.ѵ<�]�Į=J�ڶ�9��N&��NgN�8���.�T�)ٝ:����F�R�|bC��nXJ;:�ӊ3'v٬K$�ܩ��N��ڣD�Ԧ�ǉщrA��C>p�D���D/ٳ�
��8!�:�c0���|bv	9xO���/B)|�PD��6����#N}���ڣD�Ԧ�N�։I*0�4nE]v�Q�1Ț0��/b��ÐO�������O�`��Z��20�v�����Q���_�G��R��~'��C1���ĉ��E	�]�&fFɝ:���]$�2���-G;�ӊ��ĉ���DBɝ:����=JKm����XD9�;�!8sbǑ�d=/^>��B>��|�|]p�O���"&J�򉱊_��,��A�8sbǑͺDB��1'v}���(,�i�{�̉(��4n2���n`T�8�l�|b���H���9�J�,!m�|"����B}p�����.ѵ<�]�Į=J�ڶ�9��2לr�gN�8���.�le�dw�8��y1QW�'64��+��vtp�gN�8�Y�H(�S�ٝ _�G�`�M{?�S�]H�>�D��6KQt�E=F�E��2'�$U$8s̉I����pZ?Il�q��G�("�ĉ���DB��'�>{�W�Q"Xj��'B�ĉ$
p7�Y��ǨL�b�qkx�e���=sbJ�V�LEN�`��Z��20�v�����Q���_�G��R��~'��s�E�ӊ'l&�^��͈�;u��	�6r�(�Klɛ�sdw�(��ĉ���DBɝ:����=JKm��4�?���͍$�%�k�K2&ȲӲ3���y��A|O�S�4�6�t}���|��K���ow;�52c�Pte�9Y�Mc�Am��L��}�=�����-K$�E�;�Z�5����z�X
=j�rh�&�C����z��1<w��D��y���u�������G�����n��|�����~��ם=>:y�磐H���*w���c�O�����6�G���#P@X�@��TJJ�Iqf����{{׿��o��(Vy��n�Ǳ�?~�����rx�Q��K�2��{���s�7{�6#Ý����]|n�˷Z|n��7�P��.d�郬�Ӄ�����!}VN&�)��fȑ���?���������=�$a��-�mO�}:w���v/.��}�v��P�7�p��r;�%��v�:W��';Z/�W�%�q��_B��gOhk�My�1���K�pc$��@� }%�h �h��:�=-=b�s$��T-=#���n�?�fW܀��?�k��+�}�Ѓ��ι-kǃ�K�dʣm���u
9Z&��'|�,����w, �v�8H��F	�����q؜yt_6�8�}
5�a�AQ�Qqak*~E{�pv*�F
%��V��J~ ��*L�il���8�m������i�?�2й���C��+ʦc���-f`�>*w�|=���ᆗp$��=��i���V1
��6��\+K�F���TAq�R=>K�%��6�YO�_G_I��s��0_%
4(�4��'�Qb�Զ�?�p�+b�!J���.L1?N����p_���O�F�Ok��a�@�is��W�+㪡H�M��p�ݣ�4�q
�˅6�da�c��|�h�{i.���X��t��Gǘ���M���0����5}�O5J���{���]��B�=�����w��*0��w;�\1EԬmvE��٬e5ﴙՌ�#�w�L�%��7����g��V�����Z�)[�����%�)���F支Vʩ+λ��2Fw͡��c?Բ��E�bި�%�mZ��7��b}5�U�~!�`���?��ϱ��#�qiV+G��UT�*�
�n4��;��>2��ʯ�$q}{nص:E�6� |/xneXZML�]+(k��:��PL�
u�:���%�'�Pb�ޒm�%���(e� ���x��K$�RA�C8�<i�������Y:f�J�g#�� ����#���q�����f�nf(@m��8N��t�j~g�D��Ϩ�(�eCՑ3����)Q;]��-��H�^a�wBZ�hďK{I�']8����}Vܓ���"�kܛj���|���g[�mM����/�C�{S�cj��#w��Ū	3��*ۮS$�)uGf������t���A�������ӎhu!�P��
R��i�������ڄ��%����!<�V���S�Ns��Q�̊8Vf%<�+V�=���UIշ�"��(p��:��DB�2+UU�ʬC�Փ�(�[j���Q�1J��|����f��<��=i>uH�א ���<�>�4*�}��ы^7��<�
��sw�/��or�xG�Z�,ӓ�+��|���U��%�V����lF�=�W��K�ykd7���P3�goJd��"��m	�K:��l�ت��Veo���(/,煥�Tw�H(���ҴP�v(Y{�%��������t<�ww<�S��Ֆ]m�u#��4���K��S|"�)��h^6��������p�����Z6Զg~^�����#��V<�������.���_r+�����,$z��h�Y}+���*ca��RZ���C��	�S�������8-=�S��U"�PE�* C�2�I{��-�m������x�6㫜�Z���]ZF�zOPѻ/8�zRƷ����Q�O�TW�?��8{�[��˂�a<��Rk��7V�fg�Ǚ{:Do�U+�N�<�9��4�<��?mՄ�����]h�P��c��o�dm���C�M�ñ�t0�8�(��F�j�Ktq�KX���e�a�:�AB�9H�8�^%
e��$6��Je��G��R��~�AB{��9�|?�l�ߏǧ��>�����<N���ӟ�G[���ϵ�~^�E=��,ZMnB�Ñ*�t�
8�����]�%3
�����ץdߞ�D�AԐ��Б*�Y N��X�K$��Say(N?�?i������Y#�ޏTo^5\�G��7��os���Y��<���g-M_4��i4>���nak��^��O�L��v��|����G�=7���z��9s��+*�_��gnO����\����E�Z��[1�v9#8��&��{�Ò$;�<a�C{)�M��|��Z
�
A�Bx\�����u�5�>��nп�r��qQ;NoY%
�
��|��B����G��R��~QO!j����4g֐�f��[ү����p��,Ou9�]���R�S�;���{����P�FT�[O�)`~�i^�P�:u�XMՆJ���<Nw-F9����]�7�B�ۋ<��.^�i�e�ɞ?��ݗ��u�4�-!�<|׍N�Q���+6M��\j��b��ﯬRJ�T�ϯdϷcW�z�OTͷ��C������'���|#}{�=Y����e��ą^����t�Z�Ϝ�=)�׫���f�W��������m��w$����"�5i>�\��5�߷*�9��*�Po���-��Qz_`��}��祚*�ݡ�T�Z|l����u��"�S^pz��*�Px_ ���8��=J�ڶ�{^��usX�anO��_�w��|���]���a�
��ԲS)�ѱЕ��Qk�Q����n������(8����)�=������������ �"��endstream
endobj
67 0 obj
5562
endobj
70 0 obj
<< /Type /FontDescriptor
/FontName /QSCAAA+NimbusSanL-BoldItal
/Flags 4 
/FontBBox [-177 -309 1199 953 ]
/ItalicAngle 0 
/Ascent 953 
/Descent -309 
/CapHeight 953 
/StemV 69 
/FontFile2 71 0 R
>> endobj
71 0 obj
<<
/Length1 1868 
/Length 74 0 R
/Filter /FlateDecode
>>
stream
x�}T}LSW?���U���Bյ�~�G����U,Ce�DatR
���K�*_aH%�-Y����l����s��l�b�ů%�%K��s.ٲ쟹����{�Ę�{{����{���߻����[Wtp��E�=�`�#�p��v)�7���&ǂYn@����;ֿ�R!m%\L�8��q}���[��B{���N��C�H�N�b¯�E�yz�t)����ce5�B�T���.'5���L�TqM��r�J6���=zNu����J�z��Ѷ8�Y_:���c�����)_�Xo�بm����7{�?0����Z���d�ى��G����'���u�J�@c�H���T"��C ������g'��߾D,ko�v��by �kj�Rl㟿1k�� �_����JďJ�ѝ��q��}f=P�}s7�O)��)��A9�Wȉ��+C��i�2�ҏ�Ѥ�=�G��b&�ݓخ�7xu��o:��w{,����_�F��O�W�Baص�٨de2��S�u��5�1��18��>�)�N�3u`��#�YF�%[���B,��U�"��9 ��Ht��4'�Cԫ���0�j������qS�����>Q��\��m�{�I��2�Uشǘ{�
o�z�����"�)�A1�I#�S����y��(tr�D�Ti���r���mh��T�_�U�㾃�J��l�6]��*_ʢ����}����ؗ�nCMMm���U]�SK�	s{߭k�����K���T��>_-_?�R��$�Á�;o���ޱ�ta���8$h%��§j��W�/���Ȇ�y�,�1_�?%����$��qk��D��ӱ��� c��a�Q	}�t~%:a0��w����S�Ar�유� �yZ�O����Ǖ�"+�ى�]��lAN�3��VU����`�����˨�|�����D��q�ȁK�LHF����nH����(��I�P\�BiW:].�3ҷ���U��#�#�.�]�`5�i�f��	����K[�Wnk�,�W��K�L+E����J5�+|�_�B;Z�Y�d ��Z<z?���@���l�WNu#p�.�#���`a?͗H�H��,��ػp����	z��s���7��p��u�'�� |�9؏g�2�̨�5K�o�}�I�G�!�������jBi���X��Y�?��90bTC�0�����A/�4�B#4gP)X����Rp�]4����D�O�'d�xR4�b�Yq�ZI3ՙ<Q�=�I�.�iU7��B��#4e�F�(yz�^'���I��z�W�<'-��e#kU�r�f��xb�-1.Z���1��!���u�Ϥ��(��XD�k-UG,���w�endstream
endobj
74 0 obj
1353
endobj
72 0 obj
<< /Type /Font
/Subtype /CIDFontType2
/BaseFont /NimbusSanL-BoldItal
/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >>
/FontDescriptor 70 0 R
/CIDToGIDMap /Identity
/W [0 [496 606 606 552 606 552 606 276 330 330 276 ]
]
>>
endobj
73 0 obj
<< /Length 434 >>
stream
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def
/CMapName /Adobe-Identity-UCS def
/CMapType 2 def
1 begincodespacerange
<0000> <FFFF>
endcodespacerange
2 beginbfrange
<0000> <0000> <0000>
<0001> <000A> [<006F> <0070> <0065> <006E> <0073> <0068> <0069> <0066> <0074> <002E> ]
endbfrange
endcmap
CMapName currentdict /CMap defineresource pop
end
end
endstream
endobj
14 0 obj
<< /Type /Font
/Subtype /Type0
/BaseFont /NimbusSanL-BoldItal
/Encoding /Identity-H
/DescendantFonts [72 0 R]
/ToUnicode 73 0 R>>
endobj
75 0 obj
<< /Type /FontDescriptor
/FontName /QXCAAA+NimbusSanL-ReguItal
/Flags 4 
/FontBBox [-178 -284 1139 979 ]
/ItalicAngle 0 
/Ascent 979 
/Descent -284 
/CapHeight 979 
/StemV 50 
/FontFile2 76 0 R
>> endobj
76 0 obj
<<
/Length1 4148 
/Length 79 0 R
/Filter /FlateDecode
>>
stream
x�}W	Pg�__ʥ�r�43��0#�9EQ.�D�F�K.�h4lb�dMbƬQ4^I��d��A\��rS�5�MUN�b�4��gPk���{����{�?!2�H(b���U��|(Gv�v������>CE�{4�Ykq`��\;�H�6��ؽ�����54W����%!K�Ni,߱��R���l*o��;bH� ��/��bN0�DMBq��d>�%J��h��c��z�R��dz}L4�Y���������l[���vy� �Z�~K/@T���ͽZ^{�Ɇ�V����¡���]ã��G�U�S���/��`���PapmJ�!d2gQoF��"W*mf�(�V�Of�YI$8�+<�=��>�N��0oڛ�2��d^�;��� ty�d�n0E�
�TBU!�V��F�֖�]!� ���G(,�}L�L�ʙB���K(Q0A�m^�{�
�2�"��#@z��!�4��s���������U:]B�Ҥ1��%�U.�/;YӳXN'_]ў��GM×�Ʞ�]�6����e���럋�1Y���o����C�O���G����OE�I��-r� K8�H�D;гA�={��XW��J���μ�Ҵ{��,o�4=Ee�:ljc�[�z6����q��T^� �$;�䟌���APp�-*DA5o�ע��x<�ƪ7��ZD�d���sqWF�ń�$�Oj�3Z= T~*����V�0y����*����C�?_���(��7ȭ��A 	˗�f�c#�����#`Y��&(kݒ >R�;h�zt��&�!4' �W���x�z/��C}�1�8'b`H��C�O"f��Y��:sQ�F��UGu�w~s�)���S�d6�����ؐN����i��h�t<m^f�Tg�n�'�v{��m勄���/�J\�`��J�B)����B=8��V����^Xj���O�eL��$ЇYv�]�)�_yN�ݢ~`����S��"�qE��l���a/d�Û���Q�#'��BϠإu���%Hό_dL`>�]�n=p�����*�~�8��	r5$:�w"�ܖ4:����x�����-:c�={���t
?���΍��W/��S4�R�_���)�O�������-�w��І��v��S5�2A����=C[�<�6U*D��0�����}ODǌ�|'|�|bQ���HI}C���k�
��=��Xj���e�����R�O� �8�X�Ǖ[�wx�-{s�c�&{�g$ʧ<'(e.G��Bà�R��C��^3�%h,�`�޿�x��<�T����}���E�%`�q�ӫn����1�����_���ڳ��`p���W^^��{V���jR_���(!�-���08\�81���^�k�$�K�o��{����
kf	�<ov[QT�*�ϕ=j?	,M��ڒ�����U1
����dlͺp��$�!�~����5� yn��/�M�fd���ϯ/��CE�2p�e-�@�x	5���.@LgHZ��f��֞W���G4�&0��Y�d�҉�����H�2��Y��C\v�Ͽ��*Cg�eKEa�%o��V�/3�7�;�Wu^j����/���Ӫ��~<ʦ	Uh��:���G��>^z������b����b-�).�WmE��@Y��&�������Gn�(x�Zb�KZ8���b���l�S0�]�~E�*"�<R���Uz����bsC7��o�w�[�M@Q7�����9�h��:Ӯ�ciC��' ??���o/vk���\ �,�{�yj���L�|�$%�9ci�֩�k��H�~���/f�r���?,�V��+�B�,+�Kua)&0o��);��%�`o��6;�;�_��Q�.��xGPWl��C�+bz6D�u�1r�I�4n�U�j�϶&2zੱ���*+��>>k�ܽ|�n;���d���X�������DW������Ws*E=��P��	3B���6)
ֵG�r��GL������ұ�H�T"��VO6-��aPI˦}Y�����|�ڎ���8-&l��'<öe�zmPN�C���`CT`����z	��۪��)6������X��y�X�J��U]��W�˾q:$Z�	�E��{�C}�W�R�2����AP(d���~�.��@c���m4�J_i���[���������Z0�Tx�����:�3�3�P]��Y����dC���ƒ�ܤ	����U+^����W�z *,�8{g�zE����ɒ#[l�����9jx黎�F
.e�Ոl�t�1���h�l=�&R�� ��{g��������3g�c��_+V3�����rs~�:����{��� �
;��!t���v`�:�X�Ő�9/a%s	�T�������ހ)܆�C	���C����0_�^��W��$�g,-��+�'OiBծ ���4���E]~�Ju�r����L����^}�i�9N�MOẹo�>�����h��/[h
G��ȇG>���Bq^⃫�pw'��o�,�nBե�Oy�08{�.<#�x�ƘZA���L�Uż/�$��X-���ۼ|"k�̴Q�W�fէB��J�0��μE'�mz�.��n�("(I����*!JG�an�}��{�W0yw�sd���SoC���������S&e|����4��l��~�y��i*Z0��.$H���@�&�&l�/�^-������j����7)1w>���-�#�oBwK����a�ô���y`�cƱ^�&�*�\�6��Jr�$Υa�ɝ&�L��~3�9��I���6����ߨعo�g�����>�;�'aDL�I'#�kP@/��p�
�LTUJ�S�ӫ�r�MF����ul7�$;��`?cp�D|7J�i�f�ة�<,IB_ ���I�} �H9���}��}��a=�h&�Hi%ud�%�X�7#���OrI��2Ό0�_כH���
���I
�&m��&��Α��$΍�kB��q&�yN�u�G�`�W�"�@RN���6r�5�H=�Ӥ�u�zr���\�e�F|M$�ً!�pO#����C�MR/��F	:�k9����=>��D��3P;��_s4�endstream
endobj
79 0 obj
3115
endobj
77 0 obj
<< /Type /Font
/Subtype /CIDFontType2
/BaseFont /NimbusSanL-ReguItal
/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >>
/FontDescriptor 75 0 R
/CIDToGIDMap /Identity
/W [0 [496 552 552 552 552 496 552 220 276 276 276 330 330 552 552 826 552 552 496 552 552 552 552 220 496 496 276 496 552 716 496 276 662 ]
]
>>
endobj
78 0 obj
<< /Length 588 >>
stream
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def
/CMapName /Adobe-Identity-UCS def
/CMapType 2 def
1 begincodespacerange
<0000> <FFFF>
endcodespacerange
2 beginbfrange
<0000> <0000> <0000>
<0001> <0020> [<006F> <0070> <0065> <006E> <0073> <0068> <0069> <0066> <0074> <002E> <0072> <002D> <0032> <0030> <006D> <0031> <0062> <0063> <0067> <0061> <0064> <0075> <006C> <0079> <0076> <002F> <0078> <005F> <0077> <006B> <0020> <0041> ]
endbfrange
endcmap
CMapName currentdict /CMap defineresource pop
end
end
endstream
endobj
15 0 obj
<< /Type /Font
/Subtype /Type0
/BaseFont /NimbusSanL-ReguItal
/Encoding /Identity-H
/DescendantFonts [77 0 R]
/ToUnicode 78 0 R>>
endobj
80 0 obj
<< /Type /FontDescriptor
/FontName /QCDAAA+NimbusSanL-Bold
/Flags 4 
/FontBBox [-173 -307 1097 979 ]
/ItalicAngle 0 
/Ascent 979 
/Descent -307 
/CapHeight 979 
/StemV 69 
/FontFile2 81 0 R
>> endobj
81 0 obj
<<
/Length1 6936 
/Length 84 0 R
/Filter /FlateDecode
>>
stream
x�}X	\T׹?߽wfX�XfF�q`D�a�Fd�]�}�Me !H�]b���`Tb]����fqI����j��<�g߳Ijm�k|��.����\ڼ73g�=��sη�����K�"!Q�!A�5������H!���m���ّ�&D^�c�:�gl��žW�饗U�e�b�*!@��*.i.��d����fK�	q�žgc�iÊ�!*��zp���u����W��*/�X,f�Ύ2�6X��b�d�J�2��^�L.���6���|�ɩ1��ҒL~�7'*l��%��.z�B��=%}���6콲ሖ �-��{���olJ���m{߄���:;�#�z��;A$���vr�ĉ�΀���βyIP�DF���T(����tWRҮ}=��; y�����q� ��rcXy��W\9W��~98��Hz��/�����BH�@fzipp�@FZYڣ��%p$��A��ʤxDӬKt����>��k���pY3g�C�m�s����PP4F�>�S'�&r�(q�R�u`�ez�N,V�јZ��(��Ν��g����{/g�ra��O}l.�g �|ʱ v�$�m㏶ѢdJ�
W��u!�.����L�W��VF�%�4 K�V_ޟ�����؁+��_-w��mN�(_.ud�e��NR�v��g������^�ž4M�+�k5�n�ςf�G�uCy|Q���JiD.�H$�IQ� �B�i�(\��[@�!X��1���6m:�%��c�r���t~��*4�U�Ԇ(���8��?����d�G�C:�V�K<˥2����!F�:-X������9������p�"*s�菈oWH�I��r1Q�͡LhH�B�߁,���)Ӧ\\��O ¯�ꗃ���?\6�`3����V�6��A]�a`�XV����C�0�m��Ù�c}�-$���+;����]ݑL���K沈�(XV�-������;0�e�N��3g���_��-��b4:P��������mP�2+�@������
C8}\4IXd
����A�!���{�"V�4楡)�������?�1~���PP���6͊i�9�.�}B�Gm��N��}`����f�hr��GB7��B�@�˓UPWh�4��$�/w�ST�2���Tz��3�Q�<��G��3���?	�d��a��� M�꺋#�P
�$���eBJa����y��s�Ssz�����M��l�l�$��g���	������W�##�9��������%�L����d++�(������!���ƻ"�i�U�����!�^ ^�!M
ET����4(82��<���ҳG�hK{SR{J40ܟ�����9�V�Q�g�l=��0�Xn�S�dv� Y@��D��Âd6��s'%�DT'xԔ%f��s�d�h���ڠ̍����
�c�xv�.z��LzNZ8��,�f��!�Tt+��\R)eE2a��;�IW��,�3��[�1���rXf�a ��_�xv��F/���\���5���� Nd�Rk �Q�D/��AEC;6�`i������j3�}�;�($�n	?����7}3��!ű*�#�%���p�""�˚�(��c��m�;�	��#�d�{DGEU��� �������SR���
�S0���E9]N]�:�Hl�g*�A���_0��ڋ�����¹,sJu�r��\��?�y���0!����9߁[!�O���[�eN�S�;L�s�:'�����f6���-�9�_A+���a�6���������w0 UQ�h��M��_b�����nޅ9�p�g&��t���({(�)����_���
�\�Ɵ���C����.����v>��u!�VdχY��@R��E���T6��ZW8z����Wj�G�����^���/����e}�G&�� �O�[7��U�o��FЖ����k4�}�)}%Z��w
YX�ƫ���ז����t�fQ[ia<<�2��4���c��/~��0�s( ÈZ���/�\�<�U�����m�L*ڈk{�`�s�L�,;K�ԥ�Q���JI�堠��\�P5LAye)g�����٫"BW��j}������֨x7=���KR��W����K\fp�d���ssX��ƚi?6�;Ȃj����!�KPFeEW/���w8���G��z�'.¸z�*����>?���
BG!�e�C��_t�Nfd&,��l��8��8HSܛ��[*0bֱK0�ӎP��%z�Dbe����Z��Jh�tO�K{26xw�:���[�l���ߑ�`x���h6�����M�X��x�-��f_xV>@Ė���W�c��nՅ�u=�g�;/���8��H��[�ނr�a�󷰰P5Q1Y����9;z���6��tm��~
�^�>Փj�?r+�l�
�K�#��\��c�a ���r_jX�X��R����k�� ��WĪ��f������aZop�#�Y�7L<x����v�d��������cB�p����4
ާ,~�$��Q�� R�}�|���}D'��$2K](u�TR	P@E��-�b"á6�f��Ob;A����k�u�sX ��-�,+o��e"�E�K�D7��(����w��Jˎ���ܺƇ����iz%)rKm�4f-4N�ܺ1ciL<E���VD�b�+�R �A>�y΋u�>�$��/�eh���&�QMg(�O8E�ԁ��3��P�=��N���0�G>�KC�sE�)�I���*��K&(���<A���Ų��\�9>��J�#\�j��=�ψ}צ �l�D"<,^b���[+@��]�^�r�#?�k�Ux�3�7����$�92C�{#%̚�����@b�PkQIu����o��xº�߼6�UNr��� �2�>�]�s1&9559�b��dc�{��"\S"7�j�Z�SJ�X4�>��������犮\�_���G��w�O�9�v�M��r֒j��/j��5'�D��k�	��ѱeK���b��3\k�����Yј`�d�	kW�?��JXc��Ϙ����p���1��w���'&Zr$+��X���I�!x|��`������f��x�`r�|_��W�&�_l4*8_� ���_z�^o�n>�%bdrK�e��Sp.�7xE�e��$+ a��-��.b5���כ�-��ҮT5��
�kpXzXl[��u��;�b.��Q�u;@�)l}Y{N��}oU�$�LI�`��z��/�������p��L�&gƸ�c\�;gZ��iO��`�B9��Х��<}!�>S��*��J�����9K;Ocz�ͅ��q}6�^ޞ/m�*����=�#����%Qy����*/�d�����e㻝ё��4��]�����P���MW]�qn���{TbJ�DozQ���� �DH/�T�I�I�.�[?0��N`�6�����{����0dLǉ���@�@tfvJg���vCqa���5놯�7}�=V@ ���"���A�F��NJ\��9��Q��n�Y�A��l�PAyu0�T2W�c��4��
�
��vQ}�Z�YK1�޿�&��&&�?`�(P�f���73��)_��͉r��Iq�UȬt4�,�)�(i�Y�ƙ���c:�:��CBd��6s�V��T��[S��M�^�]�r�ϯ�ݳ>���P�����\�2�������� >��,(|��@d�`!�k�娆�����C>7<�F���;��X����T�Ϟ{�����<��ֽO�yh��G����VgZ��t>��F��\�뺀ƫ��šE�T���k�E�����Xd�e��s~�����O�q;_�Z�l�y���+��9�gy:��g���_�o��P�Q���hħ#ʟDXj�5jh�$б��Z郾�c_xS���"��҅a��\�p_ �ШɁ�s�	X�4�UZ8�yI,vn-��r�tC��� -���,�26�G��u�K&}ێc���sk�`ݮ�\{�;�ąƨ<�V� <��`vv��HRyǗ�u��k:�7����^֚ݒ��T�;C���B
���E�\+:g������ha�hk8MoU�]�|�3(�Ԟ������^���<�����?d�s$�@��2|���O�'@�[����+� -��_�}���������+F��y��������g����iRu��r!(l�?���#ޝ�3���2�Ѧ�(]��1h��CH��G�o���:�����L3�xg���ռ���1��:��
�R#�wx�y��;���x�M!���5}?b�D�:�\����u��v�'����!i�֖+����9 #���r@~z0�q+�tm����q��oWRΞz,�6�ͭ�{��~�+&�k���<��=%we����S��ט��M� ]��}�_��m!#�М�de�������TQG5R��E!�i������G���p�&�ζ���"Z�V*����8�Lt���ZXY�� +wW���)�w�Tᑿf���n��͛/mOt]�@��Wºv7��/��`Wo�^B�'�;_߻~�?����#0C>���O�p{��E�m��sHڄ���Dq�'�N���H"�~f��s��[��H���κ㸑a��9�cF<v��cw�)����ck���i��:�)����!?��0����i�� ����#���w��ށx�(����0���ᒝĕ��f���tx�!l��	2���uq���A��}�������D�7�5��_Ɔ�a��~�~�������O8{·K��rG�["Q��Cџ����-����J��(I��U��$�J��8ۘl������c[�m�m��N�S�٭�3��{��ݾ���(���^������U|�ˎط�Y�=�9C�*�9�㫭�b�r�Z�D�Ii!���ԑ�0��� �~�%Y$���?�����5h-��$�x����Ib��*�mĞ�:�[���	�q�0��ֺO~�I���Y�U�kx�
R����w�ñل����z��W��\k���OvA�� Z�t$�p�6a�l\�Q8KAm6�m�j������x
��R4��9��endstream
endobj
84 0 obj
5160
endobj
82 0 obj
<< /Type /Font
/Subtype /CIDFontType2
/BaseFont /NimbusSanL-Bold
/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >>
/FontDescriptor 80 0 R
/CIDToGIDMap /Identity
/W [0 [496 716 606 606 330 552 552 772 552 386 276 772 606 552 606 276 662 882 330 606 606 716 716 552 552 606 276 606 716 606 662 552 552 276 552 716 552 276 606 716 386 662 716 552 330 552 936 552 552 330 330 716 716 826 606 276 662 662 552 772 552 662 552 552 ]
]
>>
endobj
83 0 obj
<< /Length 805 >>
stream
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def
/CMapName /Adobe-Identity-UCS def
/CMapType 2 def
1 begincodespacerange
<0000> <FFFF>
endcodespacerange
2 beginbfrange
<0000> <0000> <0000>
<0001> <003F> [<0043> <006F> <006E> <0074> <0065> <0073> <004F> <0076> <0072> <0069> <0077> <004C> <0061> <0062> <0020> <0045> <006D> <0066> <0067> <0075> <0048> <004E> <006B> <0078> <0070> <006C> <0068> <0052> <0064> <0053> <0063> <0034> <002E> <0030> <0044> <0079> <0049> <0054> <0055> <002A> <0050> <0041> <0031> <003A> <0032> <0057> <0033> <0035> <0021> <002D> <004B> <0042> <004D> <0046> <002C> <0059> <0056> <0036> <0047> <0037> <0058> <0038> <0039> ]
endbfrange
endcmap
CMapName currentdict /CMap defineresource pop
end
end
endstream
endobj
7 0 obj
<< /Type /Font
/Subtype /Type0
/BaseFont /NimbusSanL-Bold
/Encoding /Identity-H
/DescendantFonts [82 0 R]
/ToUnicode 83 0 R>>
endobj
85 0 obj
<< /Type /FontDescriptor
/FontName /QHDAAA+NimbusSanL-Regu
/Flags 4 
/FontBBox [-174 -285 1022 953 ]
/ItalicAngle 0 
/Ascent 953 
/Descent -285 
/CapHeight 953 
/StemV 50 
/FontFile2 86 0 R
>> endobj
86 0 obj
<<
/Length1 9056 
/Length 89 0 R
/Filter /FlateDecode
>>
stream
x�}Y	\SW��߹7	�B�"��1���la�*��,�K
��R��R\jݵ*jK):�U�q:���ik�2���j�3���������M����n8�{N�9�[��v� �0f.C����֊�#��Ǒ�㾿�����ٔr��>�ªp�&_��s��]ehj1x�b��a��ָ�����7��c�������)d���E�{ԕʽ.��� �?� s�a�E� 3	�R�T!�K"#'��*}G7i�G�@ne��M�>�����e�L]#xḎa89���axi4�|}�����=U8��x����O��ĉ�����}@���ފ����n�p�urR�͉�� �����,��H�%)�ٟ�[x J�(^ѰP�\��
���4�w�5s�l<�	e�ƯrvH�l�4�#��W�@��U�(�a��0��������$+��s�w��[�N��]5׶Ov$��x�V��'w�ӟ�o]��t
�)$�����v���
ڂk��4�U=�j`��[*5 _}��� ��F}����5�E��	Z�3�A�VH ���ʉ��;M�����E(�Aa/{t�x���Q.��KW\�OV%H�,ed�K��g�^��GO��ɡ���1��䦜 ������L?a%��1�5�����5���Ή ����/�U� !�:22W������L��R��4-;֡���yɷ��K��B�Y�r���D,qp��b��g�v�^Wӝ���؄P{�s���ck���$����%�$��=-g�� U�sk3�3�\h���j0��|�Zi��g�%={������0	�,��ɚ�d���3C�W&���P�K,z�Le)�BH$�7�f���/S�u[��|�h���w���ǎ@2DÜC��<�~����dbq���y�K&��,	��7��=�����gX�L�����%�W�qJ�$>����DG2 /oZGHWcS@WS|]V @`[w|]�����y�&f�s7T��h+7䪲u���*5��6*��<O�j*[Z��ڈi?��U��U/�yձ1Ui~�Q=��<�0�qDgQ�̆�$g*�0JAΏ5�(��>~�u[�GB,U����-5G�cW,�دc_�U���1�Y����έ௯��� +mV%�^X���vV~!@���5����Az��94԰oì�f]�1; oMl����f�ȐhDХ\)�K��F�QJ4�<��VOEG{��[��c#���2g0�̙��9-���'#�R��S �y���/A�%�t
Qz�S���6)	���� �I�G*@�y�l@�b��{�F� Z��������)����Ej�z9J��"O�ؓ���{� _����S[߈���08���m�u�)�,���J7�+�k��2<^�RЦ�e���<
 �Y��*���]3�M.l@|�<��%廋�J��	��U��\����uJ�n�Cv��dB7@L5NI���=�F �l_%�-Ε�`�r�h�A^�k���g����C�,>!���`���ʡ�"�dM��ců��ךS��tN
�/�V8E��>	�Og4o�U�S��� ��H[7Ҥ8��� ey���K�F���TK'"u�*$����X�DeK�F64��Ct�/��l?E��]����nkij�N���A,�w���w��rs����G��To�0@��qZ�2�H�mh�Q~U��%���� ��N��J���r5��ܜ4�؀1 Ƴdav�'k;{�)��5.�tbfhPOH{��K�0���ĸ3굆�7V�Ĵ�^m썀 ]���ٍ�:C��_��ʫ�h!d���qe����&Dwn3h���Kv"QڛF�2��%"�8�Kx��7�&.R/�z[Rp`[؂�d���e�:/
5ҫ�HCgf�4�M<7���X�M��A8?#>>d���� �/&D�oT��Ɨ� ��Nk�O^a6R_B-!�6���hVԉ��Ʌ2.�)I�	?��7�o��7��?�6�r��gF��+�P���uE����<��`HW�,8-�F�l���4O�ق�|�{⦊�ƣ�9�;I8W��lZ^���	q�'O}�xç�"� ���q�Y��ѵ�3���Qem�q��rv}�\�0j����j�k2�SZ�B���Լ���JT�8�����bdҨ�J����ձ�͛�+��=C53�
J�F��Hn��j�$̺��S�����d�P ��K)5}`]���W�P+�U��]��9
�0�Ņ�����ԯ�]�m]�r͘+r�(OE�9��o��e%tɬ��9�p�����ط�U�f;�<n�Ɇ��Z7ln���\�eB�֏����mH�r����{#{�o?ppwi���H��%[�ݎf\Mؽڂ��5��O$s��y1Y@T��]AvNvbr��P��mʃz��ㄥ��2������?�k^���o��z��p8a�`�0ħ4ed7�FL#Y� �[�����#�md�Ad���%���E�w�(���#7�vA&�erԿ=������"��'$̦�(��k�M��:�_�7�}��}d��������gZ�4���v|p�N�ox~C�R�Ǵl���0�ߞ�IKL�EË���in2M��� )�{A��"��������������U�r�x�_VC�Y�^.Xy�k�P_w�鸸�c�s�9�شvo�yց��n�����q�s�q\���ȹ�oh5�w-�/�����0��S�_�}�ΖaD��q�{��e��9#D��v���?C��+7̀@}�MD����cA�(�7���C0t�j)������M�<�q��~|˨*c.!�9�DS��y�h��
���d�}����9���]l����!�Ո�sP�9�Y��L��6s�F%���T�_˩����?�B�N�rU8Yi�>ju=��4e����
E:l�F�v���=33X[6o���\#�h?w�X/Ms��zn ��H�i��T�R�MUR���3t���
�m��>�
���-�1�Z4�Ac�l��\��&�����	Q����(���"�X��V��WU�zk,���5�7���u�r!f-��|	�M���:����(]��Q�B����v|b��% �"��)ťC�~�;��/j�=��ˬ5�LE��,��y��;�)�^$D̷A��[�-�×�jdt���K��4�+�`�2u��!S��Jk��[�Ԗ�6n�?΅�բ����i�{l!�*��!�
Y&��U@�����^�9b��Gӗ����G8��P���>A/��g�U����Lx���
5�|*��;!��=d:M�����2��E_OT�f�%"��%Ro#�Ƭy\�k̪S��d�D�.p#�u�~��_h|qDΜٽpU�lr���Lo�I�Box�BbQ.	�oK��Y����7c���e�7�J}����<�CtlpCb�KQյ����ϗ�p.�\ꗞ�Y��w3��q~�3#�"G�ޑ�������MV,��	K�s}W�8�2.�y"��9{֒wb�$z�Rpf�i��D����Y�E�����"�[/��LE��>�uqTQW9��t���4����W���I��}^�54\�o�=�J]F�jݾ�->�.�������~����7�iD�H��c<JU�	��ǧ�'1gH*�m�#��V���Ө�"*�AOgJ����W@+��m���!_�2m?=�w�c=iuX����;��'�%��֬�=�)��pO[�1�<�j�$pSG����� ��s��ֹ{���Ξ��[� ��*d���\%<�:���.��&�4�U��T�q&"�Z���\rKI���{q���m�ᒒ݆H���+h�y�ⵅ/U�i�v�rŴ���Ƅ�`fQJ�iM����R,8P�(s��R�����@�&���U#����M�CР/��$��-���jB�����SQ�� �ܱp�M��Ƭ�f���n�L�����}*�����.�h��|�Ӗ�(�A�Q_��i�D@���0?�\3�EiA�g?l�]��n���^"^	��y:��hY������#u�v�*gK9��/���:x��lX8�֬tc����}w6l�w ]Y�oME�Qĺ߄���j���Y�\���<�,\g�[>Z����YT��5��ޯ%�s��q�=>ᙓ�9�Aa��ㄗ��N�~��a�����7�b�4��D�#�u�J��8�7s �v}ܹ���� {�風"����l�)�NL���y"Fksf 2����OI����2��5\��1~�6��)�Ư��#P�9»��?�)O��wp�y~"�������<_A���A��s�gD|�_ʧ\&.(�)܃G�ȏم�\�#����no�����O����O@ww������Q }���n0�	�>=������BGKL�������*h&1��c�g&�1��Q8�(6s$���9��9� ����s0�O��6�EHZ�_�x>�7r�R�϶�n~��sշ�8�����'Gwn5��N��U���ק(�V�ӭ��@>M�7���Od�������w?4BӪw��m���"��5����A�]}[~PP~��!�:��;�:Q4Rq�oigF�(3���?�W=��w��n��G`>�S8;�(J[U�eVp�����Z����U��Q�m?v��S��a�jܭwBM�Zb���	������7���.�q���i����L�M�q�\`юB*gP�N�}��	���@��.��O�ꨗ`A!�y���Q�.�ֈ��_��]�x=$�K+��m�����.3���B�N���6��\�O�@�U�&u�	�[��/��)�*����[N�(:(�uc�m���ƫ��v�44�LP��ׄgj�k2�'�}Lu���\&{��
���q�cάr��Q@_/�< }ԛW�r��g2s=�wK�3ډ_&��֖�U�b����� h�+d�췠p�d�ƺì���ڋ�`��)~&݃���y�Z�Ĉ�ۏ���xH��$(��K%�Ь���R��$�\"���@�Z��r
�u+�B f4�{��k×�7$,޾,���!2|?��-�8;Y=�5s	W]�wTD����ED�R��K����GrD��ýꏨ�v"���	$Z9B�~-��(�".���!�Y�8�z�`Xï����-�هt��剶`�A�5��`ѯM�(4��6	~��ٛ<Τ�I}���_�����{2��>���bƙX���yc7���τc�uCy7���)D��̺w5�_!�*^9�����	��|��ć��v0�֕bz$����>rs5�f��p������ZVle�6E���y3J��M�I��c� ;6yΰ��p��x��[<)�u�-��u�_�*�_cI���F�KRB%E�7"*�!�[����]�(�3��'b�(;Hٞ[����C��d���Ko��]d������Ok��q��i��^�f(�0���&h���ܻ� %m��Z��|�W�'�������L��qW6s��� �\��Z_��$}�����˶��p���ObITb�[ˎ��o���v��L/�韴Xz��3�_�� ��N�C��{X���Ҳ�nq	������N�(�E��`�Z��P�=���i')��4uh�L��D���dK�� �2Z��|�~�l&�I��T�r!5�����O���2�:�\l̶�J-�@�f�.���	|��/9Ddiu^�Rk���'7[�V��R!?_�V�X����jY��[�kb� h�O~����r���*{W{Ӱud���x���M)<\�[V��&I��Ɂ������b49M_UT���wzgjhdzht���K��z���}f���L2�pP�U"uQH���h~��xŪ�3��MF/?���;Ga��[SnDI5Iɜ�rs��t�S�N��b�:n�j������*���*��G��5��$��n�)Ya���/���UH����V��D,O!a)	Q/)a���-��[��z�eAjw��*��2juk� D]X������^�~5�K��,�2k��>��,��0����A���װ�����hW�G��ɫ���\��x?ny�a�æŖ�� �li����-��e�.2]����ލ�<lFq?��ub��}�p�>��~f#���"q,�KD[�8~�N�<��_�ǜ�{a;��
����܌�2���ZF�}Wl�q� ��Ͻ�\���.��#��\��0~���µw��S�~!Ұ�'��.��81�%=L7�T��L���5t\ۉ-�v��Bl���3:�^o��<:��V��k&Sǜg�tAq �"y�\g�XW��]���<�R����E>�L��q���z�v�I���$��$I���M�5�OV�V�V=V���[�Z;ZG[WYo��Ǥ�r&m�tt�Ф�N�3i�Fj��i��es���O�['[�m�m�m��Ov"��v�v�v+��'ϛ\9����}�}�7LSI㣥��K�U � G�-��<���τ���g�#,�b�r�x���3��r��S�41L!¨��g��|K/�	�O�o�e��ǃ)�o���LS�4
k��kY��V�ـOu�k$~oyO-~���8R�O�8�
��`J�2��c�xs����2|�	+�qv=��	����t~B1�4?�1�F*J��;rp�:�)�)G
V�%H��=��o��i��e���<endstream
endobj
89 0 obj
6785
endobj
87 0 obj
<< /Type /Font
/Subtype /CIDFontType2
/BaseFont /NimbusSanL-Regu
/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >>
/FontDescriptor 85 0 R
/CIDToGIDMap /Identity
/W [0 [276 552 276 276 552 552 552 552 552 552 552 552 386 552 606 552 220 496 220 552 552 826 552 552 552 276 496 552 330 552 552 496 330 716 220 496 716 716 662 552 552 496 276 662 496 662 276 276 772 662 662 716 496 662 716 716 552 496 276 552 662 826 276 606 772 330 330 662 716 189 258 936 579 352 579 662 276 276 276 552 579 579 1007 662 552 552 220 219 ]
]
>>
endobj
88 0 obj
<< /Length 973 >>
stream
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def
/CMapName /Adobe-Identity-UCS def
/CMapType 2 def
1 begincodespacerange
<0000> <FFFF>
endcodespacerange
2 beginbfrange
<0000> <0000> <0000>
<0001> <0057> [<0031> <002E> <0020> <0032> <0033> <0034> <0035> <0036> <0037> <0038> <0039> <002A> <0030> <0054> <0068> <0069> <0073> <006C> <0061> <0062> <006D> <006E> <0075> <0065> <0074> <0079> <006F> <0072> <0064> <0067> <0063> <002D> <0077> <006A> <0076> <0052> <0048> <0045> <0070> <004C> <0078> <0066> <0041> <006B> <0053> <002C> <0049> <004F> <0059> <0050> <0044> <004A> <0042> <0043> <0055> <0071> <007A> <002F> <005F> <0056> <004D> <003A> <0046> <0047> <0028> <0029> <0058> <004E> <0027> <007C> <0057> <003D> <0022> <003E> <0026> <005C> <005B> <005D> <0023> <003C> <007E> <0040> <004B> <0024> <003F> <2018> <2019> ]
endbfrange
endcmap
CMapName currentdict /CMap defineresource pop
end
end
endstream
endobj
8 0 obj
<< /Type /Font
/Subtype /Type0
/BaseFont /NimbusSanL-Regu
/Encoding /Identity-H
/DescendantFonts [87 0 R]
/ToUnicode 88 0 R>>
endobj
3 0 obj
<<
/Type /Pages
/Kids 
[
6 0 R
13 0 R
20 0 R
25 0 R
30 0 R
35 0 R
40 0 R
45 0 R
50 0 R
55 0 R
60 0 R
65 0 R
]
/Count 12
/ProcSet [/PDF /Text /ImageB /ImageC]
>>
endobj
xref
0 90
0000000000 65535 f 
0000000009 00000 n 
0000000300 00000 n 
0000103106 00000 n 
0000000349 00000 n 
0000000444 00000 n 
0000000481 00000 n 
0000094127 00000 n 
0000102965 00000 n 
0000000797 00000 n 
0000004729 00000 n 
0000000601 00000 n 
0000000777 00000 n 
0000004750 00000 n 
0000082599 00000 n 
0000087174 00000 n 
0000005092 00000 n 
0000011394 00000 n 
0000004872 00000 n 
0000005072 00000 n 
0000011415 00000 n 
0000011745 00000 n 
0000018561 00000 n 
0000011537 00000 n 
0000011725 00000 n 
0000018582 00000 n 
0000018912 00000 n 
0000027803 00000 n 
0000018704 00000 n 
0000018892 00000 n 
0000027824 00000 n 
0000028154 00000 n 
0000034615 00000 n 
0000027946 00000 n 
0000028134 00000 n 
0000034636 00000 n 
0000034966 00000 n 
0000042159 00000 n 
0000034758 00000 n 
0000034946 00000 n 
0000042180 00000 n 
0000042510 00000 n 
0000048555 00000 n 
0000042302 00000 n 
0000042490 00000 n 
0000048576 00000 n 
0000048894 00000 n 
0000054537 00000 n 
0000048698 00000 n 
0000048874 00000 n 
0000054558 00000 n 
0000054876 00000 n 
0000061545 00000 n 
0000054680 00000 n 
0000054856 00000 n 
0000061566 00000 n 
0000061896 00000 n 
0000068164 00000 n 
0000061688 00000 n 
0000061876 00000 n 
0000068185 00000 n 
0000068515 00000 n 
0000074165 00000 n 
0000068307 00000 n 
0000068495 00000 n 
0000074186 00000 n 
0000074516 00000 n 
0000080153 00000 n 
0000074308 00000 n 
0000074496 00000 n 
0000080174 00000 n 
0000080387 00000 n 
0000081851 00000 n 
0000082114 00000 n 
0000081830 00000 n 
0000082745 00000 n 
0000082958 00000 n 
0000086184 00000 n 
0000086535 00000 n 
0000086163 00000 n 
0000087320 00000 n 
0000087529 00000 n 
0000092800 00000 n 
0000093271 00000 n 
0000092779 00000 n 
0000094268 00000 n 
0000094477 00000 n 
0000101373 00000 n 
0000101941 00000 n 
0000101352 00000 n 
trailer
<<
/Size 90
/Info 1 0 R
/Root 2 0 R
>>
startxref
103282
%%EOF
