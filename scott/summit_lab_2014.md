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
	default_rhlogin=â€˜demoâ€™

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
/Title (şÿ)
/Creator (şÿ M d C h a r m \( h t t p : / / w w w . m d c h a r m . c o m / \))
/Producer (şÿ Q t   4 . 8 . 5   \( C \)   2 0 1 1   N o k i a   C o r p o r a t i o n   a n d / o r   i t s   s u b s i d i a r y \( - i e s \))
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
xœíMoÜÈ†ïó+x`™İœÎ Á’lÈ!€a99Şİ‹xgùû™J¤úòmÖ6©æH6°²¸d³»º¾ëíâû?}ùGñÏßŠ÷÷_şS|m~ŞY•7õ¦<ÿ)ßu/øu±s»âë·Õ÷âûêóêóá¿ÇŸßWÃœúíë¯«÷ç¬ÎW¾Üÿåğ¯ÿ¾øóá·_Š¿ıığãÇfˆãßVµßİìêÃ¯ÿîşêÊÍîf»/×ëÃõ2üõxó¿VıCñëaåÍ®,½ÛoªÍy.Áï‡©›§Ú®ÒşvzóñÇŞ­|Uü÷§ÕÏÇõœôM¹mşôşûÙ’"îï.Ø·şn~éİÃêı§ºğ»âáçNltşñğmµ)Ş­ëâáÇâr?¿¬üé¯øÓW·W*\YŸ®ìÛ›ó-ÛQmO>>¶ ]¨ï,îò¿ŸSWßAİq/=QwW¸õ%êú}ñn·~NŞÓó›jUw§zŞ÷u¸ƒ/<÷ºgîëgd®ÏÌæÚÉïNWv!‡v.ìO6Ü†Áw×ÊÁ®Ü?ÛŒY¸3×åñpgò÷¡~ü²ÛÇğOÁz]ŞQ…4—C0¼ÔÕœó¢‚‰¬¯Vvªõs*ä,;Õ‚õgòÂbZòy(	À…¬€ï!¢=Õm8È:|FİbTÌƒÜÁjb&áú\-ÕˆV]­ oöÏw,gAß,ÙH¶“_ k‘äk £ãñ›nxiy;é†08ÉY7,9l'ç×…¾®Û‡w€C%—kÁ‡0¹»Ëé’!åq¯•Ç)øt5RHÏ‚±5¨¨}‡Èïgæ>… ^Â©ú2¸Ã»ğ/	ÿA½¼òômP¼ËAÿ)O¿äìC;y_i…3^{úµ!ãWZ	õÍ5ŠW7ïsàĞAñZr‚Â/2AñæzLèz\£:i£óÛ$rP,9ÒNŞoTd‘CÛC½À¾ÇôCšêå‚® ¶„ÀmÃAŸ†¸œ«-@û6¢¿Ë«ErÉÙ‡vò¾ÏBˆß…bŒ4\˜m€9£¡ÅLe‚†ËÚ•tÛê§İ_¥ä»â]U©rÄQ™îĞQTK¥Aù®*Ğn¸vh¾úA>¬3ná ·°ñV'à@hÖu]£&ƒÏ²‡¥UKûÛÉ¿TV’¡ırY=‰(NJõ2MHÏtr)H"
äA:€Ÿ«W¡ëÔö©Ğÿ~Ä=¡îöwáCø7èû3óøN‘d‡W‰¼YîÂS·—àî-wx9æè´ƒ¹ÎÌí¡!:¯nD¤;.æ‹W7Jbp‘Àh;¢¶õ&pz1pğFˆ¤¸;N8cÒ	OäîÊğ=6<;¸èÂ²Éi ù6‚aÁ#0Zô&»84J°Ô»`Ïz˜†¡Òx4ÎP®Ÿ\È‰ Sãw¯Ôš…Ê$,¡8¹¯Ì@Zõ±Ç*İê=hêì~3°sT®“á
¶™°³ïcçÍ&°Å>d·à–†ü[n{HĞ}Wš<’«°E;÷4ô‡¥è¼Ûã™
W®2ÿ{:Şõ”Šè92 ûúÃLÀ™î<R…ƒ"BÁp	³’(Ãñ‘pf|/	—Ëx-ç¤™&â>¸ÀÁTñ½ç~§hA¡³°é_mÄáÔy$Äö£`ÖÅ#ÇÏ¹p<¢_ÂjAS0Ù'9ö6´±ú·@rAõÌÁĞÎa- ©¦XŠ­Å´’Âo`—uıhöû¾½ÌE	y¤ĞÉ!Ø]­üC³¡É —`™¬«÷á•™iIÔñÛ…cxPSÇâ´ZÆÔå<Lì/YÆÂeZ´Ñ•µ‡ÑAOe©S"š©Nârgã.cÿ¡CvóÁG›?=&o\÷/ß`ı´ÎACÛá‚Qu, ½R¼j$Ã8ÈÀı¼#‹¡õ4ÎFgü>xÀúD(c]ŞfÆB”¡…w•ió'DÄnbš‰Â‰5H!ş—ãò¥æÂ#3ùG5Ât‡ZÅà†iA–ÑdF	\¦hS§q!Ã;ÀfzuTæãE†Ú={'sïIÄC„ˆè|Ñıï7<œÅáÄ.Ì}|âŠ&Qs&&Òƒ¹ë¬.„€ğtÕ¨œ»ToƒÆf®†(çV;æóÌŒúƒ2dĞ9%Ü¡³ãr«@Ä¹âéyNâ40@D„)òÔÚîäî™n‹&HJƒ0Sqhšğ’'’´÷ÈBµín¸ïYO][é WÚwD™&b¨õé„0¤W]o“”!Æû?3•ÖÎòÚñqHŸMÉTüÚ¾r½"³î$ˆKx?¸Cû¥’ìÚd´«½ÿñ„¥´¡“¿)âãÅàt~4Iğ×Ë‰ªïƒàmë1¼á-„àEË»º]Ğ‡˜ã®ñàuòa˜GäªšQzá0eŸïçˆÇ­†ât$%xq†X6°‰Ì³‘8£	Ó(0 Òq&~m©×|©°DB?5)1[Rï!Uô-.‚”àî"g×‡w½>„éö	B„LäLFr<Ú#f ûŒwLãî0¯
È‘…L.ƒêØ(9(W+s]ó„ËÕ?R€?t"ï-f\Íc>ëß{R»^HjDÂÉ€üCµ [‡P×€Z‹@GèHv¼= ™”˜ˆ TÖ™ñ¸ª9¹æf&aK(ÊiûI‘û°`´H	$0’åZO£¬ƒ™B/!=0’¤¬©scR`V^X×UWí¢¼áÇ‚ğ ‘¡&5ŞÁn<»Lé|4nÕ“qË÷h„!Å
ñ–,í©t³)Ì,ıRÍ¦P+	İÙ¿$ZTn‡Ğò §Q`–Ö}i&¡ô]eU¹ĞYL<<É±J„ÆÏç(¬ŸZÊFQDv0¦:Ì†9ÊÎÅÈX-âÈò,Ç#˜{–Øm’Õbb3•ˆkËÎiı¯Ó§¹œ½&"÷:cMşÔóÃtVwHôt)E]Ç…†ÆÔÕ7q}âşû²xs]>3@}¦°‡TYŒI©ôxòH©dlÚ.ã)²mg‰[LRûåÚuÅ zy•§…hè ÛUêvëêQ¤# uÄ£ÔtVìP³h. ™øP&ŒíP1=Â¹ ÓKŠÁÊ] Q5½+‘TÂbqzq÷Ø¿ Áv€zO.¬Ûjã‹ ÜcDáŠë5®
9¶ÛÖ~*Úik˜N=NsÊÙ`0%Xµå¨¼N†àåzqúp¶ŸúèÀË8œ?,FtNN°t’ÎĞÀÀ¹I:]O	}^ˆ¦)øRF::XáËå÷ÍÚíÌA…õ.G†äï6ÓymYÖPT:°KÕõ†ñ«2dÕ&0Œl‚“M·>]ø8k'uJDcèòÛøšîrŠI¹´Mº‚Şµû²&»E=¾.v
}iY¾•'é¡˜â¬fv<õ x:Å–7¯e¾4ì¶Dp/Ã4RuN! -#s‘õ¼Rü›_OÉ†l T]¨…4ª.ç2É$(}Ô@cgq¸±™–8?ÂpŸˆñ‘ÔØô1¦©,Îƒ³›F£O^è,E‡GÂòIÖµí,2ô\“m¼"jÓËB³»Òu·fÉúïˆä°C[Fh&­_ùñ˜FÕ™¤:&‰!"|]AØñT(·Ôß°¹†ş_)rûé1j<ã<íÏœ÷·ÔÚuïSC)UWl¦QË)@¢½_SèTƒ¥ø¢HîZw Õ#‰€`¶×’©pkĞbjAPëM—ãÜdƒğ5´e7ğÜ-½¾´O^pm,XX×izèÃ
€€„¹÷¤w‡à3¥5œŞ‘bé9¬3Ê™ }à$«M¢Ú#ªzîÚèÌÓrPÃw„iÛ7>ó¸LãÊ’|Ä8IX™Mò‰Ø0¸m·Ù[§c;ÅĞD„`j?~üÇ£fªR?4¦jS#ØRXvÃ§“t#'ª7èoÇMbbÀJ½ZÔ´» +’:kcÈ¥8İ¡ÒğQ¡7t\Ÿ´8©†zTOh˜³Ù>\{ÁBÚ#Ä.Û’ON‘ù5dèR`'RhnÍ†O¦èŒ¥¿½î›´œ´yhªùC§cµIÑY.¹Z“ğr)>ù·üRª+wUßÖ,ùI
¡šå$J„k3ş 7ñÛÛĞOÃóªo±à³Awƒm×¸|Á"ÔÃ$bØÄùB+(	Ez&TÂ ³AyWà"íºj}oøˆüêãÅì‹¸î©Ñ÷[w0©¬t›¦œ «¼:-qE
,_	5$u›ÎëaêõLÃ½­P}Â…HAäˆGzj˜Ceq|#2g85Ï·¨tëÜìÎU½½âì[µy%ñvµ¿$÷¡ıUÃBd/æëËí?I+C!ÈĞ~5Eìk°1æ$]Îæ ı*€!ç¦í!¤«	K`iD_—‹r)l,'µµä>è%h™…24a‹¼øÃ±ˆ*ëİÍı3˜Îµ]üµIñ‘m½S|äeR
Ùbø"R=¨y
•©a°)š¥Æ'é,¨ñP§qbgJÿ?â5†L–voî¾¸w±_‰ÊYQïG(jy¢ƒ
a/ëZÛ¾;?ªï{Şòú¾7e½Î ¯¹¹ómò·‚˜ÒÆ)>—cpù_ùÙqŠê“‚zµÚÑ=ß$h	Já½!9™ ù–åHŠî_Ø‡fìú]|kZ.Ó B"’&ã÷*B¤ãÛñmõ^ÕÙLZÑZŠ7†¶†¢*.è
ˆ4:U¨Ú:ÖT´°°H¦“Î ›uŒÜ[´£><ğ)wRµ½Íç9±«³]“À8­(uùïÌ!ƒŸpÔè0@_½ËìbzİßkA¶O~.#"ÀÒ´pƒñÃânÃG 8Œm0TCe="ç¬¹p’8W[yEùd‹ï]İ~úû,uºÒ5
ek>ŸWÿÂ¢Oõendstream
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
xœí]K#9r¾ëWè¼Àpø~ †éŞn>hL>>½ÍÂã=øï›©’2#ø)™ì”*k¦z°ÛU_KÆƒÁ`şøO?ÿÇñ¿ş~üñãÏÿsüvùûãÏ­RĞ/Ã?PÀúc6ùøí×ÃoÇß__êÿÿv¸6ñò…¿ûÛáÇ—Æ/ÈÏÿ¥şôG{üçúÛ_ÿöïõ¯¿\¾>|à×C²Y•áOª¿è¯F‡¬bÑŞW\·¿şïÃ¿şéø·Ú­²ÖÖ”àÂK_Øï?¯Vº;=ñkÎÿÑ¯®ìCeÇYw,Æ¼üğ¿ÿyø¥R»¦r¼ü™ı™RÊk“B´ùXÿ§L²®Rıõ}Q)eÅO‡Œ2Ú(ƒ­?æbME‹²¾Â…¡N«l)•‡Å½­xm)Û&¸SEÛJèH)z¯JŠÅ?Nı›ĞoŒŸ	?‚Ò)}¤¸WZ]I”"CÇş};P|âçÄğ‰{J‘Hê¦¼¿UƒÌjT:i}ĞÄğ±ÊªçT	èh’.§rqFÙ\BI„ì¼sƒ´¨u•JÈ>_Úq£r(1¿´}¥8É…öJ‹òCµœ”1Ù–Îô6Q¤èØ?®å‰ŸÇGî)ÅIR·å=hâ—?‘áTûmòAÏş|g8•dC¸1œ.ø`òZÅhgŸLŞ¥œ´=TÌÅ„ÌP>œ&œ'‚;å£6Õ_PŠu ˜jµ6¶Ãé‚ÂpºàÃp
u¤†”#Å}u\ÆU›6”"CÙpšp>œ&|âR$’º)oPb·OLZ+S¬.+‘àÌ'œx³¤«-ÆXJæhF±)Xî“ñÚî“	ªşJ¡>1™X§½˜4ûeJ$8ó‰'ŞŒPdèØ?æ	?'ÜSŠDR7åİøDÒ:ó‰Œ*ñPgzsÊÕÖCàh5áâL1Ü'&c«TBÔ‘ûÄdœÊ©xo©O$r¡ı£Ò¢üP-E[¡z›(Rtì×òÄÏ‰ã#÷”â$©ÛòŞÎ'ê-Å:sc8]pæ	N¼Ù`PIW·9Ê†Ó„óáDğ |*9ê‡`JÕ§
Ãé‚3ŸHpâÍE†²á4á|8|äR$’º)ï}b®ÃØ}£Ä	ç>qÂ©7ËQépEîsRŞDm]ãK©x5éÈ}b”Õ`pISŸXe¥²©+¦D‚2%œùD‚oF(R7õûÄ‰î'î©O$’º)ïÖ'N­sŸH©R5áLoõ‹ÎFTùVªÑGÛøÄ’ªTrN©ñ‰%W³´É8æ'¹ĞşQiQ~¨–©‡"­¹ŠûÇ‡êÄ÷‰÷”â$©ÛòŞĞ'Võfjd‹Ãé‚sŸ8áÔ›Uƒ
Îš!”¦(NÎ‡ÓˆÆí´3Ã¤9Q‚65øípº 0œ.8ó‰'ŞŒP¤>§	çÃ‰à#÷Ô'Iİ”÷v>±¾Â§Ú7®D‚3ŸHpâÍªC¨ñ–uCäKQ_×”¹z	îë l0.fî‹I5˜®±¥>±˜¬ê‡êx¡J$(S"Á™O$8ñf„"CÇş1ŸHø9q|äR$’º)ïÆ'’Ö™OdT‰‡"8Ó›¯#×Ç”9ZMÇç`<÷‰¥Náu¼[¸O¬—j–>Å@}"‘í•å‡j™x(Ú
ÕÛD‘¢cÿ¸–'~N¹§'Iİ–÷v>q0…X¹p0œFœùD‚oV†p·.9]á(NÎ‡Á«\µyO}â€VÁÕføpÑf88ó‰'ŞŒPd(NÎ‡ÁGî)E"©›òŞÎ'=´šj¨Ä•Hpæ	N¼YE]¸šµsEÏ>"5q¢©Ä+^yç>±â¹öÌ§|dM"òÈF9A¿q~FœùD‚oF(rôÚ?æ	?§¿rÏ(N’º)ïÆ'’Ö™OdT‰‡"8×[P©®&Z4Vªõ‹Ü'VN‡ÕNO¬x¬viùÚ™È…õH‹ñC´L<m…ém¤ÈĞkÿ-üœüÊ=£8Jê¶¼·ó‰gSğu9X`8]qæ	N¼YE‡Ü€)ºAép"8N/µWñÈ(ÑA*>6ÃéŠ¶ÃéŠ3ŸHpâÍÅ†ÁÙp¢ø•{Fq’ÔMy_”ø¥{¿hÈóöÏl7iÁçé^“öš~ë&úáëáÇÏ•müúËÑ¼ìã½üõõ×C¨?;—_ÿrü‡ÊoüÇã×¿ÊğogÀ¼ yÊğÛO|<al’>aôp`Î@š§¢]Óı€F—¶c¶4d‘ŠÌË‡¶Q×òûsÛ(ğÒÊ:zÑŸ¥F±×~¥íò_‘¾òi}OAÈ?µìƒæşÜ˜6Øús,hÄZ©Ëìwh©ÀWŞ3hÍ;j ^än0L/ªüôµNB;B^n ªõB|Œk“‡2t]v\¶m ÙÊ c0¶Û.`N¶Ãn½È~ÇÓáüDw`>o`…v÷ã²øk_?53	gÀØ5>TT=ƒ[C£}Á”
&"Giò”:ãş×x?‡ı¸z~ü]GzîEûÆÜ	:Ä™ÂEyLaĞ!ê^o-°‡ŸÄÁßRğyAOå:öiï¾İ?«;1èDW&Ì˜ëC[4qiŒsšHkDÜA£æÑûÛ½¦yáÌ » ´aØ’©º*UÿdÌÈ¡„Vô¡Ÿ[²àËeËyÈnÚ naPm°ÄÜrá+²emËaYÜ½ïvWß³»‹­ÏĞ­í'1¼ùØ¶úçÖ6ñMrO¬oÉØ È í~d§k·Öˆ®Vl´CF	F„Ú¢@ôÌ—üòlç#˜éXÏ-ˆFa$jªÇMnâó¡gë³Wnÿaqğ³üÂd#Ï>òZ–)@yòİ`%uÃE®ŸlÑ{wä^Şğ’öI@Ñ'9^í^¯Ê´ÂbL“—k>9´f Ø‚ÿõ©xTÿOíWZ8H‚¡Ùİ'§}ÙûÜúƒ™YNw$¸åŒ2Ù¨¶0;;åm%qöëŠ²_k
yŠŞod]µ-•õ˜‘w<dW=çšÈ'ä5şc·cKø7šéú'•`f;/÷YdÊµÄ„ ŠY©TÉûŠbRtÁ–°Øõ7ä ôCV®¼]³Î‚u¸¸úéÙ¤˜ĞíÉe¼Ò!šíÒÆküá‚åĞú`¯çÌ4
ÌÍœLØ³+wãÀÄ\5ˆUœíÌn¢™=æÜ(O>¬Ô‘Ú’sŠr
ú!ïÖ.Ø­”ù—ÓC²·Ãd¡ëò|Ğá‡:Îûl¢Ù‡Š‰šÇŒ9jg.šì˜ü‘&>èöÏüŞ…üùNpÑ³LGkg`w
?€J_Œ>N¬Û\Ä[30rYÑ/ıÔ|é¢"*!Pºl[‚‘Òïàâñ3•^K!uNº­ã¹N´–, ˜ôá3©pn}ŞLb1Êt^Yàs#À&ËåF&›êûn-SÃî¸iÛ ¿ƒÍÂwfãŞ8‚ş_Ü?%ı¢ù2Oúâ˜)!Ëgşîª…R®<>äÔón“Âòv¦&np×`I¸ŞjËg«q©-ÇšÉ8ycí9q’(12MÉ_,iµrä<äQêÆ¼Î}„»"Kï£íxM™µÅWº+í×Ä=‹ïØ°–-±#ë×‘Ãz¥´xG‚n·ú–RÚİi¿ïÊà>iïı-çëédöìî]™í<„â”—ä#M@¶ı„ƒûDÏ¬¬pVæ¦“uEbrRÖºb‹?ZoTU™-C‘ãµÊ.G—)~ª¸U&úáğÁwêÜJ¬¨UÉ£#Gı°€/a¨‹Dñà•%{n›àCÁœ£?RŠ!ªœ´OæHû7¡ß?~:…ûJÖÙ1<{•­³I'J‘¡cÿjÛŸø9q|äRœ$u[ŞßY8ë]‰{Q"û[©Æ`@#>HË¨díPˆàƒ´¼+:}qÊd§­ç(ÓÄ„sM<(\êŠU†:Õ¹4qAA¼J+*ç‡SC†âUZÑ:?”T"J5Ap¦	ŠÜSŠ“¤nËûUsÉİÌ4W3fóé‡6:L·§-Ä€y‚òûÊm¨3Ge§a‹I…	z7':ow,˜ ë`â)z\-‡¿;ø©£ê<Doø¼i‹U9k4Ÿ7«›QVG«-Åm	Êf£u¦3C‰·¦8õÖg1Jqšñhÿè¼Iù¡ó¦uIWR.¬WŒ¾dË(R”xkŠSoÍğ‰{B‘Hê¦¼¿3øyWâ^”Èş…?L$ø±Å©½…âƒ´†’´gªãôÏP¦‰	çš øŠPŠSØÒhb~MŒÁuY¹l’cø ­x®oÍ(R”ibÂ¹&>qO(Iİ”÷{ğcË{ğó”àÇE)ø(DNÁÈg‘:vĞTİrï[j;µ£sî/Ìçş:*¸uì˜op5·ç¨|%úG~åÍ±ç,Ş+iI~è•®ËnçI·»î-åöç˜\LÌ5mrÓTŞA•·¥åy¥£r ¼£¼¾>aOrC&û;¨¿S™³!Ùk>©^ízw†m¬ßÈÛbZÙäöænœæúËªS?¥’h]ŠÚ^!‰‹³Å±?àZÇ{Ô—?Í[Üí¿É.åNc÷g%“˜y¡C¹ËYë;G.v±º{šg±ñ¬´#\pÿéŞ­Â7™º)(ï˜¤öQZ%İÑjëê¶”ÖZ˜9#OÆ<Lí'4œøÖPÂÀ°h/-ˆ
BKØ·s^û	gnàº	–guš-×©Á,±ÕªL$LäKŒ.ÑnCúâH¡äàK†:I¥uY×6ŒÈ[°"J
»C®ËìÓ@²Í³šE| P¼¨“%ß+ºh ÜÅ}½µ.ìÁàw<´‹İCiy‰Òlg3ßÙ®¢›şÄCÌ®áË	±^èWRtkI®Sõw™ä‹éò
k}­ÓuJÖwb²`‰Áªí¡ã8MÇÕ‰ú.åAÖ>³ıy/ÔQ ÿIå@äÛİCwÇyÍœİœ6Ÿä™ŸR¹ê•†ê…›vT…ñífƒS@ë´‚q·îå ê&—·H'oğˆÄŞ,ïx:NñÏ‰ù1¥ßÖsÈLHoxjZò"ˆ<â÷r^¦cF|HXù†®?F o¨È³lÂÿÛr4Ã›AÔÓàÛÔm4Ò³›õÀ§ww*×ó$gİ¿oéÖù ä¹§c}¾I”-¦§kÈzéöogŠ{ÎJZ¶Tù¸oÇ–²w{­œïzYP‡Kœ79vµë)ğìªıÕUßxzL–³\İK|;sAáÔ4]¯ooZ²@¥]±u,{Ìòk³m£ŞJÛâR' ‡Ğ1¹ËIÑkîÌÈõÑäôƒèeø&Ìe3÷éK ‡oÃd“\¥L|Z½ãHyq³
»tİãFò[²ˆjlÍ¡Ûï	2«§×ÅÛÑBõmØiái0<u5ma”–Ğ…€Gşœ2q-°÷ç…­æ*Dª®M½c—«ã,AÏjV^V€Ã—S_¿îŞ$	ülû‚7ßpÔñpTG^©£ğ°yÉÑ[ÇµÒõ=õàTàøp6$üàİl8á./øq*Æø­½4‡^’&òÉ ˜Vğ]p 3¾jº2œÇşgã¯}…#º0_ÁÉkp×p|fV˜&á+í'.ƒ Î“Ş!k`ï@œ{¬!¢ƒ¯ÀaNdö;¢èœí‚“{RB£  hÆ*j»Ã¦fÖ8Dd3!?„ë÷z†=ˆr·ä\×÷T´2Zùê=ƒ+Çh‹JÉ¦ä‡úƒÃ?¸ŠŸ*nT
ÑøDqc¬ÊN—àÑi•}Š)sÔªá–ˆsCıA‚ûÚ±²Ïç¶	n•«ÂÕöH)z§\Ša¨2Iú7¡ß?~:¥SªÖ,Å³ËÛŠû÷í@ñ‰ŸÇGî)E"©›ò~/ÁSĞÖŒÛb8}¯äÖ‚‹Ì¼·
q#¬_îÄÉØ(tU,'t	“á1Q¨¤wç #Ş>†ÚÄ»(s/T1!rõŞYÀC €AÌzN6{“•8óÎ=„|/¼¾€!"§EÄHLş
+0%wròE<ä+²ØåPu‹X¥Cê3©ÅU)/P”"¡ÕÉ´ë;Ptı!K1BÆEx¡ŸvïSÓÕ§^Òw4#¦IxYÙTÑíÀwÄ{Ä8T¡0o°3ñ+ˆÄ“®!o±ÁÙ‰«´ÖW%¼F´5ŠF×_)>T±´¡èu&]Ãé˜¼KõÊgÊP°’â5ø.%Ä—h™â^9k\ÔGJÑåJ´1iÿ&”Eâg‘8ÁIM(2tì‹Ä	?'OÜŠ“¤nËû=?GâÖl‰wœi£y ÚxÛhcfÀË€pØòµ°ª0»HøİÛÁ±uu}ß­®ÙnÜæJ]ÇA(ñ…ù5ÌóÄ‹|Bx‘ŸËş¾Wa^Ï2M˜+–Ÿ7N8ûao3¡5ÌèD&¤ÖĞòíõfÖ@e§>ÀFÍV>Q*Së:¸+ËXpMŞ@íx.æõWŞãÈT>½‹ìŞšÅåj 4÷Ğü½J@r¦@^Ãl±Ş|ÌÆGG†jÌä´d±vÊQE²vuíäëâ¤¸`§ø©â¾Ú™¶9	îK]¸K]'ä4ÄöÃãN­K	}Ö	/Ie“sJç¶	^”ñ>:s$ë*B]–¤ek'‚³µÁéªg¢ÈĞ±|í4ñÃ×N÷tí4Iê¶¼ß×Nçµ“3³åí{ÖNÖÿ$­{à+ğ|ÎÄZšñÀÈË`†gâáÆÄ½¶3¢€ÛÀ>¨¼ §¯´ËƒKGè:¬ia‡5sDÂáW(uÕNå³^wv¨P¨{}V…*÷C–GkBÈ-ÙÒ:w„¼…‘¡æ€}h˜›¹ùroHµT ×ãVúPEÕÍãŞÖ„4‡Ğ’m?áÛ}´Ë×ÑnÃÙP°©7˜sa¼ë¼àµä¦œt^°ìÜ¢jØ·°×_¹İ¤{ÿC×kz¶ä¨óåà»2©U4ä{ùòbùöWG†DNzÊ7×ğÆÔÒ:9ß7eîÖ4ZpAVŒ<ÌÀt!‹*';^:y#¥fóÕçY$5[g÷rÑ3‡|âC+4ÈxÃ' }¹h ª\Ä™»®$Uü-MÀ»;³æ\*v¯¦glä,¿o•<h«D»û¶µÅVÉÜÎ{™£§lÜÊ›Ÿ—¾{î€õÄß*Èwkå¥ XÇxÁ®Îúi£Kàeı{M›ÄrÑ§¥¡ÓN=Ày–/n±!.P•\E~öTÙ;â3£ºUÖ.–+ê‘zÇ+°yj¬c;Z^[Âì¾‹AvoO×/L<éâ#¶pñÆ ş‡Y®Ùíåú‚s¹ëwÊñL±Ø†ƒ›møƒ§ÌAò…G\f\ è˜|ËRŞ‡ĞÛo¾í”÷)‡0\!´EEBô?ŒZ2ŞDŠg•vÑZWQ¯‚µ)j•}f¸.GqãUºØrn›àA•cvGJÑ$¥ƒ	¹Nî¤Ê6ß	Î6ß	N¶Í	E†ıc›ï„ŸÇGî)E"©›ò~ß|?o¾ûæ¦ÈM.w¼2Sïî^‰¸Í·à.#îÉÈ[çâ®…=ªv[ËF´TôŞß¤°~z{ï9«jØNÄ°¼ğš3‰{Eİ Y¼—Åú&•Sá°¤üÂäú¢Ø¨¼šëØoß´†+ÂbîÇ˜Ì‚C«zXÿ”8Ô§Äz5PòvéåJ‘ğ5òâ%ñı}ì!¿°›(—èİò­¹b÷‚á-ŸØ¢”Xw.bÛôvO¡d”ò(î-ÈßÈ“Èviå§|B_îdEğê±œÚâvúi¢÷b•Gkx@ÎÃÔ®+›B0Ç_)(kutÑQütHQ}¶–â)©h-şÜJP.Ôp£A£Š)šáà>ÃMPÃºÈyp<ÖÅşğt£h’Ê©ØŠÒşè7ÎÏˆ³œÁI¶‚Päèµ,çAø95ø•{Fq”Ômy¿ç<Î9P®åW7ÉyÀ)E8R*—Mê¸“€iy«y¦"éç·hÇù¶4ÄŒ-Ö,–w0ğŠ%Ì+=w½ÀÓŠw½œ¡®÷Ëñ7*æól¨ª=éçËñËáÿœĞ‡endstream
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
xœí]M$7r½÷¯¨óCñû0hF’àƒáƒÑëµ±(-,ïÁßÁêœäFf±*•=]İU°ê~ÛdDA2H~÷O¿üÇá¿ş~øîË/ÿsxşûå—'­RĞ/ÿê¿Ÿ°şM><ÿöôûá÷§ŸŸ~¦ÿııé«ˆ—şşü·§ï^„?½ ¿|ùúéÿöğÏôÛ_ÿöïôŸ?OŸ×?øí)Ù¬Jı'Ñ¯GüÕèU,Ú{Âuÿkıãÿ~ú×?şFõĞ*kmM	.¼Ô…ışÉ“”Ë:—ªÀæJ7}Íé_üôÊ:A£‡bH³îğ¿ÿùô*a®šÊqúgõg,=*¯M
Ñf—Tt)ÅjÜè‹J)Ûè?>Å`”ÑŞ˜€xV™”‹­•Ê*£g¨×J»ìkCxB<&e}ÈÙdUH†Ä°ÄX)¼9`ıúÌôiøñ)(BÑ™L¸WZ]RLX"Cçú=?!Şô92¼i%‚¥íıL2«Ùé ½z"“UHUÏK­ĞÑ$]G»øÚ	å¨¡Rs©Z­È*Á{7Éñ¨‚-6ë–Øì‚õCk¡>èå¤ŒÉ¶ÄÀpæ·V"¢sı¸—›>GÏÚc‰ÍRËö®øËŸ ;•˜£M>èÕŸW»SVŞ¥’Jßf¼6y­b´Æ³¿¯MŞ¥œ´%´(ÈF–¡¼;5œw'ÀÉG¶$Se·	¥æé¬åİiF»î4ãµ;ê©!åˆ¸'â2Î¤©O%2”u§†óîÔğ¦=––Z´·pâfNtN+_tŒ™;pÆ‰€›9gT æ—,G­Ê…H<rNô.Rƒ-Ñ'Î‰¤œòÔ´ANô¤v°Úé€N”9pÆ‰€›A‰ëÇ8ô9r|ÖJDK-Ú»ãDÎ8‘•
8ó›SQ§bG=•jRœ=áÁ«çDïUÙÕ€J»@ı˜µ@æe`(”‚~k%":×ï™·ÚYŸ#Çgí¡D°Ô²½÷ãÄÚ,ù?§¾;Í8ãDÀÍjÕ´NÔNzºÓŒwİ	ğDRœÏ9±¢Éj#ïN3Úu§gœ8°”ÈPÖf¼ëNŸ´‡ÑR‹öŞ}"åœÑÑr'Î8pd³DÃ†%&†f­&='†ì”‹ZŸb9†{É% '†…UIkt" Ì‰€3NØJdè\?Æ‰ ãDĞY,µhïA:ãDV*2TÃÑo„fj”ÖsÔP©Öœ¢SfEÂ©âÚrN¤1šâ3G	r"ØêÇ¬ú0/C¡ô[+Ñ¹~¼«6}ŸµGn–Z¶÷~œX›BpÆfÑfœq"àÈf©Pd•(f(ïN3Şu'À=Iq9%äÄŠ’A}îºÓŒvİiÆ'l%2”u§Æ•¼;5¼i,–Z´÷~œ-)—ŒİÀ8ãDÀÍ¢JS(GiúOZš.NŒ»DÑYáœëÌGÓŸ;äÄHó¤:×¬|õk(s"àŒ6ƒmõcœú9>k%‚¥íİq"HgœÈJ†œùDÒ°ÉgÔ-É†ĞÅ‰±÷4"'Í9‘æ¥*ÒlGGäD°Ö­…ú —¡P
ØJDt®÷rÓçØã“öXb³Ô²½÷ãÄhièM4[İiÆ'lV”§¹&ŸQwİ©á¼;5œ·…¦­È‰-‰Ø‹7†vİiÆ'l%"Ê»SÃyw|ÖKK-Ú{GN$².9ÖÆÍØpÎ‰G6£Q¾vœ:cC”ˆœj(Í81­Bñ¥Ÿ;'cT'i‹œ˜ŒU¥„¨Yß”9pÆ‰€›A‰ëÇ9±éÃ9±iœ–Z´wÏ‰M:çD,ªáÌo¾®›U´dšSZÎ‰I×åxêã™s"ÉW9eÇçÎ`¨³èÃ¼…RÀoP"¢sıxWmú{|Ò9±YjÙŞ;rb`‰‘¼èN3Î9±áÈfÔ ‚v§åDYwšñ®;nÅQ){äÄÚª²èN*ºÓ„3NØJd(ëNûxw|Ö9,µhïı81ç\Ã]jLÜ‰€3NØ,g
L™qb.ä	_'Dœ‹®ó¤DçÄ¢>ÎMË(S‰EÑxjŞl=PæDÀ'l%2t®ãDĞ‡q"h%¢¥íİq"HgœÈJ†ıVL¨9j©Tj®'mÈ*É”n=±â…føÎ!'‚] ~ÌZ ó20JA¿µ9:Õyô9r|ÖJK-Û{?N¬MA{jO¢;Í8ãDÀÍ*Jsš 'vİiÆ»î¸«óJZäŸK¤¢Èt™š)ïN3Úu§gœ8°”ÈPÖf¼ëNoÚC‰h©E{ïÇ‰ÅûîêĞ-€ Î8pd3”#j	‘£‘æC4SÔ'&GKædh†|ìi JLQÙH!ëû€r'6œsbÃ‘ıZ‰ëÇ8ô9r|ÖKK-Ú»ãDÎ8‘•ŠÕpæ·:!‰Îpk‘8µñ¥ãÄDÜcr±ãD²€	ú´g%6»`ıĞZ¨z9¤ ßZ‰ˆÎõã^nú9>k%6K-Û{?N¬MAÓì1™¾;Í8ãDÀ‘Í|Š¡8ÊºSÃywÜ«Œ6†q"5yS4w§íºÓŒsNl8²_+‘¡¬;5œw'Àgí±D°Ô¢½''ş¼9¯ˆšy#ÎåŸYÖÑ9I¶å$ı¾¹ĞÏ¿>}÷S:æ¿şå`^ò½^şóëoOT‹dµ_ÿ|ø­õ—<üú×'S´&ä‡$6äGñ7?<ö§ş#û"¸¬£Í	°º!VäzÄØ^î÷\#¿ñBnyALC‚P»¯°	T8
1~d…\Y!åóËGö\e„–&	Á½ùLş‚üø+u›7mÏv­=mt±™Å¾43h™Ÿû?™<F1ÂL“q°SC¦¦™zÛÆŞ’ørKïé0¬¯½¢ ©¥sbû’¥B?ôßaï¹±µŸÖ,¸}ùgÎ£ã¿¿ İ]Wè©İÕ<µÕvççÈs½</w4ßşÂtæŸ˜RÍñîêOD±²¦®úŠÉª÷Ÿ\ œ>Ğb_ì=`ûOÆ6B…J÷ÉD¦Ñ±ù<ôÃ—¡…~êõVî…šzílïº¾Çuï-b¿ï«*<#‘†u{Æ÷2DM{ÏÈBíeåä'ÃR.ĞeÜ–ûR.èÛÂ/¢Åˆ65¬éÎv²t <ôÜ¸ç])•ƒÓ$u
nnr‰fÕ¬ÂF‚2vhî¢)tØı%ı_ùpÜˆŞˆí7Œe—¿q»KçÚ]‰\½24+ü…à]1o+}`zıÔËğ}‹øÜÊ0¢¹‹™•¨Ø¸¦®—Ñ×Tê">B…Œiâb®0ª©ÇÑ‚C„Ğúb…v+Ãî9	ıE±¶ÿ¤¯©ÔeÜ¦¹ı ZŒhıA¼tîÃ·;,‡f\QÖeSêÙ–¢•Ÿ6' ?2<X•½)®®=¢œ5åüÁ³z×ÎÏ[ô÷ÍK´†Ì¡m®pó[Ï¾Øâ4Wq4ÊA¼(µ¸`gÆ6*Å¤mâ(ÉóÆ¦şÌ«êÎJ9S·Xb«ù²óÒhwüóJ#î~şs{En¡=¾iLé–ÆvS¯[\+AÔ`‡[@$×%úøÏê>~"§;"†ìç.ãe-„
]ÌÛ“yğÄ Ö¥*ºI¥¾m²AüÈğ˜k®9 `§<Wp”óAÈüS"¬ö¤sg¿ ¬.1”Noitf8³öi§‰Šâh$&wÚVe>€Óº5/Ú”|À›g°~}æ
¡#W4=>øüøœFøù¼ŸÏÚtá’Ï¯£äüu>;m—àœ¸wÁêÓ÷Ë#É™eS¹<'W#ÆësãAO¬F—Ze±×¯5^°Ô´Ç:¡X‹¾^Æ7Z%®xÛÒÇ?*f…úÃUb¹|µaqn(Tª/fëÂ•Vš¯oÚlÍÜìÉGŞ«Î¾‰%ÒsCJÑó"–ÕÆ‹æÂ½İ}èÿbÜ„™ÇÍn¼x?l!l÷)eØìÖØğ[H½öh±‰§Y#Ñb—\dOLâFÛ¼	yI¡s	v 9ÑX)ïYŠñJ ¶½VHîÖÚôZ°4µÂà§„²s2pı¾¦Äå'r3x<Š—_Ocß&P~G]àR_ŞhŸ8E6^îÌ•q«Ã˜-\AÓWÿs×ôJÎÙûø÷ñû	ªo#†>—fPZz‹È¡o‰‹°{¸7û*Y·»ß-¦!¢ê+ÃÂk[l¼ï.Ò.Dã~Â6âoUNÍ¿ä¯u}Ó"†Ò7]S¸Õñ*efW:nÚ‘Ø6LgşB`nˆ3.q³£ÃK³oµ¡˜XŞ ¥Ücüd}<ß¸¾Q^²!VzÅ’üx]ûú%©­¨Çp—GÖTî½óÅ—ºş¹Ç!±µ)|!¶6Ä_ô«S2‹H<Ü‹ODs–©s¼F7ÚsSòF^_mE}³Úe=J4šq)b8^¹~Áj¼ú&Zó†İw´a(6&ú}[©íp?äfvº¯ß¥~oÃŠ1¼ÿï1¬l8WòVAĞpwûU¶dä'¢úÈJ:ç¹RD/6o6l#o´KœD—×œ)ùm¼9ÌÍùR¯“î •¨úÚ™ÀsR7Äü‚vI‡44Şë«-tÃèfË‡­oŞ$9ûtÛ1F×›p­ÉÊ‡RœCüÈpH¦Ï®ğ$ìUå|äl8ÂÌWL!3Y{z}ÔFÍ„r‡s/€3c{ù#pÔ)[¼9]˜Î\ ¯u0Ü)c½ÊKl5_ÖóqÒæ~2³nw-í™íDˆ˜‡\İÍR†à{‘Ê<>‹Ó›™¢ÊsË(+ÙçjÚ«?åLM¿ôŸôk~â°Òöè…sê¥çúR¤=ö[Í:§mw´˜øDøeŠ²àğòÛŸ«r>ß›êÛaFGåm9Ìiø‘á‘h­}ºŒå¬á(çƒİWÖÿ“òhQ©çMÓ×ç0£ß]Œ~eÏs¦®OM{æ®¿vP¦ÁõŸ¾Ÿ˜x‘™ñš„˜úrß”!£¥È·xºF ªlcˆ.#~dxŠj:èÈ™pG9wÊdbÈz.ÿÁ÷ÇÆìyrÓé~…Ä÷q.ô€øF"ºßò¼€$Å$BPà-^}Ê	[Ec”u:†^/Ø×É×Ûrî”ğ|Nj÷ùAxwIxÎìIxß$$ôçúUqºbV^|kÊ›òa±ªè”Š=ña Ş3‘¼øqO³å@¿ŸÃ‡9Wp&çNù0
 kşåƒï‘Ã ?	¼S‰Øn!d,Û_(âÎñé´«„Ø¯UŠ˜òBH¯³2õ½ğún•ñQùÓKˆnJ&ÄÒí.­â(çN)3Ñ÷Ôsâƒ2ï’2cyÕ9ó2Û4‰–T,&ë‘SşñÜ¼'VyØ7ê·«ni­S§°³>.gR½R3yS?2ÜEU7rbìuG9„i?¥ú 5ú4ëìW¯­Ï5õö«ŠÛSpßpfm¯\15Œ¡AÕ÷ŠK}{ùÀÓD ¾»Ûû&Ğ¾D{À›g°~}æ
¡#W4}Ü‹wO#E^=rô­F
±@!†±b!†…~ÅB,êŠQAõrhxõ§xÇë"BÛ†?ºv“É³Ö~]Åßå‘†÷s#Ù†SKãKí¶y3[^:I¬Näˆƒ/ıVÊ÷ŠzooH·—©Ò¢aŠºS”®Oßt¹8Õ%îAÜpyŞØf¯ræt˜Ã=VÎıøöñ{*ÊÕ°úª­yV!F¯?2¼.»`]¿¸¼†£œ¿CJ13_ÖEek)Jæj#fB9ˆC"3àÌØFåXß=à¨VÁùĞ?ğë3ÅòÎšØ¥Æù\Ë'§FL†š/ëùH¾£àİ†]ƒ÷GêôÒ€ğH^5ò©Óï"Ú__"ˆ©îX”úšÀËãó€uÂ¯»‰5œÉù ãğÕyĞ5;ÒFOÑö±cqoCYúúBõûIzùk9oCwBâäJö'5Î’šC]<ö.¤n{`G9wJw®Õ´Ù=èî.é®¬_şHjşö„g½*5Û$œÎ¹yb¶œBAüÈp—Uğ)ùîeÁUåÜ)áùÎU®{Şı£¦¿áİp__îxI@>kr„èµ2>›+!Ö÷\2Ú ~dxp*SLîˆoG9wJˆ!åzé…yâ]¢ÛõÚ‹-TÕ3“ˆEJ„œ$÷m/*ò8>|gCPu)¤SàI½Ã¦âG†G*.ÄÚ_8Ÿ®á(çNy6¹xzıàÙ»äÙ°ë’İ=	•Ü¼4ßçÌ;iB¶œÏ
(-E”ˆ½25gµ»'aG9„ ?ÅlUÈ©n–tö‹*;{ÚâöËÊ„D®@œYÛ¨èŒw£–•dr½‘ùÀPP_¢¶½oœÒ¹îc°Äæ¬_CŸ¹BèÈMÊ÷Dài×ûŞïqhÉø—¾µDá3Ï]¹º7Î‚~\¿Ş$^‘¹ÄâÕ¤ñ›Yq\!ä³˜~ˆw¤„?ÅóçÃW³LÈw¤V’©AF|HÂfB‘*ª.>‘º¯—ÇD3Ÿ_“õXy>'#„sE‹6Ö¯÷Ş)»3Ú¨jtRNk”Ö+íêÿ…8…'¶N€KÎqC?zç©B“Šô“Ö¥ñ?Yš>×Ğp—TJ¾¤Ó-7ˆEÓËdıK¬«œ)°Ö¯¡ÏLŸ†³,SÀ!°…:×e™‚>GÏÚc‰`©E{ÏY¦ß*n¹ÍĞÄû=C™ø'&pbLø"ïqåÌs¹óo“)ë!6J†ÚµGÔÇ»/7|tÊ§¯¹N"»œ{pä¥×xyà=?À<>ç3~éuŞìŞãIˆáã\k‘À'â0İ†³C·øFğáM–É`ä·§Bc²õY'†^¢2E—ÒeŞ­â(çƒ,“aè‚æ3V«z:Çi®6âh&”ƒ8LgÆÊ˜¨‹á¨S©hçR¢e¯JNÅÚŞ5NÅhMÌ,Dk5_ÖóqèÖÈÂ®w¤nXWû±ãO6¼ˆtñóVgÎÙ·?MMÒŠñ®fÒ„-N?~D<£\	&vY…k8“óAÈüSª§k´¯4Èí”Õ%†Òéíb=Qtf8³vV9FWŸ[kšl«O·²0¼ºœj•{ßhål½Cå %‚g ~€>3…˜#W4}ìyÜŸïzìøxàÚDë†gÅ!~İ'˜rİÏÍŠŞE{Ìh/I_û¡ÈOú~Ëç9ß¸˜°ú^¼c}Àˆ—¯?wD÷­F÷-o2
.jè[0ÂXĞïtAá&wa£îÚP˜èÔ+Ï^<·K·öp%,)Ñ<Kÿ'ãMÇá^ŸƒùA3¯“.ÿÌ·+ÆO¯+tò©Í«>õ™ûÔ¤Ş©&ö^5gF„iÒYÑX„ç_Ìk…£œ 1bı¾ïtò/ä¾´ÜqBm12DQañÑBQ+»¬2à¬Ş›j#Ë~¬=W¶¨ß4¼£àŞèbÃæö»ÚŠéšo3Ë&B{şÜÿÉä0ŠfêiIËı”Ò§¼/|Ô=å2aÑâ£)?U²¦qçjó}¯%ì’½ËMÜÕ‘.ÍÓÄõ2/Hƒrˆ(eà^ÎCŸ-Aòoiõ3€—¹ŞSVÌ^6„~ÂSã­Ô]^Å—áovÆ“ë­Ò(+	VHk©oşt^£'GUG•/ØKPÇøöÕñï˜\ì²r7Ú<EólˆZIM=gy1Í3¡`±ñ%¦BÆ~ãŞúæ<¸™†=ï‚\­±İÇ+8züõÃÉ†»’_g ßã*X)c<oXÙ_É+}·ánà×$$[Ã×NY9—ú‚±/ïeúEgç?>™ •¡œâ&e½ñÅrÑõ	„š‰ËPK?ú”mMÊmxÑFiŸL9ÄEÜ*—l	æ %íTj3×P–ğ8Ë&vu¡D†ÎõcÙ$ Ï‘ã³öP"ZjÑŞ„ßÓ¾\Jf­½ËŒWq§H=½>7WŞÒ)„Šz ï»Bè!^u‹ëJîâ™[\ÇùÎò¾Y!TŒ²â‰4q1ÀÚ¨zÃGOI-äo¸P8Fl‰+ÇÃª¸¶_„‘¢¦Ã é‚5™Nl€Æ¡ù02ÙòÁûØ×{îrd‹*‡âK½íİÕëÖu2uømø‘á¡(µİÔ«8Êù iU ù|Œ*ØTráj#fB9ˆcTÓpfìLæÉÎ&¥£§<Væ‚L¢Øºô®‰ª8ïJÀ¨j¾¬ç#Görª²7œ™Ï%‰Š(¢.æÌ31“¼¥ıÒ%(V\„4€ÄÛ†+#æ.ATZ·Ğ8Í¯ì8~ë€øÍÒ/WÊ&sÁ½WÂªıF— ÆnÉDki açaÃÓ½‰´ød(ãÑ"–+ò¦¡Y44»m}ˆÇ+"X]Ï, ~dxò*ÆäJ÷^Ñ*r>HhöÉ‘²üëmg?£"EQÅÆÎ~VQ|d]fö`Ö¶ÊĞÿM0ÔQ\æëE”ÏÜ¶ªœ\ì}ãT(Ö}À›g°~}æ
¡#W4}d¼ßSt×—…>Rt¶yÊÿ~WS±Ê¼ˆuI*–LRêó¡¦3ÇFdwÍ³R¦Œ)×{ 3¦ÄGÓ*Ü¹T,)XVF¤YñÛ¥2²è)ÕM„X’H¸MB®ÈõÅÁ÷·?p.kºØÌ›â¹‹ŠÆ×Nõyœ"ßùu.L÷#õŸÈ+„„.âN¡áAêq3—ná™R®œş½<b<üüôÿqq¬¦endstream
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
xœí]]d·q}Ÿ_ÑÏLñû0Xk)@‡ Á:a´Œ(~ÈßOñNÏ­sÈÛs{f{g{g[B¢İã«È:U,ò’ßıóÏÿyøï¾ûğóÿ>şûáçkJ²ÿú¿¿GÀÇCuõğñ×‡ß¿=üôğ“üÿßšxü…|üûÃw?<"?øWùÓÿüá_äo;üûÈş|úõş¿>_Mëÿùëÿêlª&7£àvükÿá¿>üÛï—~XS­õ®¥ûBÿ}p%[\]WwZõuË¿ø«/ìƒ=„–Û¡9i'øpøßÿzø‹HX»fj>ısöÏ(=›h]IÙ×CŒ¦:ï[ìÆÍ±™RªÏñãCNÎ8Kˆçä+µywˆÉÔZ\«Ğb¼ó-ù|øø xj‚gS^Ú^ñlMŠ®æ$fg²ë)mkÿ ıˆú ~|HbÁÔlñh¬u¶•\P" Ğ¿€ƒ>GÂU{ˆ–Ú´÷G™Õ¬ƒ­÷‘¨bQ5²Ôn›]±q·bš€)EB«H¡¹e$OE¬’ªÍéÔö^Ml-ÇnP•vş‘µ@åbœ«¾åD8Ø%ªı£Q}„«ö ,µmï>ù¸SË5û“=ûçsî”¤Ã>9iŸİIñ>å­ÉÙ»H?ß§|(µX™¡Ù/ÎŞç9 ìN+>¸ÓŠËävÂÅ‡A¢ Õå\c!wR”İIñîNI<5•š—	mĞÕ£?Itp§ÜIqÕ$¢¥6í=â«9Qt0Õ—œ"àÄ‰€›9ëL³>åÄh0Ş×à-s¢´c|pÙæD1ƒI©„NV Ñ‰cï‹ÃA”pâDÀÍ@"¡kÿˆAŸ#ã«ö(,µiï¡uâD’
8[0-Ææ=£2ç|•®1':Ä*b›Èœè\”Ù˜DAäD°ö­…úà(Ca+8n*Ñµ<ÊªÏ‘ñU{”¨–Ú¶÷õ8±Où‰Z'wZqâDÀÍœõ&Äk`”ÜIqv'À³Ø ‰9;ÚÛH<AÜiÅ‰6‰„’;)Îîøª=JKmÚûŠœX¼¶—diDÅ™G6+2½â"„Š1bµ¥œX%B·7pb­&•"¼OœX›‘²¾Ñ *Êƒ¨8s¢âÈf*‘ĞµÌ‰ªs¢jÁR›ö9Q[gND©ÈPŠÓ¸%ñÜ˜+GYtÔXe‚œX%Î&Û‚8±J¬±dÊÁ.Ø?´êƒ£Œ­à¸©DD×şñ(«>Ì‰ª=JTKmÛûŠœ(S!‹ar§gNTÙ¬D$gîK#DÉgw\Æ(Èœ/Ä‰‚ŠáªãPªèàN+Îœ¨8²™J$”ÜIqv'ÀWíQ"XjÓŞ×ãD!jÓÇ¹DÀ‰6“Å i¡äFÙ£#mÅ˜˜}” ‘s	•9ÑËÂ25[@Nô=?–n”ìJƒ8q"àÀf ‘ĞµÄ‰ q"hÁR›ö8Z'N$©ÀP€£]mÕÚX&Î¡ÖÈœè£„Yq–Ö˜e>Jş,“4#'‚]°h-ÔG
[ÁqS‰ˆ®ıãQV}Œ¯Ú£DµÔ¶½¯Ç‰}*ä¬Í£;­8q"àÀf>XùcË¶1Jî¤8»àÑHæJBNìhÍEİiEwZqâDÀÍ@"¡äNŠ³;¾jÁR›ö¾"'öH\jÕ	¢âÌ‰Š#›I”/)ø³ *S°4ûåŒ­2¯sbD8Ú*ÿ"'I¥£ÌîJ2@i'NØ$ºö9QõaNTí‘ÁR›ö9Q[gND©ÈPŠÓ¸USZÊ™²gÉ¥ÅÇJà­ŠU$¼ç[“PŠÈ‰`èYô¡Q†ÂVÀ. Ñµìªªs¢jœ¨–Ú¶÷9Q¦B/– ;¸ÓŠ3'*l&™•tÒ5fJv§Ü‰ğ–³Ë9±OùÜ«7‰İiEwZqâDÀÍ@â€‚;)÷±;¾jœ–Ú´÷õ81ôH,IN
 €'l&Q^–=¹of *ÄÑb´C=1¤l:›´¡R1ÑËoQ=1,å÷¸ (¢âÌ‰Š#û©DB×ş'‚>GÆWíQ"XjÓŞ'BëÄ‰$Jq·¾‰ã¬Œ
·XÃPO)ŠUŠOC=1¤d‚,ŒÕÁ.Ø?´êƒ£Œœ­à¸©DD×şñ(«>GÆWíQ¢ZjÛŞ×ãÄ>dÕÑÆò<àÄ‰€#›õÌÊÙ”#£äNŠ³;ŞªKê‰}ÊgÃàN+:¸ÓŠ3'*ì§ÜIqv'ÀWíQ"XjÓŞ×ãÄè‚).$;î;+ÎûÎŠã³‹¦ÈJÆFF{É5º4Ô£(úV”gNŒb¤K(Ä‰’[›âeÍI2@yGRqâDÀqÇX%ºö÷UŞwVíQ"XjÓŞã¾³¶ÎûÎ(÷§qëÅo[2[Ë‘Sê‰QZ¦¡«91ÊTË6YOœvÁş¡µPeÜ†VpÜT"¢kÿx”UŞwVíQ¢ZjÛŞWÜw^¶ŠBËó€ó¾³â¸Ã¼ìJHå%wRœİ	ğh¼Mb%äÄ6ïí0AÜiÅ‰Çc•H(¹“âìN€¯Ú£D°Ô¦½¯È‰U”Òƒ:¢âÌ‰Š#›I
k%|G’àB~ôDÀû:Iàf™…(úÈ•‘“¤éÂZ™+d€Ò Nœ8ºQ‰ÈqÚ?æDÕ‡9QµGNKmÚ{äDm9¥"C)Nã&M&8{ìh“5gq$«o¸eÍš½t²'ª]°h-ÔG
Z»€DD×şgqV}#~Ò%ª¥¶í}EN¬zƒ,'wZqæDÅ‘ÍúŠP,ÂÙãàNŠ³;é™ÜB[µÖR‰íëŞ²tp§'NOİ¨Dä8v'ÅÙ _µGNKmÚûzœ˜¢(':…'NÙL¢¼õ!8Ë¨ˆØlÃùÄ¾NJ^òï%ÉÎEÖ>8QÒô’‚utPDÅ™GNT‰„®ı#N}Œ¯Ú£D°Ô¦½N„Ö‰I*TœÆM:–SÎeD[lÂÃùÄ$YkrÍUæÄ$kÖ,ú§DçÕ.Ø?´êƒ£Œç¡7•ˆèÚ?eÕç8â'íQ¢ZjÛŞ×ãÄÔ[qjŸFwZqâDÀ‘ÍúŠPÃWFÉgw<K¾•]‹Ä‰}}›|iƒ;­èàN+Îœ¨8r¢J$”ÜIqv'ÀWíQ"XjÓŞWäÄ&ÊeY<EaÀ™§SØ2ÙBÍ¥0Úëæ’:{,ÙÉ¸ÉÏ{,Ùù^k‹e8³zµ.Tª:œÙ^ñáÌöŠã™m•HèÚ?æDÕ‡9QµGNKmÚ{äDm9¥Ò	ê§Ã·½ í,ï±ä¥ø-yØcÉVş˜‹÷X²J*<r"ØúGÖ}h”¡°7•ˆG†×şG‰W}#~ÒN‰¯–Ú¶÷9±'¶9´qpæDÅévßZ²‰÷XwÒ³ÙìN€û~&-Ù¦ÙTÔpJÜiÅùÌ¶âxf[%Jîg¹É _µGNKmÚûzœØ)©•æÆ=À‰G6“(o%Š‰ÑÔ7ÕËãI
À³$Í5Ø6Ôs®¦ØZy%géT’.Ğ *Êƒ¨8s¢âÈ~*‘ĞµÄ‰ Ï‘ñU{”–Ú´÷À‰Ğ:q"IE†RœÆ­´s´~D[•\¶œ˜eé!JC=Q&L?yì‚ıCk¡>8ÊÈ‰Ğ
›JDtí²êsñ“ö(Q-µmïëqbî‰mi!ÛÑVœ8pd³ekIH!0Jî¤8»àµŸi¼ÇÒÑ¾×wZÑÁVœ9Qqd?•H(¹“âìN€¯Ú£D°Ô¦½¯Ç‰Â¦5å¡ 8q"àÀfE¢¼Í-ºÀ¨ŒOK.õÄâ%inÂC=±øhäÿdè%¾±›sTO”pâDÀÍ@"¡kÿˆAŸ#ã«ö(,µiï¡uâD’
8ÚEBµsò«vD[KÙõD™‚b!—¡X¼äÏÕÕDõD°ö­…úà(Ca+8n*Ñµ<ÊªÏqÄOÚ£DµÔ¶½¯Ç‰¥'¶-Jf;ºÓŠ'lÖ'”äÌ!8FÉgw<_½oTOìhkµr(tp§'NØ$Jî¤8»à«ö(,µiï+r¢Dbk[-C=pæDÅ‘Í$Ê”j-&:›ÂPOb<T?Ôå×M+Uª'–êLu1V*€ Êƒ¨8s¢âÈf*Qís¢êÃœ¨Ú£D°Ô¦½GNÔÖ™Q*2”â4nò‹¾¸ÀL)YòÒÛ¡XJY>®C=Qşcr¢z"Øû‡ÖB}p”‘¡ °HDtí²êÃœ¨Ú£DµÔ¶½¯È‰2¼²v·-ÍîtÂ™G6“	•zÂÅLÉî¤8»“â2¹½LĞLõÄîÖEi}t§:¹Ó	gNTÙL%"Êî¤8»à«ö(,µiïëqb•Hl}òq(€ Nœ8°™Ä†şõ÷ãj Ğ`¢Šê‰’sŞ\ê‰5ô³Ï±Eª'Ê‚×ôÃÖ|« 4ˆ€'l	]ûGœú_µG‰`©M{œ­'’T`(ÀiÜ¢‘¹šlbT:Ö¿ê‰5„Çï†‡zb’?;iœê‰`ìZõÁQ†ÂVpÜT"¢kÿx”UŸ#ã«ö(Q-µmïëqb^é\ÌîtÂ‰6ë*Eosf”ÜIqv'À³	.Ø@õÄîVì&w:¡“;pâDÀÍ@"¡äNŠ³;¾jÁR›ö¾"'J$¶Q&ıPOœ9Qqd3‰òò¿&—• ÏC=±6'xù'6/âÅ¢TO¬Mü"&ï© (¢âÌ‰Š#›©DB×ş1'ª>Ì‰ª=JKmÚ{äDm9¥"C)v‘PídfÊÖ£üÚPO”ÅXEê‰µIşÜw©vÁş¡µPed(hÇM%ªıãQV}˜U{”¨–Ú¶÷9±'¶ÑÖ`gw:áÌ‰Š#›É„J©ÄÀLÉî¤8»àŞ_C£zbw+ØÉNèäN'œ9Qqd3•H(¹“âìN€¯Ú£D°Ô¦½¯Ç‰’"ÉÙT‡C¦€'lÖR?®”¿TÔŸC=±å(xLq¨'Ê6=l4º¢-Õ÷ä¸ ("àÄ‰€›DB×ş'‚>GÆWíQ"XjÓŞ'BëÄ‰$
p´Ë²‡#óÈ2*!»\‡zbË^¬"˜¡(	€„êÒÕÁ.Ø?´êƒ£…­à¸©DD×şñ(«>GÆWíQ¢ZjÛŞ×ãÄ¶OÿZtp'Å‰6kËKtQr'ÅÙ O’4KFGõÄVéYÜiEwZqâDÀÍ@"¡äNŠ³;¾jÁR›ö¾ê]a¢øñP |¼+ì	§[Ál?¯dkĞjîÅ"Ü[Á§3Û‚»ş1ÃiÉ°J\Êï6QĞá©ç{q§[¾V‰Œ>õo¸+lÕg¸+lÕï
[-µiïé®°µõá®0
8[ßÄ	~D…Š%#NÌ‰B6uùpxX;ŞLÊ!ğ]ajêX‹ôQ¦›»´´‹J$ô©Ã(¯úw…­Ú“ÄÕRÛö¾æ]a¶Ÿx{Mîô„w…­8İ
f‹	Í—EwÂ›ÅĞ'ÊW€Ä¾Ü¬–×Î€îô„ó½8Šó-_OEwœÜ	ñ'íI¢ZjÓŞ§AüéÕ÷ãö-ó•8·ÿL·ç^ğóx·®×»u{µĞïyøîGQ;~ùËÁ=Ş[üøŸ_~}H¢Z¿Ğá—?ş`mÈÿtøåonùÄ}X¤@]€ª@¶ ñü¯Ø0şÄø+öÇ±Ñ3müğ‹ŒŞ—3k5›v•†µ~Ô'€² A5çoÁçf–sM0úd‚ijÓÂ»i~~?şÎ8aı#PÔ~œlcÏü{]½â±e×µ~t™”;M£r¾c¯htÖvjãÌt.Ïİ4ÜãĞÍúãØ»íá%fßïÙl€I½iì&íF3O}¿@»©Ñ?½ÅÄœGwÿôhC?¶z«ü,q/Z{–ínŸH#·ÍÀäŠöltÀ%Å#í;ã.¿mÎmüq—%'O›¼ušò#ÓÌÊ]÷m—œw9ñ_ÜïØEŞu _-yÀ”Ä8Å?òqS Àô;ö‡áG¦ñ
ÆFö{2#ÁíÉñiÒg¿ûÓÌÍÚ]¸BN²/Å‡±ÑØ÷¥)àN®šÎéŸhj¾¬Bà¬,Y}M¡õ×¢ó%,;I)ô<RJqYiY]×oF<oZ”e¼íoÄZd¥Åg2 §g2¯ò'—–ÛUb¶FX%æäĞ?@?¢>€š,«‹\şyü J%"ŠÏdĞgõğL?}ñ¤=HKmÛû›ª„ÍuÜB‚qˆet  Ên”û°9À¯ŒRÎÅ°çú1Å0;¶1ù©cS£eœ	áÏ1Õd 	ˆ#0ñĞnÂr Ÿ¦~ìÔL¡SÇş´;P£”ğÃ^Çì4r×Kñ±zØ§ÌÂ1Ï“´Çüâ”Y^Ã@/×Åm¼§I÷…ÆvcÃŒC9›pŸƒ¦ÅÛÄ0»L÷ŠÁ¾€ù÷£Ç+†rü•‹WbÏMËi~ìòÇä·§ÜZDÅgìq…•gö¢-ëŠiZWNº[¯|£ŠÖ­€wW>³c¾¼F0K9“è|Ú¶Î4–“=¦²9ìX\imÔ_	Š¾Ğ_ÊŒòg]®ˆJ2E–/Òâı¡YÒ”ôø¸ÖroWdËBŸË"<š–rë-€D'ë‚àjğìŸ¢´6œÖF€ÓãZ«DBá¹,Ú¾†ç²†'°NÚ£DµÔ¶½ïk£emäÜ2†¯gm´¿â8Cİ7™\\#ÓX¨›ƒÈÈfs x£]À	w®±:¼×„/ÛÕÎ…çÑX‰â÷léi%6YmÚÑÛ˜çÕ”GLÉèÍ&E‘¼Æ¯vÓ•ŠÎ»IÑ5wFß|w¢ëWtõ5=›¸h²Ù¸òãúíõ>t£4²£üD"l6î@y›	£İ?ËTed•™ˆ7„İğ|+;Ö·³úÜ÷ÍıóDû+Ç}~›r­ı(úeÏµ|Ş5m_'ö'yúWğl.àÇ‡Ó›Õ1'Äá}k'kĞ$ÊQxîq|î”ğlúçş§Ç~Ÿ$.]»Ô,>ë(¯iç5­âô8ê*‘Pxî”*…çN‡'LOÚ£D°Ô¦½ïkÚeMëíà#ïcM;%šSœ¶öM|Æİ¼Î^|¸ÿ‡ÆÁ°ó©ÄïÇìd:>íkL§Ï¬‹ntª9×Ø&·›K}–5ê5
Jû»¥“¿NŞ¸4}ÿÔáœKíûzÍjrÿıMêyBìŸ+ß×w*ÓíSÚîé²yU7ulšËÓZù
ˆIÊgHƒûÃ¾±§¡ıŞ:ß‡I¶	?
Şoİ+Ş:Ä}ö&
h_áN¡º`…®Ç®	ï74ö—(qyÛ 7I±ŠR8¥Á€Ó{Ø«DBá…kz^¸^­>iÕRÛö¾§Áipy—iğ­{›ÄNõ§3t?­÷#IÏ‹ıBG’ÎE2hãÒ{7šÌöuS°÷Ã1§Ôßâá˜¯eeÖóœÎóg,û¹ûË7şæ6^³iu…Øsµ¤gÌ‹¨İ¯K.ØÅ›ææ¾úÓÂdêé.‹ÜÆÜ,gæfhLµ'}Úh˜¬ãìuÓÄÄ=7]£‹¡²{¾âî3³ñF=ûü ŸJ_éüÚÉw&Ä±¤6¹Öº·ãK•Eiœ4‡}­&¤P\a´-—ã,/l!¾<fäêrcáMÖ{%G‡Gƒ•U`¿4á‘F@iİ8­{Ç«J$tí¯{U^÷ªö¸îUKmÛû¾î]Ö½ı‚á‹W_Ïº÷=i%=éûy4ÎùÕnfBç÷–ì×h÷óË©ÑıÜhÊâŞ¦Š?‰¬~iõäÓvİ¾ì9ÑkÆÙƒñ-ºj—cÍøà‹ôğ£L|kRªıÆZÀ]¿py<ZĞhä¿¶&F“É-ÖĞë´ˆ/d¿ÜÓOx’˜+Q|$&‰ÄıÉ¹~ş_û§(ÇYÅ9Î*$ºöâ,èsd|Õ%‚¥6í}³Kœíwx¾Ã8û6Ç,>cõø†ã}ŒOñş~îâ…f}şÜ…ö[½¬M°_wÚÿ*åå™ÂşÕ|Ÿ§Êx†Ÿ=zÁi†K*Ïå£»9í¼ÿ6î—³˜½ ÉböÏa¼üpñ|¸ÜïÅ§ıSÏ3°?Ó`ï—¿ÌÇ4Ÿp„æF)q	¶ù‰/>Ìs«1Î³>§JçtÂühŠqûG	§6&«İ„‘Îyql£wM_×n£Ë™Ææ5Wô¾b(&»Â>ï_·íç~Íi¥ó5™ŸåìÀt¡ÉË3‰X25²ûÚ~ß/([b€Zf"Nz«“ş§‡Ÿ¿-?"$âûsòOïÜÿêlê ÚØk?vükÿá¿>üÛï§kë\êOËµĞß
Ñ›(Ìñ#á]œ+yÜ9‹c;'ñoU“yŞ¢×¹9Í—£3¥d›«8š	ÛAïTœŒİ_¢êÏ0šûÓÖ_0EWLq1µ2M6¡ÖùÆBíù¶ki­OÉ×ñÊSúS:róñFˆÉŞ\ñL¡à¹Ï¡ŞÓ™Ö¹Êqÿ.²«·¼4zf°/8};µ1ûE€KßExn¿2_Ã8~~5eÙŸå'¦Œrë“‹§‘oE—iäâ‡/Ÿ„õ+]í=If‹ñ”ûs—Š	Ñ8ï$"ú9Ûy'IØïƒ¤;±¶Tìh¿hjYÒšÁ~ÙxÛb#{µIMşõ’Õ’ûÇ64’ÔyçjÇ¦¿Vš[èç•T¢öOÑ¬äM÷<ìÊÃüBóŸˆÌ_uLmì®o…à/°Ø~8›ÔßO»ÆFç¯\Æ9ïcOÏŒ¹ËVÃ™bûs==SúâckG…qgå*£¿?Ø§½8÷½<sß?èp®-ªö-”nô{¤[İHIlµoğ°@ól/zVàªï¬ÔlR±ô—X›3Ş'Û?ü(Ú›”l-ğLö)×şVp-&ÛªgT’µ]èØoÅ”Óã[(ˆ÷7t}°é “µÆ…âûkãÚ?@é@ àTµW!*‘ĞµÃ;+«>¼–í¡j©–Ú¶÷ı@àcÙÎG½o«÷Ïêgÿ™¯¾ŸÕßŒ´osVÿV×,Í½o0cñ¾°	ŞMÊ’¢$‹cêß0ôËaB­© ~ÜKK±Xúy×¯	-¹,hO<B‰ÑhzuÌöïâOÁ”äš[®¡D<õˆŸK8 Ä”K>õĞıS”SÅ9eQS‰„®ı£”ô92¾jÁR›ö¾§,KÊ’ó=e9Á¾Ìí’ï²L‘Û×{İä~Ä÷Õ†»VMÊÑKŠÛoy·U´AüØojˆ‡&ÄÖÜ×Ë²ÒÍ¡9WÍ¶w@Ö¯}¥Kx3büòi<âÎÛB$fçë_¤ÇôP~	Uq~	UqT Qí…;Ğ‡ÃjáN-µmï{¸[Â]¯ÂÜÃİ6ö>î·ÈmÜÈ>ßüHç8Çì8?æ©É@S?vw‹.òë²»76÷t×Õog³ìåN÷.ÓÒ’ï»g/ß=S«İ¯8ÿõ¡U6É»IÖsŠ&•––û5`»
pÚN6ÂrêÄX#£Ù´*,Sy;-çdJõ9ŞNË¹ô¼=ÚŠÛi9Wãj’Şbÿåd]qNÖÇô[%ºö“uÕçÈ¸jÕRÛö¾'ëK²^oï“ûvÚUH³‡‘îÛigÇ÷¾öY·Óê3¯´¼ûŒÅûÊ&x7)K‘?§[,¼8m§aÅõGZí!ÚtHÙfŞN+Ş™Òc¿ãí´âƒq>”’p;­øh\«¹4ÜN”RÀ)e’HèÚ?JY@Ÿ#ã«ö(,µiï{Êò˜²ÜŞ“ïz;í^ÈXr©fßÃşÚÜÓ—§0¼ ğâNÎ&;ÜrŒ#dSCIÑ".±!È:3‡Ğ<â.ô‹!«k½•bdµ+LÉ¨Ğ°³­,Ç8 /ÅT!Ñºã@¼ù«‹á€«Ì-mçoèŸ¢wç¸£8F•HèÚ?;ªÇÕ%‚¥6í};KÜiñæâÎ~ûıØ}cçVöµŞFÛÓŞÇ-¢rvQÿš[pŞÓ•67ó|ùÛDÙİ®_póá+®Ò:ón×‹´ÿÖÏû¯“„å} uçoğØqXŞ`¼›:Iõşqk¥ŸÃr-š¸|Çƒ¸ä”-IízN	¸k’=JîØ?3òı€”Mµ0šŒõ¹¿A!9%à!˜êkIyiğd\ŠIÈ%J’êûmãñ€ıS”òUÀ)_2MHèÚ?ÊWAŸ#ã«ö(,µiï{¾ÚóÕ$D}ÏW!=yëcFTAvk>_6	~Ñy—ë]ët£±*uŸŠ7zšåTxj©&GgS?Q³‰>Û*âŠ)±¥”
âµJ\‰!W	B¥™âRëBZ±Ñ»TJo¦ÆèüR)¼9ãr”Ø¼ñ1‰1Ø?E9b*ÎZXÕşqÄT}8bªö(Q-µmï{Ä|Œ˜õ1/¥ê¯î0Drn-à—±Ö0v2­i¿hÿV—°¥‘a¿Á¬s™Mğ…V°¯ynàÒ7lŸ93ËİÿkŸ\v_	aÔ.ÆÉ§§#O“6“Y'ÃŸ!uÈ®öOÂß„Ÿ}X`œ¿>46m/°¦Ãe0+Â…óØc#pæFûy·ó€ŸfÎÜÙÑ'J‚¦ß	Óô;I¾Ña_âz<)Lçøf•gÃMCFÃÍ3e8NÁyb¥x¾ÕyÀ¦á™<m àúæÛsİÿ°û;—L„0=~Fçk.[r&f'ëŸµ&ùZv)#~ÜÉ
Î÷É›*$‰iòGYÈ´à¦f——ÏCÏŞä¾BrKÛ€Ój«©?©s26Ç’ûó“Ú?Eiq8-‡eH$tí-AŸ#ã«ö(Q-µmïûâpYºr¿H~[Ê\¿ìûBÉ¿şÚ§}a8©?Y}ìÇ|³ê5¾R¼ à<•&1»¿rÁAúW—´éšØ\jÜİI6¾_ñIî$eÿW&_O»mì{óo×Çª¾sŠİ—§.ø\cÿLÁ4÷€»¥ñùÊÔ±é Õş½(7r²å»Ÿå'l¾å='ë#Ùìòº”·’Œ¦báGÁ›	Õ·à÷½™TJèŸCÈo¦äüˆ6S%í'T	wÕô›azúK¸·’'ï$Ñ;Ó¯ é(ôoE?²>+Ni;àpƒDB×şQÚúüI{’¸ZjÛŞ÷´}IÛ}¼¹´ıíéœ‰uŸ&åL¬ƒ_9ëËÒ§6¦„zÊÊ¾s÷Ïis¿ò”ûÍµüıåÁœ†LKŒ—Ÿ~£(;î€½æ±õéÅÔÉ'Ng´÷3¹ı<íåo»r’1¼ü³ü{ùãK‡ŸşşXQ^endstream
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
xœí]M$7r½×¯¨ó¢øıV3#>4€†F¯ecQZXŞƒÿ¾ƒUÙÉŒÌbVMõtuw­€ÕÌS%Éˆ ƒd0øã?ıúûÿúûşÇO¿şÏşiú÷§_wZ¥ OÿÛ×~@Àú}6yÿôûîı»_v¿Ğÿÿ±{.âôÁßŸş¶ûñTøî„üúé_èOÿ··û¦¿ıuÿoÿNÿúËôyıÁï»d³*õ‰şzÀ¿²ŠE{O¸îÿZüß»ıÓşoÔ­²ÖÖ”àÂ©-ìï?xë¼JÑ¤£ W7ºÉkÿà§¶Aïƒ-v_•ã¬Ûÿïî~£æ¦©§ÿ­şkÊk“B´ù¨Óè‹J)ÛèjŠÁ(£½1µ!1XE(–jV:yR¨ˆZ*KÇ£Ş?íğ×şƒ+ÁÄc‘*Ù’t({¨ÈDßG£íZè6ğÃ.P³BÑÙGÄ½ÒÚè’bÂmí{Úòé¡FRêò‰úXV³¡¬ªåL: Á<¯£Ê«ÉĞº ZpÊ˜d£ñQhÚZĞXÒÆ†©ìgÜ©˜“ó9í¡FĞ´éäa6MÔ¬lKG+A€¶ö1›‚<ÄAz¨4µ¬ïj‰ßş#¤ÄmòA¯şym„ÀÀäcşCíâZÅhç_Ô>îRNÔ%"ek]F´?í×|ü4<(›©©–2WI=_kïŠNİøyFûñóŒ×ñhh†”#âd04o°FDùø™ñnü´ß7é¡F¦ªeK^Íu¦ÊçLv–pÆ~€#ê‡:&9š•wÖÃiĞjj@ˆÑkNƒV'Eµ»â‘­ÎŠcKF3ÊÌ8£AÀ‘ØZÛÇhäá4Ø¤GâM-ê»#F(#«iªáÌnEâäªC$@MµÚâ4'F«©7R»´áÄh5ÍÔg#FĞ7j‰­Œ4¥ İZˆÎíãƒµÉsà½y–©¸ijYß·#Æj^²­ÃiÂ-|F*ø\ÛÎP6œ[òáxRÎkŸ"²b:$J?œ&T§	g¬8ò\«‘¡l85öãÃ	ğYzäaĞÔ¢¾oÇ‰–:·Y‡È8ãDÀ‘Í|í‹Ô™ÃhÉ\ ã;NŒ4I$«ÓÃJ%¥h'FÒy 12#6”±áœì×jdèÜ>î6y'‚ôX#hjQß½³ØJçÎ"ÖŠÕpÔKU\Ô»8jé³b‚ë81RI&ÄÜqb4´˜Ô½'6½`ûP[(Z9JA»µÛÇ­Üä9p|–klšZÖ÷í8±š7“›“‚NÎ8pd3ú0dòñÊ‡SÃùpÜ)¨Ç8‘‚NÖ{1œ&T§	çœØpd¿V#CÙpj8NoÒc ©E}ßCÎdiCÕr#Î8p`3¢š·i X’}"¹Á‘sbÔ¤:ê¬®ó#yÔÑmf~b¬DŒ&3?PfDÀ'l52tnãDçÀñYz¨5µ¨ï¡tÆ‰¬V`(ÀÑn…Ø"åìJ–hcŠœ£&&¢S4çÄ¨­¢&ËüDĞ´iäaV†ÂRĞn­FDçö1+ƒ<‡Ÿ¤‡ASËú¾'†\;Y%õÃiÆ'lV;”O™Üf²á4ãİpÜ+â™ŸXQÒJ‰…§í†ÓŒ3NØjd(N3Ş'Àgé¡FÔÔ¢¾oÇ‰‘fâ’sŸ8ãDÀ‘Íh* ×ÇzÍQRF6¥Î‰ÄM*ZAÎ‰Ä/Šª#ÛBL‘ee‡F”pÆ‰€›AÛÇ8ä9p|–Y4µ¨ï¡tÆ‰¬Vd¨†3»QÃJ|§¡¢…
ss"ñ5 ä9'V<—ŒEN½@û˜¶@fe`(,íÖjäèÔ>>T›<‡Ÿ¤GnšZÖ÷í81Vw7›Ğ/» gœ8²Yõ¬¨—„ÌQ6œf¼N€'*Å›`SÌÊê¥§í†ÓŒ3NØjd(N+ùp|–Y4µ¨ïÛqbvQYKrxnDÀ'l–]RN{g
G³Š|fÇ9±£¨_é`8'’ÃFÕZX"'ãTúH­}€2#Î8p`3¨‘¡sû'‚<ÏÒC¨©E}wœ¥3NdµCÎìV”ó±zPˆz­¬#,çÄ¢‹ÊüVË9±­’sŞgäDĞ´iäaV†ÂRĞn­F@[û˜•AïÍ³ôP#hjYß·ãÄÚ4ÕêÄpšqÆ‰€›U4ùh]â(N3Ş'À­rÎåzvÕj¬Aí‹î‡Ó„Šá4áŒ6ƒÊ†ÓŒwÃ	ğYz¨5µ¨ï±èh‚Ö¶ßn8?ci8¦ÔÃ{êÆq”œ"K‘»£fë|’§‚xV4ÌŒfGÍšüã\ŠfF”ï¾7œ57OGZ}n?ciòğ3–&=«±ijQßıK+Ÿ±`­xÆÒp¦š9©Ÿy‰fêÈ'’¤Õ=K¥;c!<Öù7±ıDĞkh‹ÉVÆ(…Ùm®‘¡Ïíë¬<ËsøIzVã¬©e}ßğŒ¥E±ôÃ©E·àKÃñ4E‡Be&İ¡l8Î†â™1køÉsÕõÎb8P9œN8?yn8´9ŠÃ	p6œ Ÿ¥g56M-êûHs²×6Gı\ÅçcõßwÔÇêÆ-ñ?^w,wÄóÊ»˜sˆ)8Oó<¢,p‚¸WÆi%‹5e‰Ó)¾hn_CŸ˜<?ìÈl)Õ‹8y®Qœ…°ĞYz¬4µ¨ïÉˆ¿\ô¥,Ì~Ëf!a~c¶Œıqu¥?}İıøs·ÙımoNÁx§}¥şF	Tñõ/û İÆÜıë®FÏM@îÔåø|êŸúOúZ´»¼Œq;DÓûB­î?1}Ã~îËèÛaOŸ”×–EŸÚñå+üÓĞ;–ÿÌ»çø÷ºçe•»gÚ“‡²Ğ=Cí4’™½hiÒi?6àçş'“	c¯)ˆ=!®7" Æö]ãÏ]¹F~ãE¹¥ï-aÜ^¿Ü±Øq)Ó˜C©ÅGííë–lĞlLªÚm‘ú&U‹²á›é'İPzCLïW‡­Ş'½ÄÎSÿÈë\8±üâÄA¡g©ÜëÖ÷†÷}×ÈÃ2Öx=­Ö•á¢ZÉ!@½NıØ÷Íy·÷Ì"ËğË:ÉëÖµèŸ:cM4˜×k‘í°ı/N]ÂéEBüş)œ¨vüIº‡>²6òh!Äúˆrû
ÇäŠ‘¥{c]qÎt<Û[OVûe¹#¡1ˆD-Ã–Ji‡µÜÏ 1îDÓ…´ŸH@ÔÛ#L÷"ânè ¶Æ:eŒ­½U–;e•ã|^9Åî¤q“¯lò©›òíçğ_†@8¢'§&Wú2ÄaGíĞ_z7ôŠø©oGÿÉ4!H+¨Kˆ/¸lL*Wõä'BÚ‡x•h³eCÑˆş½²ŞÅs¾Ø§¡µÂò(:S†ø…ô	…×XîÁkœè²f¦Ø0Å5~¾W;[e}oâZ7Ù°Ú8ÉgôFŸ<6±û$<”ÛvqÙqB~„{°ïZ6Şp;ğ<öêåÖDÆóÇÊ.¦lçÚ*š&æ 1¡X°ğşû]gª’ŠÎÚT/°Á=7ÀwFYI|~¬±Šc9ßxoıÒ­óıã&'b¨¾l‹Ê6Å¹Øˆ£š°Äñ\¨áLÙZ™htéN¢²Ê.8ßD±{wİ]º¤“¡Õ>ÖØZ¾,ç|Õ¥B¸P‰7Ï…p}Cî¡?Şéy›ŸO4|OÅr…áº_X1ÕŠårÿ‰8osã¨Ï}µı/DâÒï'a=w{1y‰£Â^|-i?½>ÿ;K¤½¯aN¶Ş…9süÀp•?Ftd²†c9ï„ÿ/lÿ56€FRÊ°d¥ôœõäA¡‚BiÎÜJ¡‚z§úc.ÛI’ /ß‚¹§ËË9¡~çGğ² {)Ñó²ÜNºÜ.º/Ã‰-K±W6ÂK_ª—É½Ç¸ÕğÃ£Q4§¸ãm^,gÇr>è,ä²£Y(¥Ç,ô!g¡2Úë8Çvc¢î•ì'S›¿g¹:è[*æ9=ŠjÅ¤³2Å¾*G§¬÷)‡ãfPÛhøá)ªìs0]Œë*å|P5o˜/ñAÃ‘†ƒ.ßÀº"¼r%üà"úl'Ú1fnÑ• ‡3½àT·jt®Zá·ç×çÔ”•÷¹/H×TgÖujÄ¯Y.‚ÇËXÎå|PN)ìC8^‰{pêÇãT›·ÓÎØù]9A>·m±5Äï¢İAö¢¢–~'|¼}"=Ùaµò*ÊV­¿*§bpÆ¯®%Mœi´ ~@¼fE´!æPºë[+8+çĞğxg’é/Öí”czj®¿Xè÷$Gœi›äµY;ÃÑHS›«—Ÿ¸ Ñ)Ã£2™ª©+Š¹F°´Ğ'&3äŠ¤‡ÇQçšF|ú®Ô+
\iq°b¦[r¯ârÏûo¡_3[‰j…Úñ‚âı^Õ¸ºŸÏ”ìtùL÷Š)ı\Ôş0Œÿe®¬,×Î„ŒÉƒ©á'du£¨ŸšØ3Æì™Ëê•t]¼?>2ã‡*9òMÃ]TÙÔ_ñ˜64yçJá(d¸E3Ü2Ü*SR}Lk¬;mÉZšÄ°}e÷àgÑG€wùp§
nYvZÈpÛe­¤Ç›¦–õı¸œ¬H¬Õ¹IÜÊ­ÜsÀ]ÄN§3Ã<¾ûË"Z„j®\Á³D^ÿÅóUlİóJééOû+Èò¢…÷=}õ¿poıú|^µiÉÜ¦&õFÅKá_Äoú)èùf\ºeåî¡£å¾”çKáÂÿ°uEøAÈÔ·fêâËİPÊÉ³¢g/Æ‰ßÈ›ù}û¤¦“/DÒ°ÅÒ
­vÑÂ
RçÒ.¢ài [1Ï+Ç#gŞczŠäŸ½F'ÒSÈÄÓğ’J°½z‹0‰½è£ûN{ñY 2MˆDkÍ}‡‰RÏêçNuVL³ba9\#,\Mb&óûğ¦}!²±wq½êœDîî³Nú“| 1ñ­Ì„"™¨Ş
Õ‹äÒµé;¤êûÆNÜsÇğìÒ£×¿R¯Ovµ_îù»‡ç/şüı=ÿb;ZúfÏÿÏ—{şÓŞ’Õ½¾ÕóŞ£;çï†qİŠŞ·(÷‹ğ£¿Ác¿cß¶D×™ş\êµŸ†îïD• Ó[H¦[ğû„;)œÇ—I¢¶¡ıÒ³]È[&kŠÃº·$.jªë‹ubé+R±-8ëÒç—y÷à¢õûrÎKN¼ËÃ„$‚§z`ÃnqtƒdGRˆ¼H
+R™¬\Š9sô"/M
ïbC’¡¡¥d²—ñÉŠHv$,%îïo¸i?¾6¿’ËíœŞß_b–äØh•JŞ¢d±•ÜswºŠrÆ2‘7$
§qçL¹"¥ÑÛ!—•dTwÚ¼Í|ŠêW^WäÁÛÀ„‚ÅÏõœ%yÜnŞ»SÛóuËµ=yò\^(`¬÷áÈ»Ij—[L'W¤²y™‰~y¿!wœ(c<‹ùiì!m7fëË]™$$[ß>¦¤>ŒxŒu<XÖ×`½ÎÎ!~Ø™P¿Ä˜â&e½ñåôŒdtñøh¢ğB(àì…P†;¥ëc-õA…¹Æú ¤‰!ù²‡öÊbJ g1%€wï‰N52^e¯{Â¡İ«Ÿ“ôP#jjQß˜’SB†qkı}Ã; "EÌ‘}\ŠÜõKñ{ÃûM¢Ğ5B¼(˜q%‰åEáCÉQ1ËŠ°SCº2«Ş³ã‘æEÁ’§n˜ 6¸cı»ä(‡LnXĞl˜‰Eâë+rƒüÒ‹BÇ;ã¤‚bpÅ¾Ææy¾Hc¢é7È.}J.¼ÆÚa5on…k9'Ö ãäÇ‚¾®Ö‰‡ÆãJT;¤„÷˜·<ê’V5rÅ<rÍxÓæëg¨O‡lR:FÄG*‹Æ»ˆê®t—!bÇrŞÉõ:\,¡úŒOA‘7-qT–ƒ8.ºÎ””©::•²ÏÇ3<AŞ=+CŒ‰òCË—å|¤ı8wë¢qO#ç’8Œ“]¾´Ü°rêÉùD¡rõ5¼pmûxŒéä Ü'Ä€¸'Ø_ƒ¹YerÒá…EYm¯!yûn|µRä"¯×Åƒ—¿S±!G¬ ÆéXDµ}Ï•÷ïÇoTÓSIñEgêcCÈ•ãs¶ßpçÙuÂüW¼|)ÂOz•ùO¯ïS¥Dq(>oÒ)Á—ŒøáÅ(—KL]†˜UËy'>Õ¥™c¼7{šÊŞÔW˜™c>˜[2g7sÈ†T2ã3ĞË7…ï†vål'ÊŞD,DôõğL`üÎñ/L4¬m’ÓÙåÉ‰åaÄÃû»¹÷'¥í-·}
İîvNÆkºIgeŠ·¹·e¬ò¥xZØ~`¸5*•LŸsWaÇr>¨‘©aô—ôp!>¤Ñò*?v6ø\şÁæ6¡Cá—ÃŒûØ·xÔ}‹®Ú×ß·HÖ)W²ú¸oaèWS ~`¸K§mç\¬áXÎu:ŒÓ…¼šFüáu|<¯Ã¶4â‹ï>6.÷àÜ=¶%Ú1yÌº>:˜£""OºdÄIy*¹=XÅ±œwâ!Ğ”Ÿ¢ÖÓéÏ+êJ:Ûé/(çs.‰ıiÛ«œMªA!ˆFeuò±¾ôÊlTÍ8yŠ¹G<*çBtz56Ë`ûúÄBC®HúHÆü‘œ–Œù•¶U^d^•Ëxé½r÷àífYËámy>Û’ÃC¦z)ì¦,J¡73f™é,¶ä„çß¸MMÔ	å-äÀ¸*Ãhï8ŸHÙ±A—â›q’[I(ª‰®J*(#…?‹®IÔ´¡jY®è¼½,8‘oòÜjÀ·3qm3NU"oŠ_~çå·@6$óŞ5–š6Ü`Ş¿¿áŠ¨v˜aí¥´ï}¡iCÊûWÊP1ÎI(úÔø@Üh\Ùù¦ëJ/R¨Xzo¸5&’"o Êq:Î	 Î0YæşUÖóÙ%•mÉ¡>ßli™“®Ï~`x0ÊÓ¢1w÷·Wq,ç¬çáVS_vNñÈÅFÕ„å w1 gÊÖªbÙ0ÔÓ‡<ñÄodO:­â;ÓÔ;=>…Œ·? åËr>n| Å¼›Ã,å¸ØĞnğoy7iø´Ğ†¨‰aCÄ/dËVfûsÁk¢ÚËOZ6$gègqj"-%ÄÏu÷ÕŠçšÄL-D~Ş>×îÚÅû3MÒ•ı‡fãÜc{lÛ^…ò¼CD÷¬ ¯ê ÄL³G®çÕ¿ï\M4S¢KñÃ³QÙ›b»+«8–óN„KCœ6{R^5ĞñyÅGDÀ‡šcË:sß`§ˆb†«Á¬; {‘·wóöcŞ¾—yû\†ˆ Çm¼¿üªM¡ßø\®;´FÎ1ê¬? ^ŒU6ĞÓÜYÃY9ïÄ±ù!äšPÛh:ı¹¬èÏ5k×Ÿ+*‘†’Cœi›~`÷Ñ¢ªÛM¥ne0¼Yâq+ƒÙ¦FGz€Á2Ğ>@Ÿ˜@Ì+’>">cV³¿®c6¤oÑ°‡CôpˆîÑ!Z|§ã=D¾øtÉë5ò¼~ÃŠbX6¼tø½_ddÃÂk;²˜-á=²9"FEDô29ñ‹-m‘c£K6­È—}¶´føÑõÁ<o4,äÌ«s‘üÅnléŞjg^n“Ó{“ïĞõŸ˜şIŸeˆ—ëVhAÄÀ/VR–¾ŸˆY:¬ËâÄ/Æí3½˜.…]Væàs/ùmhH/ÌÄØâ²Ä™ş°ğ‚àJTÃ9­
½´x]ğ.ã±Âœ:Î‹G1¯	¹EtÕ8ÊK¼Â0r'¿$‰¡9LS,eÀ8–jx]xCVÛ¡)ÂÏ†/T‰ÛÀR~á§Ë½WD†?Yfü.Ç/´ÛşÄ8StæË;â5}hœ.^6uÌeß%åü5AkÂüç.1Üé¼æ”¥ãÈ?1R…1eÔõ8hóuÌ{EÏÜ0‰Ükg¿dtM`ô5oÈrÍ‹I+%L o+…¾-™F±¶áY•}×o‹—ö»üe9lÆæWäœßğzÃ¯¿kúvÅã¬0oÔ½¥+7ˆ2¿—[ïKíã¹fÈçrcıN¼s7~éyÈT²¡Â^A×èã%–¼oHüWêße±v½
ïy*nUïã…†·Ö®yºérË>ü0ı2Ú÷;­NœP‰;šüeÎ.ÀâøÏö—ı/»ÿçCŞZendstream
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
xœí]ËcGrİ×Wp=@§òı êÉ€	ğÂğÂ¨±l¨åYø÷I²ï=ÁË¼¤XEv‘ U"33y"ßñİ?ıü›ÿúûæ»/?ÿÏæõğÿ/?¿XS’İÿ³éÿ~BÀÇMuuóúÛËï›ß_~zù‰şûûË×"ö_øûëß^¾Ûş²G~şò/ôÓÿmüæŸé·¿nşíßé9|½à·—â«iıŸB¿nñWgS5¹Ù	·ò×şáÿ~ù×?mşFí°¦Zë]K!íÛÂ~ÿ”|&&ï}àâFÏòºİ¿øÕ3Û`79»´iÊ	>lş÷?_~¥¦¦™šÿ,şŒµg­+)ûÚ­6×ûÛKÍ”R}ü/Û—œœq6:jûKNŞ¸R›wT/1×XB@Ø™lmÍ–ÍëàdºjK³ÁïŠŸğ`!§’7PipÆÛš2y4ĞWğíK2¶¤fkÌˆGc­³­ä‚5
í{}äÙ"âC•\[š%ç¬fúªè6©¤’7òª»lvÅ6ÄA9ŞúktÍ1•‘l-ÕÅ®2øt¡? ÑÊşŠS»šTşjå@û˜Ê@fêbœ«¾åÄpĞÖèÜ>nêY-â =Ôš:®ïn‰_ÿ]«åšÉ°É.ş¼Ğµ,ïOvçåÖäì]ìíÎJ-ÖSiÅål}÷€EÏ™pÑsf¼ã¹Zï–SMäİÑÖ‰7Ğf”«sÆ{ÏIÔ)S©ñHµ;RnïÃsˆò3á¢çL8ŠUÚÓ¦²ÌÅ¤ç¬7ÑWg…‰ g„8òš&Ù½›"J‚ùJ½Ÿ³]Ø©ŠÂQlG”d]ö60¶¾÷Ç;4 Üf3ÎÙnÆ‘íæÛÇÙn–gËñIz¨5uTß’èæÒ9Ña­Ht3ÎìF^SÈ£Ôß\«œèÂ_h”Ò8Ñu¼•PcB¢½@û˜¶@fe ,ì5rôĞ¾Wîµ“<[OÒ#ÑÍš:®ïë]wïkğª;M8£>À‘ìm16ñ0”u§	İiÆ‰§R!g‹Œ{Ü'­¢;M¨èNÎ)pÆ¼ FDywš)w'À'é¡FÔÔQ}_£K0CpÆ‰€›E—M¨µÆÀÑBS#À£!‰©§qNŒ1)¤³`ŒÅïKW´oF™gœ8°ÔÈĞ©}ŒA-Ç'é±FĞÔQ}N„Ò'²Z¡ gv«&ç-×–kT+ñvæœc ­PPƒ¿®o‰]r"èÛ‡ÚByĞÊÀPX
Úm®Ñ©}ÜÊ³<[OÒc³¦ëûzœØ]Á92r•İiÂ'lÖÑlé*B”u§çİ	ğDD“j«È‰İåi~™„ƒÌ¨èNÎ8p`3¨‘¡¬;Í8ïN€OÒc ©£ú¾'¦B}”*¥NÌŒ8ãDÀÍhZI¾èK²%¡SM6rNÌ•¼«æŞ¡¶ïŸJCNÌ•úE-±²±= Ìˆ€3NØjdèÔ>Æ‰ Ï–ã“ôP#jê¨¾'BéŒY­ÀP€3»+”$FÕ$ ÕZ[œsÇk5qNìğÔ¯¼GN½@û˜¶@fe`(,í6×èÜ¾Wîµ“<[OÒC ©ãú¾'vW js’İiÂ'lÖQòÕœ+GYwšpÑ wTŠÍ;fjì.Ÿjñ9òî4¡¢;M8ãDÀÍ F†²î4á¢;>I5¢¦êûzœXº¶lj>r#Î8p`3rCC¢×®ED¹`N{Ş<uØVKæœX2·BÊÁ"'ë˜H“¢ÀŒ(3"àŒ6ƒ:µq"È³åø$=Öš:ªoÁ‰P:ãDV+0àÌnÁ\÷[D#ÕÚ)‡sbÉšFÔR8'–L£¶F4A/Ø>ÔÊƒV†ÂRĞnsˆNíãVåÙr|’kœ5u\ß×ãÄî
‘ÔUwšpÆ‰€›•Ş'|_~æ(ëN3Î»ÃkÅyäÄîò™¦œ.ñî4¡¢;M8ãDÀÍ FBwšqŞ Ÿ¤ÇASGõ}=N$Š5¤,ß<7"àŒ6«¶˜Ü²k™£ÔºZÎ‰µ‡šşx±Xi,çr¡ˆ‚œHsRšßúÄ@ eFœq"àÀfP#C§ö1Ny¶Ÿ¤ÇASGõ-8JgœÈj†œÙ~¤qUbLYõ	ïCmœkEê*b=±k€†ÏÁ³õDĞ¶µ…ò •¡°´Û\#¢Sû¸•gy¶Ü›'é±ÆYSÇõ}=Nì®½KÎÉî4áŒ6£øj\¨4)ä(ëN3Î»à¤Øzbwù}È¢;M¨èNÎ8p`3¨‘¡¬;Í8ïN€OÒc ©£ú¾'¶ĞL¤Q¬ÜVœq"àÀf-ZCşœù*c‹¤
MŒ[ç§BÎÙ8'¶J:h¤¶ÇBÃn“i@Î9PfDÀ'l52tjãDgËñIz¬4uTß‚¡tÆ‰¬V`(ÀQ/Ñ÷eîÖ2Gû)rd1NläÄ9·$9±‘Ë±DŸ‘A/Ø>ÔÊƒV†ÂRĞnsˆNíãVåÙr|’kœ5u\ß×ãÄî
})&‰q"àŒ6ëh£jRá(ëN3Î»à‰æ•¡f¶ÍÜQúsÌ•w§	İiÂ'l52”u§çİ	ğIz¬4uTß#ştñÁ¡3Iô=ÏBÛòƒ@}™Á;âœ¸áç€à.’¾BK®Ï#p“qçıÁÓX×Uêï÷Q×ÏEøšˆ£¹]öİcÊRpøÓ”Äp¢ÉRú¼Ç#úî{#dİÂhÈyú™ğ`Å5—ag`*Mh8h7P#6}AÔ©ˆC~g*òê§ü.oÈ=øä\¨‡‚ÿÌ
]ñy¬ÒÏUş~q¥ŸyùîÇJ¸ùå×ÛİÿïêôÅˆ¶ùå/› ±MşÇÍ/}é–= UEmÄø"Ïò+²äWÆíÕz+Ëğ; Ì€•€;^è¿Ÿİˆé]6óéBräìS®)#¾E¼e°ÕùİÜOõ-à¬œ?Jógzÿ[Ñü§Líu¹ïús¦oÒ8DèŒ‰x60µ]ˆe›o±1´Ç&wc1´ÎD¼Ò!xWiÜ9×–öúÊb†\tûdù7pÉ{ekÏß[+UÕÆQ¡7 ø[š73oêÖ­şĞÖ°W‘³ÒVI*­Î@€²·üŠ¶¦üŠıQºPÆÕÚÕkÉL±î{)àg¡Wë¤€
PzU…ª¯øãZ J É®—å'Špy[e;”9¥Ûqp‰r¢Ú±
•p{·rş…(a¤Ú5Œë=ĞÕ²Mê˜ûªë•*¦³€bézîÏÃ2~”¶ø,¾â‹,ôûa°¹˜NiL6LkLJ§øZÙAéğ‡?®C]èóW|EFNİ°±pªĞÏ÷ÜÏz/ë+¨Kâ)¿ó*
{Ûµ¶[àâ+»û²a^4lE÷—½]ãÑ‰½Lõ2gßBccY4sÉ–êB‡¢;ûx<§ütÌRëş‡‘Nµ´Ãˆ¢›®¬ÿ&fPSíPJw Ô>ôºg×~¿®}Ï!ÆûÅÆ«®»0=¥"9€Ò…Ê.³ÂC†ö[WÑĞ!~Şt±ÕFsØ4ùí%ã]	1Ä·wÅä~AÉ‰EÕ%Ëù ‹­¸†êóı®mwÄFÕ„å ;j3Î”MJ¥ŸÌah¢Z\vï¨±‹™OÆÙcÀ5hùq9Ÿûi´ÒZÒ×•V¯4ƒÔ:ªúÄ~1Ç9É¢§VgÕ'T52D„nO«®Q_¤nÛ‹nÔ‡}.uGŸ¾exğ¦†wû'lï|Çr>­ÙşOı
f?†è[¿ˆ]¾¾:ó$¦‡ ¦R–Æ]z†ğåøt 9dÃ- KÈ-g™+ö¢ v‰¤¸¾ÜC41äZû„Fã
«-ß2<Ò—w!äÙ­ËyP>t4HìÑäIˆIˆ-¯'D5–S´#©k¼ÃâåÙ
¶S¤*ÉÍ+–UÀÂ’"|baIQ•qS‚ŒÍäİ…Î>‘ÌÎäâJ­ˆoŞçä1–İíov¸iÇr” ©„~¡Ù?	ò	²º´š õaá¸lÅ S–¡™va§óÄš²/¿Ó@UÉ¯bŠ’_µL-+ùUQah¸'ù>¶\Ú>ËtÊRªŒ…›rBügŒcc4µs_¿¤DÓ¶(ß2¼¿HkKòÉå<hŒMm÷{ÆØ‡Œ±!®±Cb:lÂ`»g}—zK=ãã7«5ıjGÛİÁä@àß2¼_ôHÁù"âàå<h|¬ı©í3>>d|La}|‡2I]ŠÛõ6Æ›Ğğğ¤°nÇ;Á+b»C+¢°:,¤¢pº=1·d<ıónâºÿ•Pß"î-ÍaRñòÄÇÎÊyPbv™ˆ™S{2óC2sY¼\òNÌ,W”4İ)†Óìx_GÑ,CªÔT@X8ç|1kñURßRUKPfÀø4±ÒGØÇT8ä±VõŸd©ªÿgñ+oÊ¨Æ_Ã‡ìpÆdoœÀ÷£‰ı5©~Åİ÷w¸S‹-"¾e¸ı1§X¬ˆK8–ó¨1ô,	µÔg@|È€ØÜm¢W³
wÆk{êhè3B~üyÓÈä“ÉÙ5»»ÊîñÅfß2<4ê¢)GqobÇr52å7¡¶òŒL™š[¦Ä÷™ªãÎp£êw>^Ü953;ßeV<ö£¬;¾<s‡ï½ù¸{ĞV»›ÌÅı·ß2<Ñ¹U'îÄ,âXÎ£†ÌÖ“Õõÿ<Cæ#†ÌéyËû]İTÌ¤>ñ\î|À zÓÈ”²éYyRÏôàv9}lñ-Ãs£y]h»0XÎå<hdò®ŸÊo»÷ZŸ‘éñ"Óô”çU®-©Ónã³[Ã1óŠ» Ã³+bœvAñ®bó$ïîks>ßf‹3Ôm¢÷;ší79{æaÄ·¯Ñôâ“¸ºˆc9J³¡§Mëù"4ûˆ4›Ï¸.¯hvü–ñøb9¾}²ê[³jÍ¦ßİåUr¡¿TœuˆoÖ[}ÏÎÆØs	gå<*«Æ˜ˆUËóÎıc²j½êû÷¼¾ËKõOf>ÁÌÁöüÊ¾ì»XŒïY“"â[†÷‡İjMÜ§XÄ±œGeæİqkÏËşÈÌÅÚ3.û¯½ ,¢W8/¸$6¤Ä|?\_ÑÒó_Ø[zrùDÌÓ{Ü/Ë@¤¢JÅÛog†~ì´æúeÖŒ÷Å÷+á€o¬‰Íæ,.e,âXÎa÷OÔ°°Oª.ô×Ó9æ”Cú«Æ%
}i»P]®ß´c(ı\Kj=m&âdrÛzraßLt»dÇXãllßŒ¾rĞ’>ÓW=RpògÜ’¿ÂY£‡aüÙdÌtüg”rüù~r^¥;?)›şúÑgÒûùĞ¯šÜP _Ïá9ş<V~ä°£<äpoÃ©á„ƒÛIÔgTÁ³O—+K9Ò¯&æwÚaT±ş¸K,U²ï.ŸHi!++÷ÇA'ù^~D—¢‘?Ëö:YŒ…™ñ7™Şu)á@±mºvıÃqS»™İBd:•tl˜–ìàaEJ¬Ê¸Ó”E˜øzy¼îÕæÎ.²Jğ¦lœîRÂ%“ºĞNÛ4|YXè~§_Q~ rº(`œñmaŠ~ê+*Ùà¹éT$¼» é*OÒØpÙcixzV0EYd‘S!ı’œOãÌsc¾åsíÊÊAÔEßk˜ÿÛÏFTœ‹°Â¼ãTRãfcç&S]D÷ªá–¼fˆÛ¿I]6ÍÅPê.Á5±§ÃÉˆoN?&W7ºq,çƒ¬¦AŞ¦¾¾ÊU›õ¾q±G5a9ˆC¶ ÀQ©}Ù,o3G«qZëx~¢èš	.Ù¥iŠiµùê1?´ü¸œÏüD´”æb[¢7½á>~Èj|®ix¡JoüË{\j×zœÒ0F9ÜUÇô‹œØóêê†I­"È2.CW«.ºÉ5¾ñ­½€9LhUeYí
`,ÜpØå?KSæàÕ'TÊËÛ_ ş'º¯)ö›ğƒğ-Ãc2}×¥Šï‹8–óA"÷'¸æ(ô7åßúK&¤šCœi;×BL£‘Âvó¶P¸d6&x—÷'®&ÇÊÎ¦gË`ûfô•„†\ô¹öHÁ;½û1ŞÔRùüæT|»×A„V¬viånŒùiÆ¾bc,¬Ø;ìîœÜ-Ñ›9jåàpø-½ö6›g‡½›SÛQGdÒí-Ç|æ#lùğõÄa,WOun•ì|E^vµV¨²=_¼zvoËö‹53UÛœX¶¶í\Ü—p‘xUæ#ÈÅ;V×Øõ¿8r"“º®EjD9ùûÅ©€9^¹UsY™HŸFQ“Ê‹÷—Õ–rå­ıqªy½s¡Ä_8Ğó‡lÅîÆ>÷Jq1ÔÍq1çÓw$:\‡Ëów#¿Á½%ŸÊú®rÉöãxoiL7ÃÌ—l%í½b“s¼·¬¸c ïÔE\´ÌIŞ$z¬0Öm¢‡®E•±­âTÃ¾±pâ‹ã.ğÑÂ‰oøÇN•¡ÈDj~Å
“b¹a/XsÆ`èäïÄác-ÃÏŠÁƒ.Äİ³?ïÂz™Âºšïßù1{ÅLmÈ”oÒ‰4…Å_Ñ«T'Rµ\°^ªt:~pí‚çïÁuË	×íÏÀ°Æã0^í"FaM+‘zu2Omn«É«*T~Å©‚ÿW¥Sµ¨Ñ¤ô*%œn˜Ü†w7NµC)Y~Å«á˜6ÌÉ¨¢Õ.U¦„[[NTCüP\uçg¨2'wÈµpÃ†]`í†ò+ZíÊ!œjªRê‚Úo¹wŸJ6-U_w/ählLÔPÄ·oÖ¤ì©Oñ=úEËù {÷p©¯&o|Õ
±G5a9ˆÃ8ÀQ©µ™XwçYZË.¤ÊOİ¥Ò-iú%Wºƒ–—óyêî6îÃ|êN³ÔÉ¬ñ»7çïÓ3_év(@½Y£Ç•ëÿzã^=1Şv¸àİ³¡Æôs;j”­Ş–Ğ8‡¹AÇ×•—€[³l‹Ù%,îÉÂb6Ñù‚E|ËpO¤PlH3ã"å|`vöûòJ(±[$=_Ûy´xP—×C†Gfß’ËoJ;¡˜R"1ÆîU[O£*[8¾exr&”Z¬H_±ˆc9J;4~Şâí'í<"íD?=ò5Îs:|JkÅYaz‰h¿ø¢Ï ªj‡IÜµ‚ÔIWEÃCÅ/·'YšD·Ò\ìM€û«)ä2€o³éÖ"f½‹8–ó $r'Ùà$û$¿>V¥ï6Ï¥]ƒ—õõ°q–35·ÕúÉÔÆißî…ËµRÇíëCİÑ8ÿÍãÏ›)¯»‚“iËWeÆWCÆõfšÊØ¤%ïB:·Ò[¸UİAf}RŸP÷Zµ_ŞÆê ™^éS>¥Ô†w?ïa•«q5ô}abüBÓÑX¼µˆo^é³Ñ(’¬,âXÎA}Ê¤WctVè¯'úŠ9ÑpQè¯/ú¼p¦íf<@]f(}-ÕĞJ¿JÉğfBÍa¿‡¶±¦8ßb³e°}3úÊBC.Hú¼¦ùH#ÀÙùNvj>Ò8kõ±Ã³ö”tp:ÀwÍ ø¯¥&[¹¼–ª>¢ît†ON@9ıĞ§zÖsáMİ³@}ŞR}—ƒ¥)|=çÕyÅñLi¼¢ùá.œ&®µwz¾.ß^sÜiàJ J?Ûds_9¤‘3»aTÍˆ÷!I‘àÈğL?ÙDcWBƒñÕù\8MîYsi ö‚x¦ñ™m1ômx†GSBrÍm°ÆœLudı´ÁöÍè+“gÆÙA,ÀaÊ52tj;ˆòl9>I5Îš:®ïé Ö{hïsĞš¦·EŞfohm¿+Ã~€,SÆ,´ãNé¬³u¶_Ù,9†Xq7â6×ÉWÜp=ÿ.ÌŠ»çßZºyË5¦j«ñŞ•°Ï£ŞŒ¾ô'#g|ËpïLõ)f±·ˆc9d	Ø©¯'9¦hĞ¤Øˆ£š°Ä!¦ Î”mÍiRj%+E«<ŠQ¤ˆëCmÒ4dÕ–3ıˆ5Î-?.çó8ñ-0õìIo«e+òá×B®«O5ı¾ÖµnC}&X[öéŒi|¿;s‹ø–áóõ
NHK8–óAbÈÙ§x}ŸêPñyĞãáX¸ä7eáñá¹w¹Kò$î÷&îL¿P£ë—ázRcb™ä3â[†Worô.Š¼—‹8–óAˆû“ïOòÓjú‹¦:ï[´BÙ¸P]$µZ¬q½å¨314[úhÙ€D¤ê&mãLÊÅÇ°ÁgË`ûfô•„†\ô¹Áü@‘§¸¸ÈççY^ñŠáXE+ñëœ)Nˆ©­İ³–¢†)hTÆ-ıjĞ/J\ğ>¦ZáZœzí‚üYêy\ğ¤Ùø’k¼Ò9~¾k¸Œ¸âA™±İæùlø*Ó‘GˆÎO°ô½5× @Ú?Šş¼âu+µ^½p>Ñ†=@?ˆ5|îg…/^Rï]»]zÛéN½fj¦­4mïñhK	…ßzFMZAŠ¤PÇ¦aêBİtUÆĞÿı0ÕöÛ(ùü–¾Ï+scC]ãAwŒß«feº†¡VdGi¨¡Ûï¶è}ÎÑôô·ï’ñ©õ;h€oŞRd×¬È$·ˆc9dé öÓ˜úz†<çhn]¹Øˆ£š°Äap¦ì`R¥8zÒ„óQœ~i1ìÓ yio\¶TÜ7„–—ó¹oø@ë}šñì•×d^t½d;ÜÔÕª–ªcAjzaÎ|ÎÒ±şÊ0)ÑÒ˜úÔê»Òúø%Y†~Êhø,Ñ%‡±†fX¡œn¡Ú›Ù¾œsr¹Y[MMÅ·Šø–á5™~\Q®Ã/âXÎ	²Ÿ\ë÷µH¬(õ—©Ù[©¿bJõ±yÄ™¶ûÙT½åh05WúyTfO‘·¥İú<Ã¹B
dp¬q¶¶oF_¹@hÈIŸëóg£ÿ”÷Œ³çÆÙ¡’õc~ê’üÃFÑu§¬N/«­¹SöE~DßÀ:¬|²âNÙÁ‰ÁŠê’™z÷x_‘·×nËD¯ «+cú™’ ªïoÒùxÌï¾¡û‹k¾Í¹¯N¥½¾“E.½ « µ	0Ş	VøªZùL¸Î½ımm9˜Á¯³Ÿü¡<ŞmR¹åïk¹ù^¯sË}ÑªÛšî¸+–¶Pïú¡6«€$Íw×çABâ”=>!ğN;óöXx»çÔã8ÅäÚ½üÃX1§İı»~YaóÓËÿoo±†endstream
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
xœí]MGr½Ï¯è³ –òû0,)Ò€ğaáƒ1ky±h-,ïÁß‘Õ=•/"ª&»‹=œ&5 Î<VedFF¼ŒŒü¨ÿå—ÿ<ü÷??~øåç¿?üò`¦ÍéÏ¡ı÷Å–Ãão¿~øùágúÿïOEœ^øÇãß~<şpB~ùğoôÓÿÜá_é·¿şüô×_Î¯·~{È®LµıÉôëµ&–)UáFşÚşëÃ¿ÿpø;ÕÃLÅgkôñTöû»ä£›lp)·ì®to¯ÿÃW¯¬ƒ9äêË¡Z*Ç;øßÿzø•$,U›J:ÿÙü¥§)›creÖi
uÊ¹¸äg5¥h'k‚µ­"©U#—êHòdr …º„¨£²LŠ%™Ãã>è|6ÍEv<NÙÕlb=€ ›¨ù!YãP@±Ò€"U+VSBB<LÆXS3é$"Úë÷ø 8´çˆ8´$’‚P—dceZúÊjZ.¤jXà2Z{M²ÙTÄA~²6»dCDªöˆ=héÀGëâ¹ì'ÜO©dJ>€DĞÔéÚÃú4SµŠ«)2{	$ÚëÇúÚsDZASëún=ñëà!5•ärˆfóç-Çä¾ÿĞLÜL)9øÍÆ}.™LÒN¤ â92 ÂúÓÜ:'W¨¹•²ˆ$Ë7&øj²ğŸ'TúÏŞü'’kÆ\âÚ`=iŞ¢DD¹ÿ,¸ğŸş|o=HdªZ×¹êÉİ\g=ärJ–w$àŒı G3vªÆÅ9ê'çŠw’›ö¼MÖ$]Ç˜=™;J´yJŞ¹lY7v”wcÇ9v	¬KdèR?FƒĞNƒ½õ(4µªoAŒP:#F&iªã¬ßüTC¨†¬–ècã#Oº	‚É’£Ô@FŒ]/X?Ô¶{‰JÁ~ë]êÇ{¹·çÈñ¥õ(±kj]ß·#Æf
ôD)ÊœÑ"àÈgÆM>„P<G™;uœ»à‰tIŒ[@@eDn î´àœ;|Ö%2”¹SÇ¹;¾´%‚¦Võ}CNŒÔ¸à«¢;Î9±ã,¨ËSµ£zÖÉOA€àÄl	OµÁ‰ÙM1»|6Ÿ$fò‹“¯¬;Ê;±ãœ;lÖ%2t©çÄŞÎ‰½õ(4µªoÉ‰½tÎ‰(ªã¬ß*y.Ï™2‘)„`]œ˜*i%Å`'f3Eo|æÁb×Öµ…íÁ^F†‚R°ßºDT–ú‰ fiçÄŞz”Ø5µ®ïr"™B
ŞùwZpÎ‰g1^™|¬%r¦äîÔqîN€“gySZT	-!+ÜiA…;-8çÄ#›u‰eîq%s'À—Ö£DĞÔª¾oÇ‰®ÍQbñ5ñNœq"à81¦ñ¼zW­á(Ä1rN¤hmrÉù³ ^¦XJ¨9Ñ9ò‹ä)ĞÆN”u"àŒÇ	p—ÈĞ¥~|ºÜÛsäøÒz”šZÕ·œ@÷Òù¥âºã¬ßâTITÌ%&5ÔÀ9Ñ¹HZ±ÕTÎ‰ÎQüb>OÃŸ$v½`ıP[ØìeœÎB)Øo]"¢Kıx/÷ö9¾´%vM­ëûvœØL¡M­r§gœ8Î“)hö9:ËgÏÜ:Îİ	pê£l	È‰màC) Âœq"à8îÊÜ©ãÜ _ZAS«ú¾!'&j\ö9Ñ‰çœØqd3Ïk 9afh rÎ	N,4çœmœXÂ”ŒŸÓd ±_äâiş„õë(ïÄsNì8²Y—ÈĞ¥~œ{{8'öÖ£DĞÔª¾%'öÒ9'¢Td¨£^­ÄÎ3eÖs(óŒi‘¦™å$8±Püœ¬µqb×Öµ…íÁ^F†‚R°ßºDD—úñ^îíáœØ[»¦Öõ}CNlmö•æ}ÂœsbÇ‘Í(höD…3%w§sw<L4cs´Ù%Zr¡.w§î´àœ;lÖ%2”¹SÇ¹;¾´%‚¦Võ};Nôª>=±'ì;Î8p`3l³ã#GI5Ø"ò‰aN;Š‘9'›§Í é}ÒL(–l€ò|Ç'lºÔq"´çÈñ¥õ 5µªoÁ‰P:ãD&
pÖoT1kr3–J#¸È'†9‹ç³q"µÌ2ÇÈâDĞÔiÚÃz
KÁ~ë]ê÷È­viÏQâçÖƒDĞÔº¾oÇ‰ÍR¥‘×JwZpÆ‰€›ùà¦`µ†£Ì\¸ÃkÍµ²8±™|¶!VáN*ÜiÁ'l
î´àÂ _ZQS«ú¾'ÒteÊ.Ò¤…w"àŒG6‹¥­ ™RšÌd[Ôì'¶´ƒ«Ñ‰¥æıbLÙ2NÌ¡ešæ) Ô¯£¼;Î9±ãÈ~]"C—ú1N„ö0N„Ö£DĞÔª¾'BéŒ™Td¨£^æLÍ|ñ9Y’šRv‚[ÏQ}³àDÂ©ÀyÆ‰]/X?Ô¶{9JÁ~ë]êÇ{¹·çÈñ¥õ(±kj]ß·ãÄf
ÑÅ\•;-8ãDÀ‘ÍæL›;%¨:Êİ©ãÜ ÷4@xŸãDB³«5qé¨p§çœØqd¿.‘¡Ì:Îİ©ã½õ(4µªïÛq"ÂS¦'Î8p`3ŠÀ¦HÇÈQ h”0"NŒsÚ!P¸Ä9‘¬"ß0çMO½i™¦ÈÊ e8ãDÀÍ@"C—ú1N„ö9¾´%‚¦Võ-8JgœÈ¤CÎú­eÚŠ3£ÄÄ@'Æ9‹BëÎÑQüLÓÙÊÖA/X?Ô¶{
K½€DD—úñ^îí9r|i=JìšZ×÷í8±™B$³•Û8 gœ8°Yœ3mù” ”¹SÇ¹;N=çJvlİ¹¡Ôï¹;u”+ºãŒ6‰eîÔqîN€/­G‰ ©U}a'ZC¥ºÉ¤(ô|ÚjDHÁ¬ÍÓzÄ›·`o‰¸OqJøÛ6Ì¥Û{Q¾5®ã|kà¡'4ü·%±.‘4Dì˜-)ê×ÑGÖ¨‡rn» X)|#İ“DDqkF¸5mw[Z»¦Öõ}îÄŸwo„Œ~ë?³m²<›h]ßDûûn¡ï??üø©íA<|şõ`O”O}şúíğ.S#Ÿÿrø'jpşçÃç¿=´Å'ÀšğHò‰0~Â¸*Ÿp_å‰S=>~¦ş}UÅ‡5ÅÇ¦w
¾Ï•ÿi®kí­Q@œk¶õ¼ÕW¥U¾ò^<¡•¯˜O²Ğ2,#ÈW>Ì@Ü®‡û ÍLJQeìÑ‡•R”‚¼|E•ñiTSeª÷m™–"~´MóQ˜¢¶ ¥h©Wİ7gsvÏhúOÃB†½56#]¨,ã’º--]q\3é$¸€”â¬¤‘1èw.° 'qó®gšLDY•¢qÅ¤5;Õ™Êî´š•EŒmæã:‘Ü)oĞˆF!Ó‹²ÆŠZÇ†'İ¿ª;Õ°ğÆ«[7ó®§D]åê•Ô®
3¾'‡8®ª~å§ëÙLÛĞP‰÷1‚·-Á«®HóMîŒ2 3v]³Ğ;*fû$u¿ø+“WA{Ù–b²ôÖ÷÷ é-ÎóQ°²ú±M+7P¦ìsßÿHæœ>C54º?I=+)µª¨í6¤µ-® 1Ò“¼“cå8Œ‘<§1½ªanLâŠT¡Êz‡©âœêñÇšÈ'¡Ãaïµ4¦jªÌAîÆüy&³Ÿ'íÏ¹×òÿv^ıh»@¬s5Ä!MÖ{>äÉ×ÜÚQ¦h<¯…Swˆã©;†‡©ÆTçEÖ.±@õ¶´”7Ô¯£<çÚqsí8;£·Hd(œºc'æàÔ8Iwn=JìšZ×÷[Îµå\‹É•»H–.óM/Ÿ€ö»q±‘ûºã˜ÁÚ%Oı–/İ9ÌÜ”Ec™Bğ!µ#^ÎGê×ƒGüHxšbmçãw>O‰øâ|˜+EeÇP<§Çp8§‡x¦
gbÉx@‰ÙM&d×îaúu”³hÇ9‹vœê[$"ŠçôçôÄÙ»sëÙZÙ¢©u}¿±èÌ¢6ÔM:SA¤ŠÔU`nF¡^‰r"íÕÌD‘÷O8S•2SŞöwµr§ÈÔÚœëŠlÍgá¥Õ k¦´ª*²‘oS¹"Ğû©u¶«è‚Y•Ôˆ7rŒğjò¦Ş‰r 	Ğ¥F/ßIë…ÜóØ[¼h˜ë5±qÀ¢&
jš¨€ë³ãÀ}”º*CÕCÍ×†Rt¡Ã!_ÃD®®˜ê¨aÏíÉÜbş*ë¡ÖûõªÌØ¤v,İ"¾S:UF§q~kœgÑë–ÃŠèæŞ~2ŞNt†XÊ|«T(4Ùõ¾Ú„øñ!šWÃ£¥it0ñ|ş5zïCå(mF63<MµÃ%:ŠØ’‹mG:Ô¯£,Œœ…‘€³ƒĞ‹D†ÂÑfv,6‹ãÊçÖ£Ä®©u}¿…‘sIÍÜd7¬¨ğMN×ÇÈªĞ­Pô·ø¬ÜËqF´/Â¼:vÑ£Æ˜œe®a¼J ×+Æcõ‹ì^Ú±:®Æ•áV­Óá+/1¬Ğü<ÌÛ¶ÍÍóÔR¨6#~$¼Lm›~bÏ[C“xoLNó‘ÛJ¶‰£p:q<ÎpO\íÃ|ÏU—XBãê:Ós¯_Gù°Òq>¬t\œ%?Kd(œg'»át¸8ñ}n=JDM­éûmX9+¥nÑÎ
	Ag”»«ù»šóëBT²yœ&P	ëaªe!Ê™·ª©šï>ƒİn,şºƒ¦ùUß(‚ãšiÛT <àú¹—©xÒÎ.Ø9 2ZßØş]z˜YšáÊxDG°ÚXÇa‚²¢ñ¤œá¹>çqAªe˜óĞÎxö}ı¦Bm«ãIÿx—Ëİ,ëßÙŞÅ;uçyØX6KÕº'&·•îI¤^¿#t¼ZÛûØİÕÊ¨t¢—qˆs±ñh»ø_ï³ìz7…êëù„éT–ëdüÈğ˜¦v>o>ŠåláXÎ~•âÚIÃó½É”©Ïy?¥¬êCÕ„å 31À™²ãDñ•Í•£$¦fšò¹»GÜlS»Úç~Póõv.s?ñ¡“+•xó/ì¯È=ØãÎp}ßÅ¤fgjb©Öõº÷ÆÜd<ˆì8±úª´š]ûv€ŸsS¥¥~|u5 ~dxIS4ÉÌ¹,gÇr¾Z½²şïˆ‹J0í¶Å¶ƒçéCAo¼ôGà¥–GİÏKj…GQŠÊ]È³0ãMDŒÃÌÄ1¶lœó¯N~ÁøÉ[“B»¹æ)¹vÍ¬GüÈğvœ>Nr›8–óß;ÛO7bpıE$’u!ıµOÜX
÷âLÛaò%ÚX9§l­7-Hd} W<2<NÅ×’(H‰½g°~}äÂÜhéñ-¬üÑwŒ_@ßŠœ/İäôÜ"ˆZãTbå¾GµgQW}cÓö3e\Iğw™Í
Ë²Øw¾ÿIÒvO¯ï¸iàEÎ·ï8÷x¿ÇÙU_ªCãà¸cn‘ˆUS)ÒñRÜí·g´»(½KTß–kÿsöñ#áv¢8#ö<|%¥İtÚvğÌQ¸”q¼”•á–~ŒÎ·-s]b›D»Ú>:‚õë(Û8KÑÎ®p]$2.eeªÂ¥¬â¢ÕsëQb×Ôº¾ß¶gÌQFtqËİïæğÈ0†Ğ€ŠTŞŠÌUıêGEÂødˆß8rÇÑ[ŒOÑÛ×ÚÂò"kÍã]0;îœPÛTl6Ü°rAh£¦·œÛ¥¨>´³èmœ¦B`n{â;NæùsNÕYx®4áoW„šùÊÕva…ÛÇÛ§Ò¾Y^(±ÍÖClG‚±~eƒ3àlpœİ%¼Hd(ÜÌnö…ÛÅ¿çÖ£Ä®©u}¿Î§Á¹~ƒ)€qÒW¥–Ë½ó}rÛ|ÿZõì©‰ÆûÇSÚ÷büşJêÔ”n|1œšô]ğá&‰„ñv¼·èıp·İ×¹vgÇQˆ"€jßqõ•R>÷rÕÕn$»gºï7*|Ë® ³´4ŠªŸÌùÕR,g°kè™ÂÆÚ(q³+‡~«|ßËd®šï+à¦ª}j~ª>÷ÎÆ­8UUÅ^|­–¢âë'bûGrneßL œŸ±ĞìDP¤ÖN€>H;P€4·ó}œúHô©êvUŠzÂªeUY¶Kë.©2Ç¼å`ÊmZØÙqVÕ+Õë[–e)ê	½¢¦+ûÓ=¨şY«¯nÓ„UL¶qµbİ²ı„Ñ7ƒJ>³´ªòAD)8ÈáQ>áá°BW¯•®ÿÌ™lüü}zĞsŸº²Õ§%Z²YvªM²Wñ9Bûò%·Áwà–ªG¼’“T]d¢WW×JS€Q€’lu]TZVå<6â;QÕ_Å6'=9˜OE‰œ]UÌ§¡t«uít«•¾‡j8»+¢]9H¬~_QCÉ³Uv h¡JNRC×øuy¸ê 5•…Zµ7äÃ×ë«÷Nùr(µæŸ'¿¯S)&ÛƒO§lCi÷ñô`»C°ÎŸÌòa²¶ºRìù	ÏŞ÷X:==ÿO¯Ø»&ñÒM;ÜÏä·'
{¿ğÒÿúğş‡;Œ²h.út³~ŸdÛ8gÿÌÔà‚“¬÷ySêsş]ıòe)œoL ŸS”o~¯îÜ®»@wn×bhwÎ;Ü|c2sÉö„gï{,ıìÎÙ¬¹sª¼ôT¥;·'
{¿ğÒïÚsâQä“Tnt#Ïıª6R#·‘šÖl¤Ş‹µHiOxö¾ÇÒÏ6RÃšT/J÷ÒFÚ…½_xéwl#µÕp‹{•¨lğû×¶‘J#ÚH5Îh!Ôa/Î¿39=áÙûKŸm„~/ÚFÍ¼t›¹œ(ìıÂK¿kq"„}nª¾¾I´Ó´híÔ­6‰x§…$M¢=áÙûK?›Dpk&¬(İJ“hOö~á¥ßµI„ÂÇ‰çh#¾¾I¤ÌM"•5“È†wZ6Ò$Ú½ï±ô³I¤´f)òÒçÏÔ3ùí‰ÂŞ/¼ô»6‰ì6YB­MİITËM¢® „Şi5H“¨ádÕ¡ITËM¢® 4-¬¼ôR¥I”z2‚jĞ$ê7€R=7Ğ­Öı.BTëì Ï}Ízı7t?æÊ Nßw|ı‡”.XT÷Iùè¥õá¶Ø>BºÿŸ;M~¸à¹SÈL¤İØ±u§.îwòÎƒ/QÚñÅãï®î¸şû«®¿fI¿r‹|;ÇòÔ&ëò0÷ç4³Ë·i"ã[ô”Œ÷íë‹6÷|&|ÜãÊÏÆ^4>–p½|s—bZfßP £7ÏŒÏ7·İ]àãÆÇ‘G³UÕwøâ¸Ğ›|jüÒÏDß–¯ƒşşÎ¸fªyÃ#¿ZÍãl¸uïç°.¸x# ¿Snš‡«ä6Õ¬rYã›ƒ6RW];¾$aÇÈzÁ‡m®?Ì7¾wÅ›Ç©¨zx³êÑù°uÙáãAÈ~ğê‹ğ×ÁH–yæÀ·6©á©t[ŒoŞ¾ş¨‹r©®_Wv»Ã®Ïuöx{ø˜·6œğGâ6+ÿeßÜ¾Ïö:û´ØóËÍù±¼²ªo7İzAã†³ê’f·˜½Ä7ö¤³vğğ81ñ"§VoqÅÂ¼Ì+…í/3Oı>s‚Î?FŞ¼£ÓYj3¸z¢^ï4Ã@l<êhS_º²qèò›IŞ™ÄzOXÚC›ãÍ‡×ÓhÇÙÅ—™#Œ¿W3vÃñ—“Şø|Àç{>|ızŞ+%j.+†1ÓxÏ¿·èí™cÕ{¾Ç	'ñÔµÄó—ß}øùáÿÛA
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
xœí]K#Ç‘¾óWğl`Jù~ †i4³À4À{0ÚÖ.ÊØYü÷ÅGUDF#+»HV³[¤ošùˆwFFø·_ÿ¼ÿŸìøüëÿí_ÎÿÿüëNuÑ«Ó?ûşßO0nŸtÚ¿ü¾û¾ÿ¾ûe÷ü÷ûî2Äéÿxùûî‡Óà»òëçÿ€Ÿş¹7û‡?ımÿ_ÿÿûËùãı/ü¾‹&u¹ÿ'ÂøZùÔ…¬œ\•ìùwÿù‡ıßaªKJ½õ§µ?ŠNb­6ıš=îWÿÅ]¸µÏ&è}Ö05vÿÿİı3KëR8ÿ3û3=tNéèƒI{sgbÀ¬ßwÁå.Æd‚Åøa¼î´rZ{Œo:S6zo’ê¬×ÚjŠê.Ä¿¾Ù!ÜªÔ¥ä¢SÇ±G¶l´JÉïÑŒVëÎ$osŞ£õ!ôïá‡ïTôY%0î:¥´Ê1D<#FÇõ½ìös ø°{4#¦Ô$½_@ S70Şs"U`«ÎÚS@UÆ8æ[2Í6ÅLQ³Æä|Á\¶*UœUú<ö€Ãô!i÷hFD´>B-´ÂåØiLà˜ohFŒë#\Fû9P|Ø=šQjšŞ='~ûR§R0Ñy5ûóœ:(¨lƒªÓˆ÷"¯ºŒvä÷{‘·1EehÌÖõ$Â(Q§/Ô	á0}H>öc3ö"ï’×±P§-ÔiÀ{u‚`¼0îÀpèÇ£b3”¨Ó€ê„ğa÷hFL©Iz3&6ÛD`>Àn(Nl"Â‘5ó±7à*¹&(ü‰ÚDŸsgƒsÖP›”ê½Ø‰‰ÃŒAi ´WYa&"”0áÄ&"Y34#BÑúˆMDû9P|Ø=šSj’Ş…MD£›HfE
á˜o€¦haIµ0+He¤6ÑçTGa©Môâ	?gl]ğú0µğ~0—‘…Â£ º 1:¬píç@ña÷xÆ‘RÓô^Ï&ö¢à=Èt©N#Nl"Â‘5óx´§¡DFœªÓ€÷ÂmLŸ°MìÑì‹šªÓ€ê4àÄ&"Y34#BuqªNvfÄ”š¤÷z61d¶Òeœˆpb­Y\ qbÈ¼¶ŠeœÁûÛìTÈÔ&Fp(Ñ€Ì:lcï|²‹†è>B	Nl"Â‘5C3tX±‰h?Š»ÇVQj’Ş…MD£›HfE
á„o-z4gmÊ81*ß»d0ÑÔ&FzîBÀ6Ñ­Pí‡pY(<
æÛ8#F‡õQU÷s(ñóîÑŒˆRÓô^Ï&†Æ:+[Æ‰'6áØš@y uğBú`\>¶‰=š3l¡P§-ÔiÀ‰MD8²fhF‚u-(U'„»ÇVQj’ŞëÙÄ¬ÒÎ„@™ˆpb­œYà“¢¨íœvÙøÂ&1ìÙŞ"<tüI/ChFˆ’†Á#aâˆR&8µ‰#­ß8#A‡õ›ˆös ø°{<#¢Ô$½›ˆF'6‘ÌŠ-Ôˆ¾¹dË$ÁÂ´o]ØD©óFw]T:hOlâH¼>L-¼ÌelÑ(˜oãŒÖG¹<îç@ña÷xÆ‘RÓô^Ï&öìMÚ¹4¡NgœØD„ckåáxš2E‰:8U'„‡Î*£¼#6Aé<S§3ÊÔéŒS›8âØú3”¨ÓˆSuBø°{<#¢Ô$½×³‰¹_XÈ©<;#œØD„#k–A}[Šz8É(W5ìlG<Øî`eı‰Í(Ğ(C"„&"œØD„#k†f¤èe}Ä&¢ı(>ìÍˆ)5IïÂ&¢Ñ‰M$³"…pÂ·Ğy€éÙ9§›W¹<;ÃN5üEt…MÜÀyGOÉÃŒˆ.h}„Zh?„ËÈBáQß†	zYß•Úa?Š»G3"JMÓ{=›Ø‹‚‰0S§'6áÈšõ(l%Ğ³s¡N^¨Å3°.`›xù“…:]ĞR.8±‰GÖÍX¢£:x¡NvfÄ”š¤÷™‰¿4ßuÎéŸÉmRÅïã»&3Ş5}oô§o»¾[ÜşÛo{}ºÇ;ıïÛï;¿ÿ”ûìì·¿ìÿÆÉşiÿío»Ôÿİ	ĞG ^bù€P’Ê_ù¹ Ôi^7şF. õµƒ-•}„úc¹öŸÊ1ÊÍğ1Ø´Ÿ€Ÿß-ƒ}„Ñ0ˆ€:öÊo|YÈò^¾Š4åòÀFU¶›Rd˜ ²¥™EºËk•`;$á+1¥ÈR#rÜœ¯Õ’Q÷J’ğQÍQŸe[T²‚Ix…‚ŸfùòÜÄFíw¾Øoo%{ö${ùUÚgCK“U!%lšr!ì#êK¹væÁØf8e­`d.õUiwæ«dõ¶ës™>¯àäŒc*Áæu%PRˆK÷çå"ïñ¡Ü._ÇÏºË~£$¢¼¶§Ëí–1¶Ü?Sg¤i8ÙRÓÖÍµÕC¸½F &ë£Y9mE@Êb6Æri–C8®™Œİ,Ä‘#‹³U=ŠÈÈe…8;ı3=ÉÉ¿_!ZË&=ŠVÜ3+Za0gåB’s2j¡ä)vsaÕÎ”ÒÈ#ö!ö;g ¾ºé0l\ËÙ=¿Ü³pày~f«ãë=‰ƒåÎâ\Ôs\tÊ\ÈâE"L0„Q›;	&ŒÚäçk)Ùz6,YÇ>ô¥D..Û\˜‰ç|.MçœĞ©[	]˜:TlÜu©¦ÖeÙ1ù;Y¯&z$gCAúWEK,&mqIblÌåQ‹Ò¥Œ°€û§)_ñÖ³~t³GÍŒëâéÇw,"`Y Æ19"X#d’£
Q>ù å&—jÁh*Ÿ	ÙG˜j±HMÎè°DÙò#ó*ahƒÎoö„Øp˜s‘9››dÖd-s¶Y6çì;7|Ìr~ÈŠ±Ã:#ërÙ¬H<­EÛHğpJÌMYË¦©X	ÛxÂã„^ã~Iv#laâ•Ô¦:f¹fò˜¯~LúêFW4ÍÌİ`|îT&Æ¬I»ï¢S<¾©M4>YtíU ,k÷[v¯cÑ€låûí†‹º­$OorR5[à¼Â¯‹$KÒã|ÓLb¹¤€+”ËlTi¢&T³bü8>É§ò­”…<H±älyÔRé¯q£Ê"pFuqPN9fcù1¡ ßÒWL+òV>aW\}¯!Úb‹Gµ²CdÛg‚ËäcæüµQóç|¦^ƒ%‰e¡™9¶otÇG/iíì¹¥¥èM¶obê®"uµÙâKùö_µÄ›ì›XWÆ7æ§"záÌ–O\·É\Š™ì
¢Š.‹[©ÌËå×LêÖT9=Îó§%ûYÍÙ9¬FÌe2$—Ê’Ê>b>‹Deœb¸”˜ê qË¶ÜÛY‰`FV¾ê’¯TdwyeùŒÊÖ2}O[®½‰ÄÁU5JyÎr!‘èËÕèg«ÃêkÖ»Agø)Qöï"û+ÎæË­hËíHIC.Ê
»?¤uéŸ¸`U5dê*„}¹ÿ·ø"¿¤KŸêRŒÊ÷RŒ×àYR¶ã‚g×¹¤bêÆâqæp<Î+„.½œºNÑïÍï‡ûŞ|êØì’’ÏZôÖŞºmŒc2áq0û×·Jo0Nˆmá“°2OÑ¾Õ¨nÑ(’4s,4f¯ûÆexÆqåÓûŞí=gqõ¦³íÙ‚<>4^´“uŠğ‡Œ¿ØªPŒìÅ}.€¹gh,@–ùK	°Ì=eAåë,Àü.s 3ñĞ•Ç×l»îGÑß±ÍÄr–²~¼ât§¦µk%f'’±øå®r![™2¹T±×éñ
f¢İkü—	0˜^#³+…y9ï8Eüã€Àkhcú6&,¾éıÁï{Ğ†ärPÔ›Ìádœ'	 >ëaNç¥ôK°qã´K™î;åÎ:`Qß‘xÄ	µc§½‡}S4÷×éØAˆğ µ•&8ğ[¿ÃÍˆ8ƒÖ‡Ğ²!ÂÈ™>b€w ¥ßµßpB/ÄtÙ^Ãcô5îÖ|Áï‰ªiù¢°%,§N²OkäßIøÊ*ÚôÈÍj+<ÕS0Â7Üû±d
TN±…‰©¢Š'£{=·<¥Ù 3ïıê¸FDVµ‹İ–ÍyN³bÅÁˆ™ò–Çwâ·Šr2±˜b¦d²k¨ª\W/ÎRÑH†„åU*ÚÂ|ÜX|{åEÃÛ\¹†Söõ7yßVñUnòÕĞzè¡]6şQ±ü;>jËÊµ¿áÚ2™—w©,­ˆ9Şzk¢Ù¦61<KSË»»°qÅ†GOÑÀæí¿ÔìsèÉÌdKä)Vèq'‡Är°*¾ÉYÅJ6x¼ÇDâÛ}Ï­C BçNÂ™gF2Q@ÖèàrçVOfILÁÖ
^#yğ w8,Ò‚ô`[şH¼â$,6R·â‰ä>a}E™›¯Ozö»˜«È®3‹%“è&E¥¢²Wd1–7òZ%#s“#*srÍĞØ;ìŸÅğL®Â^ş2ù‰¡˜ä}¯ÁÆ’>ml{|¿Ë›%İ&ËÍÖÁ¤JnÚT›äß²±«Óo¸“c‹«Z#¾amn`Uƒmnè²"Ç¿ËOı-ß_Ó#¬:h±wâEÏJo9eÕ\ã6ù1}Dæj·—ôv5›¯IKc¿¼5Î»ò7•¬›Ë%Jò‹ym¥õcC÷ï.WSµ¼K•ã¬†àí>7ßñĞÙ±êçQWÅË÷G+ƒí×1¤+İ)—7U¸O¯ç
î±A"S1 ŞJİÛ®Ò®ñ›S3Ö˜<v¦<_o±m÷M/÷¼‘\CE6y«éˆ=¨7ú;nŸ!5ûd÷À6$¢…×å£öÍ”À.¿\^'ÿÚ]]É-ëÿ·ìÕí`‘7[zºİR‰·sV^£ïßÇ±öú®y„¾xß®ÆÒ÷)â¨0!›ï?ı`ÿ·Ò²iYEŠ¶!¬ßjC¾‡…H2ÿîÛû™ÄÈd_ãÌebÓ—ÇĞş¡áEÔr×İpı¼.>êÎú]ß¤F{Ûg´W?<¹.åRÑÌgÇã<I“ÔıÏ$Ó¹]tÛÇdÂã`õÜC8!¶íRò9DŠšÎûœŒ¡]ş|´]ôÑ©X²–4wùC+ŸŞçG—¿wÔá'§ËËÓ.ĞÒåí®!™X6õãÀL\v¨µéVöà¡¾+…Î•uî}— ¢Ñ;…ñÆƒR.xMáNÆyßõIÛØcP%ıxƒ’)éç»Y‡qBí~@ï¬¥(°6h{‡ña8›³¥¼ñ|PíîÍÑ0#âZB_È†#gvúÑ îı¸/ö3®i{ïiY¯œN”ü­cì9>û6†8èD;¾†rÙ>Ì¬ıùŞãƒÀúgyVí™üø’‘ùx’¿ÅÔ“l¦KùÖ}rá7jv³ÂÃ:éB¶†ûâ·“?ÜÊ—:/Ot¯Rh¾•î¢+¿W©øö¹Øvh•¾¥-7ŒËç=+Ñvï˜4(ÜğşN—/ë"3L±Ã×¨åv#¥0’/zsMVÖ5=oè©xEåÖòØ¤¢»£xù×âÍåÊùÁÊòŞ<ˆ` [Xía/ÓÜkß‹µÒNÈ®óYùã5éàºä¼1ã‡¾?P§£V1`\‡Øç9©ì»¼ŠŠ¢¡ëËá€ó²CxT¾‹Ù{¼Âxì´Î1ú=š1ªÔéìLÊ{´>„¾àı œ\%!å8ÑŒÖG®’Ğ~huÜ=šSj’ŞÃUÒ½RXÍRi7TùÜ²y[6‹¼™9ç½è!8#bƒó.÷¯˜øºıPtx÷µå#LS¹ü-ØÜ©ÉóƒäiJÀÇ`mËfìÈµW®´]³~wƒ/Œ¬S…‚3©AøUƒ\%š‰şÉalE‚•y1Xce|ÔZ™¶Ü´)œÌæŸuÂb×moûÌß|Pöİ<Ì64tz“w+ßæM¾BÌ¢5}5¶|]ÁÄP~™´¼‰WÅí„loRo9¶ ÚÕo9^W—şØ[vCfìóúºï¨_)“é‚vQ…>§ug¬òÚcü x_çlˆ×ÚvÁj ğcÊ¦¯SÃ¨ï@lp}¾áÙvIÇÕn÷v6·Ç3æĞ\_§†Ö7¢47â47â8ë6ÎHĞa}$‡ös ø°{<#¢Ô$½?rq§\œñ¹¸Û»Æ÷š_M_½ÉZ.3o]ó¥øĞ9†(Åë²¾–+cRç&Lz®PYÒj“EoLÑÙg>_Ñ›cúR"—¬èÖ¯Rw‘ŸÀä‡)è´ü¼Ic?şØh©½d†ûuÏì'nÍÙ8+-³ÒoyŞ¢7¿½ç‡H¹€M<«V<3¾Ià¹òQ„™s›)²^tz“Ï3[­“[åYíƒºëŠ	®©-*Ã"—DÉÍ\¸/+ë*z·Ü¤­õœvoùlóÅÜ¨Üx…¯=¬¨“’¿£AÁ—gc*Ê@¾{xyß¶çjã—•T#T$ÁDSÔb¬å âu8—˜–ÎïFåKƒød‘°õ…tİ©®8è*-¸ŞL4Õ^(°eïêôEªnómlÏ|;rÎ?¢x„÷ ®¸êú*	§ê_Î°Âã¦Š³ ÷r“ı†¸ÔÛ\¨Ş(ÔÃ^»â)ÖV¾'S6í2kß™m0F=Y{;äÓDùç¯'ÉBAÍŠÔƒì*åûoçãû
*ÕËJ¶7%ß õ±Ê#'SÉË–ïf¿­ğ½v·	X*jÄ*Â¦íb¤h²I½K©âí×±ºp¹¹eu¬r¼óLd·“<şè!˜Ó†DøëŠãÔ/÷b$óØÚ5¤.¹`ÁøàÆŒ6—-\gq<Î“´ÇCµq„|ÆkXJÊÖÑmc“	ƒqT‘‡pBìØùœmíšûzÁhmÙÚ5§Ø¹¨rÙÚ5§Ğiç"míŠV>½ÏÖ®ï©7Wşl¬<+ ëøÎ™ærŒŠ÷eçRV‚È«cNñ$+åf÷:×|†èC].ìıåÛ—X{ímïŒ#¾VÇ)`®WÃ52»22[Î;N|÷ğÿÖww«èœ†¡340a*ü@qm»SÙ¼`Gã<‰û¤½¯³Õ”~	6nœv}	¼ï”;ë€EGŸ1à”Ú~\`ğn^õM(ô©:ã¬KÙ`÷dÆ3d}úRl1rf§í_ß•‹3î}[ğ·[V?_-îÃ³T‹[Ş=”ËV»ÍÊpfPÿÖû´ı/»gÕendstream
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
xœí][#·r~Ÿ_¡g¦y¿ A {/òÀğç!ÈC0'ÎÁldsò÷S”ZÍ¯X­aKÛ3£™ÕáÕ|Ûb±Š¬,^ªú—ßşs÷ßÿØıôá·ÿÙ=NøíA«ôñÏ®şüˆ€õ»lòîñ‡¯»¯¿>üJÿÿúp*âø…<şùğÓ±ğ‡#òÛ‡£Oÿ·³»¥ßş¾û÷ÿ ¿ş:}½>ğÇC²Y•ú'Ñ¯{üÕèU,Ú{Âuÿk}øoùa÷'ÕC«¬µ5%¸p¬ûıÇìcQÁº«WWºék?øÕëpTÇïŠ¡‚œu»ÿı¯‡ßIÄ\7•ãôçìg•×&…hó.Ò3&ÆìY7ú¢RÊ6:Ä÷1e´7& ƒU&åbÍ.•©r%[†:eMrŞ¹İãàE+o}Ö)Ên¸©]¨w ±X•mğ1R­~€>¢>€ï‚"E“1÷Jk£KŠ	%"Úê÷ø 8è³gxÓ$¢¥íıH=2«¹Õ¡ôÚ™¬Bªz.µZ@G“tAÛÍ©â\ñÜZÑ“ÔcqØÊ9“U¼£êLeŸpú¤³ÕµîM"ØêÇ¬ú°VNÊ˜lK» D@[ıX+ƒ>{†7íA"XjÙŞµ%~ÿÜ©ÄmòAŸı|ÎŒŠ¦ÒíÜ©áµËk£5=_»¼K9iúh•s.èdÊİiÆ;wj8}Ò9zW]u–H m°ä	;ĞŞNxu§@RˆSShãL::ğI"¢Üf¼s§†7íA"ZjÑŞ¢¯æD“É¹ƒöÅñFœq"àÀf&e,‰‘£$(Ğ·çDbÂ½?ŒW'ñ™Ø¿ 'ZMj„`4ó}@Y#Î8p`3ÈĞ¹~ŒAŸ=ÇgíA"ZjÑŞ'BéŒ™T`(ÀY»Ä”‚ç(	
†jÆ9Ñ”HVñZÎ‰¦$•Èµj‰Í.X?´êƒ­…¥€]@"¢sıy¯õÙs|Ö%6K-Û{;N¬Í›«;[éNÎ8p`³Ú¡BL®ÎAeîÔpîN€"—l³AN¬ ƒÏY¸Ó„
wšpÆ‰€›D†2wj8w'ÀgíA"ZjÑŞÛq¢õ¤\9jŞˆ€3NØÌzzÀk—<G­¢‘$˜Â9‘æk„—<uÀƒJ%”'ò‹Dæû€òFl8çÄ†›D†Îõcœúì9>kÁR‹öî8JgœÈ¤CÎÚÍ)“±–£TİKÈœi¨§.R\rœmp4vVäD°Ö­…ú`+Ca)ØnM"¢sıx+7}öŸµG‰ÍRËöŞkó’Ïé¼àNÎ8p`³Ú¡}¯ò¢ÌÎİ	ğ \p±NGA"9‚¦Â&T¸Ó„sNl8°Hd(s§†sw|Ö%‚¥í½':K½+Sè×l€3NØÌYš)Eçmà(	ÊD8šs"%Ê›£ãœHQ…DEëŒœèªÚÅîå€²Fœq"àÀf ‘¡sı'‚>{ÏÚ£D°Ô¢½;N„Ò'2©ÀP€³vKÊÖ'GI©©çDçh¤(Ô9»ØÙ9šµ¥h£FN»`ıĞZ¨¶20–v‰ˆÎõã­ÜôÙs|Ö%6K-Û{;N¬Í[[×éNÎ8p`³Ú¡¢Wr”¹SÃ¹;N³¶D#GAN¬ ‹sZ¸Ó„
wšpÆ‰€›D†2wj8w'ÀgíQ"XjÑŞÛq"u7UL¤ğFœq"àÀfDª£sâhRUMg9'új:«ƒíÖ=:ÒÈ‘4r¢§aƒLeødPÖˆ€3NØ$"ÚêÇ8ôÙs|Ö%‚¥íİq"”Î8‘I†œµI½Ğù-†êj8'úÊDåÈ9ÑS7ÚËbg°Ö­…ú`+Ca)`ˆè\?ŞÊMŸ}OÚ£Äf©e{oÇ‰µ+$ŠŞû¥(À'læ+[8b˜ÀQæNçîÔpêÜV{Yì\ÑBÓñÈ;HC;wšqÆ‰€›DD¹;5œ»à³ö(,µhïí81jâ
2YÑıËŒw{,3»)šbW¢öõªº¿ïbçh¢‚gÀ(Ád;G“Uˆ%i¾kĞP¾úŞpÆ‰€³İ‘Y"Cçúñ=–¦ßciÚ³=–f©E{÷{,­t¾Ç‚Rq¥á¬İêÀiiBÌQê:‘lĞÅÎÑx²
ò]ìMP>P$Êbg°Ö­…ú`+ã”‚íÖ$":×·rÓ‡ï±4íQb³Ô²½7Üc¡®bpF¸ÓŒó=–†ãnŠvÊRübG™;5œ»àIåÄbçŠ¦X|îÜiF;wšqÆ‰€ãîH“ÈPæNçîø¬=JK-Ú{CN¬~ÄH®tØpÎ‰G6+U”KÁq”>æB?œS5Fq¤5çÄ¤«hFÎö“*—‹e8ãDÀÍ@"CçúqNlúpNlÚ#'‚¥íİsb+s"JE†j8¶¡E“ğ._œJ…fP‰sbª]ªØ,çÄDİÒuçŒœvú1k>¬•¡°l·&Ñ¹~ÜU›>œ›öÈ‰ÍRËöŞ©+„\|èİ©áœlvØÀ:òİhîN3Ş¹àµ7Ò'¶ï\QšVE×¹ÓŒvî4ãŒ6‰eîÔ¸»à³öÈ‰`©E{oÇ‰äŸÇÃ!İàŒG6«¬P£Úãn{·˜ÉHÖêèºõÄ\ÊÇ”Øzb&6£æ´…Í| e8ãDÀÍ@"Cçú1N}öŸµGK-Ú»ãD(q"“ŠÕpl·Ê
õ8Šã¨;^Iİzb&Î‰V›ÒŸÅ!†
ÚkÇÖÁ.P?f-Ğ‡µ20–‚íÖ$":×»jÓgÏñY{dáf©e{oÇ‰µ+‡ôîÔpÆ‰€#›UV¨ÇQ<G™;ÍxçN€‡êC>²õÄŠfktêÜiF;wšqÆ‰€›D†2wj\Éİ	ğY{da°Ô¢½·ãÄ\×¹è}7Ùœq"àÈf‘ú"1Ÿ'æHÆpäMİ<‘øCyïI~Ç‰d$eè‡qbíÿVY6ó”7bÃ9'6Ù¯Idè\?Æ‰ Ïã³ö(,µhï¡tÆ‰L*2TÃY»yEÅu+9R®Ùn˜+C{ol;gêjÉ¦Â÷XÀ.X?´êƒ­Œœ¥`»5‰x>q®oå¦Ïã³ö(±YjÙŞÛqbí
ÑÅØÏgœ8²YtuÿÖòybçNçî¸UÎfÇ÷Xª#hÒ@wšPáNÎ9±áÈ~M"C™;5œ»à³ö(,µhïí8±T®H6ÆnQpÆ‰€ãiëB}Ñ'òFe“s¶Ûc1Zgú‡ã¹jiæÍbgCÔ£h*g;q×P~r­áŒÇ“…M"GOõcœúì9>k§ÄÁR‹öî8JgœÈ¤â	ê†³v‹ŠÂ‘b=GIu)v{,¤)MŸ	NİùD­“
ñä8§ó‰Í.x>­…çÿ°•ñ´ ”‚íÖ$2ôT?~”¸é³çø¬=o–Z¶÷vœX»BL¶ÛëÜiÆ'§­KP"Â8ÊÜ©Cäî„xQ&u!'ĞLÀİiF;wšqÆ‰€ãÉÂ&‘£èNí,7w'Àgíñ”8XjÑŞS#şzõ¥e8—?³+;+Ç=¶]èùzµĞ_¾<üô™šÅï¾ü¾3ÇËRÇ¿¾üñè³4 }ùëîŸ´ÖŸşy÷åï¥şãø| ò˜Ü@8ÿ„vÀ·'Ü3”!Ÿˆ½”Ôá Û±ºRî/İWìÏİ+¾"ªZú¯èàÎ—!õ7 ]PQ†øŠû(l(Z÷óH®;*cL3ÀÇ¾#ößñnô„°»ToØ˜^ÔL¾omGííÍk q‡úˆ°³ÔWvx‰ˆbE?ú8¬«0ÉF¶±üstoèœŸ¾ĞØr£¤M9k×!sH:NoûBp9µZ=$ß¾oJj=êbôêŠªŠ^#Ôû„øÊ~%8@ŒCÂŞÂ7¥„r¢ƒˆÖö)Ùü®ÿÊx2"¤\>nn2ÂoauÑ·%y"Qdè¨[ÌÌÏÃÁJôíñÔK´¶2f2Ñ§„•Ç¼˜GOÚİô€àNÂ5~Ö÷"ÙÏú¦ØĞGf…L	*êS*ÓçL`ÿ66ó…=iÒ˜¸MßÃtæ‰'^k1wÖò=ïCo>°·s§ş4£.Ÿ]¸O@k»—K¢‚çY¬ò&ëj‘dÔ®'¾G<EEóÈ[¸|gå|c—K{ÕÓızõê£ÑÊk›C=£…æ3Q+röRwQmÀ™™ †—ÃqëÍ†£±ëêw½vÅRb$wÜáOı1SL·ÁShøbb½v	¡æËzÎ«~]Z ¸y^ ë+rıñU)Ğ-Q ÑLa"«à‡3OÃha<Fë!pfzÀ‡áÄöÌ°OÄW§æ”ç¬ÇİkÚCtñ=â…XÚm·ÊpÛåÎÊy'Ôüc4TãSéìç•·¡èÊ©Ì~A¥`è?ƒ8Z»6TÈÄÁˆfbôÉ(Ø,%¶V&è`js4‰Ğ2P?@™B¬!Ïhº¿³ó÷ÄÎÅoÉ½/É¬OŒ#Zì´ˆƒ2|B”1.Ô,E2Úiù3dÆÏ¯è(—	=t”´³æìâDjqÌq9&öÖ‡ÍÅŠúå¶ÕÏ]¹Ğ’¬Ëç¾Øc4f…™QŒ]î(ºô«%}!zÚ‡‚b^hÄ"L{dÚñ{gñò±—Q$1­xÈº1õËU’Ÿİ÷Dˆ-v Çëfì,l²<u3I½º+Ö>D;ˆšWÁ7Xãß¤‡,4æxQ{Åé axÑŞ¢jbIi|ôcÜß_h•Ø¾b)ñV<âío>ŞòFI½?…r-]ØdxœB.¿›Œ7WÆSãØI‘=`ì#}Ú÷…®áÕ~Ss“-º5LûÔr÷Fë¯5³bÍpH“bt¦¨¼D—¯ë¬E¹|fÏ›ZŒ£ç‰3“ŞBŠQÄ1Å(Ã³2™¬Y#á&±uH]]Ïí¶ú5ô‘éÓp¶x—t’ÈPH1ÊÒƒBŠÑ.mè¤=JK-Úû»:ıùDí)¶Z±B*Ü7õÀÇèãçË®"l=Ñ®j/šˆõƒ+†Ú~…A‹cyŸo~ˆ«	¿&šü¥7ÆcÏ5gf·8óæ· ŸPNÚCˆÏß¯8*Gøqô5îWÄgß¶7½Ñ`]S~’3ÙRäkVJch¬rˆï¼UÆ%íƒEÜ×ló4øøcFÜäu6£ûqÌ}Ëğš^ S³F5‰uQ@gvX¿†²Áp6XŞeÊ$2rß²¼µû¶Ëg;i›¥–í}¬§Áº\0X¯Š(ãÜîåÛ]d¶gG½âO›nZA†q^.˜|Ïœ[‚…ØN¬;‹õÕiÄ…GÜÏÃ/­-–Åz¶¬œèc2Ò*Kıá9ÛùY'%Ïœç¼½éÈŠ3ƒb(OVß_®ÚäºÑç¾!†“‹ñIaæ·29¤Û­©±kŠŒ¢Ó‹8øÁŞİà=â&8½­‘wMæ›¢Ë5ÀGòN#y§in’C¤$:
û‹ÓÙí°~eóÀÙ|ğ.Kõ$‘¡wšåŒ†¼Ó].éI{”–Z´÷}>r˜"^yñà½Å©Loe©ÿ«)b–÷V1ŒvgÇïñûŠxú•†Ûdq<^³g¼bdİb«j‹å$1m¸¼Ğ_b¶Ò—qÅÒ¸PùáŞ¢)‡ø®¸²ìD¡B[Qñ=èËûÇŠéü\½¼µ-Ç›æÿpâÿ·¼û)<s|cìîã³<C‘Àx¤²·ßgæ©ogçãÖ8áCxOxùşÒøR°¬ú8›ÎĞ@73ë~7›Xõ}$Á$}xmlÎ6± ‡í§ú¶“PÌáÕåˆÂ‹yÇó0¼(í£­ÛU ‘je¬NŞã& lÑp¶hx÷ŸI"CáÅ<ì¥:ğbîe;“ö(±YjÙŞ÷E£ã¢‘q§ş}ßÄÚxË˜ù¾ãé¦lğ¬ÙÄÛDA³bŸH”2ÍQÄTE¯Şm‚ùC¥ˆ/±Ï%ï‡HAb‡íƒ´â>ˆHJZ³İ7í¦'*#
6õé>ˆ:ŸÜ]PûSßØÂÅ}q£eØ©ÖÔE–2¶”xâÜiy«¯©Ë;Ü+¥!úrHJÒ—“ÜËóG]“Boƒüw¶ê[ûæ€ã[C—'Œ•n)¤ŒS£‰¯ˆ÷ŠljWí„ùìvÎ7)·§œíüNf•}©s-wÂ{#„'íqùáŠ­#gz‹]sğiH_Ò†cí†›¯+NB‰Ë—÷\ÆcF8Ó›oš¿)Ùã³ÌN·Ø“]qÍy<È«Ú;§ğÖM´»øã›&‚F®8n!&,c§nyi‡¹Æ	şo¦çŞãª÷;ÍxÎ¸ê¦ˆPÎ6Ís„xÛ×œâ è5cî~;Áæ˜‰ÆqÕt/(B4¿xÂ
ånÿxI½f¬ìódÚääãxî-ºÄúñÚÒåëS+b ñÆş5a„³Áéaé#ãË¸‚"†Ú+¦ˆ—§ê_Ñ§†Ç|eÂêãw{ÜÊñ‘û°“rc3À[3œ9ºğåòÌx=ã]o\‘=ïòCY“ÊğÅ,›d¿b|ĞmÅ“¶Pw›¾Ë/‹<Ã‰º¨r1§ù5LÀÙ5LÀáeÔ^y__¶ÁÑ ê{0sæ×0£ñT\¦¢ø5Ìh‚ÊÅ§úÚNh"©Qê;ƒ±~e'ê g'ê Ç,üM"Cçúñ\şMË¿iÁR‹ö¾Ÿ¨;¨«WRıû~s8¾İ¯a¾ìü%Ÿæ/öóhÀzàc˜àŠXc<åy3õ—ÇM÷0a³0á’]€zãk%ÃİÀ/f–ãùÜ‘ÆÛ_¸eº÷z>€ş®CÍ¡¿¿¡•µ[éÿãXüuÒãoQ±kÒ_³}õ"é®éS¢‰C.şŞáªÉM“»=Oîox§år‰)ó$Ü€³$Ü€CúìX¬òÑ›b9êT*Ú^<xÒV…bS°<	wÒN“óáíT³Ä¤½*Åyc0	7 lpş2Æ†ãkÔšD†Îõã8M¾€Ó´Ç°Ô¢½ï8Ç_{çûMÂıÎn€Oƒx¿Ót9ëÉ+Š+îĞ™÷{‘-Ìw“]Cøë¼H®‰‰’È³¥û	ëxö9¬^kÈ—5’¢Ğñ<PXuxšÂ~_C»¯¹ü86Ùår¯ÈMóvVRŞû›Ö†™UV5WÜ¡[»^qË!L·ÖYïgFCÑÍ,ò¿ïğ9“¾=Õ!nãU\‰¢Ro’±õ‡µYÕçsB|ÿ`V+Gş¼u†øÈÕ7P¥C¿pÔ©lRJ5›6à™¢ìhÉğşP6à“ûèêK0šÄ¬…şšj»ƒúÊV g« €Cü:×­€>ü•ìM{\wh–Z¶÷}à¸
ò)t{­U€>ø¶¢Ğ3¡ÆE+	W¿JöÕ®8	"³O‰1SúvÎ¬¬Ø¢¸üÍî²OxÓúßşV)1ëIá—I6ºÅ~ã­LšEtyÂîw67 ¯¹B; Æ¹bÃq\èáÃ¸zEãóS©C“q‘m+:L_õ×ºN¶eÌtÓ|ïÏŞåá†@‡™2SI7•(BÚ}=<òÇCªMëŸÚ{üµ¦KW±èCUİÿZşÛÃ_~Øı‰Ó}ŠJ”w1§úBD)$¡ÂZÄ÷OI•EÓåS=‹c9“ø—
¶è&'3ŸuVéèbìÔFÍ„å ‘^Ã™±U-j¾ß›“Wc–~¿7Ç ²K¡ßïÍÑ«`Œãû½Póe=çH¯vÉë¸q—ş–ŠÜB¼Õx6¦âÙ9Š@¢häLë8öˆwà>h_~ı×—n^uº.®?£"¯pnpœ½AdÅº¤í¤EÂëo‰ñôè¡h£pˆï^¬²Ş§l;²<‡c9ïd|û±Ş;ËŞ”šbíW§&gÒ¥³ŸV†lS3 Î¬]T2!DÇĞlhp3I×CD/$Şëú¶1Š¶1ïPbk¬_C¹BØg4İß‡¸ïiˆ›3z¬â._	hç’Û?µŠ'†Úµy±à‰xóáV²s’»+.‰ˆûòô,W,Ñ­ØÇá³8ê1|Áíš>W¤RÚàÒÜÛÉœt»	hß×.õŠUÌq^áˆB¹+ˆ2Ä=Óg¹zqE'Zqpëò­©¿ßôàO#€L'Öï¸ˆ÷ØÉĞOe©¯ÂiCøÈ)ªV,‹>>S³ÓŞ~·”Ÿ7ÛûÚ‡º•s²ëMö†ß6w+—K7IÛ&ºÿëÅßÄ1|h‹« /z~ı–Ù9·è÷£ô—RÏıtr'å-ŸN~Ãù†§†İç¾¡6‰¿Çg"¾³èú6ŞZ[JP>9£-¿¢8»¢8\®.%ªàS4‘£IåäæW´ÖQE‚¿¢MøaÇY¼¢MhİÙám@ÙálÀÙ–=à°O9zªÛ²}öŸµ‰h©E{ßgWú³¿_Ñfäõ‚W´_¯O¤'gšÉŸjÿ¡Ÿœú>ó^LÑ>ô_éŸĞ2Rê×µ¦ÖÃ¡F¼3Wl~„^°ï'´ıŞq$v:?ë7›w¿>ü?[´endstream
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
xœí]Ë®9’İë+´.À,¾À`€ò£˜Å FèE£ƒÛ]S(È…qõb~¿™R*3‚‘©`Ò™º)[6`ß{ ñÁ8ƒäùåÿû¯ãï~ù¿ãKÿÿ»_R'/İß7ĞöU<¾|>|9~9|<|Ìÿ~9\‹¸|á_/~¼~¸ ¿¼ûïüÓÿõñ¿òo¿ÿö÷üß?ú¯wø|:ŠÔı	ù×üUI…OÒÚŒËò×îÃ¿şúÃñÜ)¢”Z%gÜ¥-è÷7ÉåRµ²RuhnôØ_uş¿º°¹;*ÉpL*d´9şùÏÃ¯¹Š¡m"úşÏìÏ°z/rÁÁyÚG!ƒqYNŸŞ&BÔŞ@ütğN	%­RâŞi¡BLZe4	ec–9Bƒ6X-Íñå ñ¨3lòç²n²Œ·êkŒVÄ•Ë5‚öèêÏˆŸ.7Õ%­‡¸R*™‚°F„í{9@|ìÏ	ácïa@R“ò~É#2ÿrÕ:(½ÓDÌRÉ]µ¸ÖNÒ« Ä¡\B\n€tÕ¹Vë­î¤¥˜‡HÒ…¾ìW"xÓ¥ìk£\`û ´` –ƒP*êäÂ‘ŞÆ!:´kyìÏ	ãCïa£¤¦åİiâ×€9%½ÖÉÙŸo˜S&ø	sêñnÈKá}¶nôùnÈ›ƒÔç•G‘ÉfQlN#Í	àF¯ŒÑGXc6B2®4§%æÔã9¹l©.DñlWRzîkD(2§Çæ4âcïa@R“ò&JlæD“MRié±8à€ÍLîF
.¨„Ğ<BTñÜ`€[k…Ò*^F4Ä°6¤ 'Zë…Ó:Ï·P‰ EJ8âD€65"thâDĞÄ‰ ÷ F(©IyœJGœˆjp¨·-rÓs³
4Im.æ¥¨³TòÔk0'Zkr“6	r"h’èÒ2`(X
ÔÛX#D‡ö!-ƒşœJ¼ï=¨HjZŞëqb7‚TV»Òœq"À›™-T”:b™Ó€æğ<¥ó!BNìĞ uƒ°9haN8à€Í@Eæ4à…9|è=¨JjRŞëqb¦zqşYb%q"À›…”)"éì aÔuÓİŠr_”AX­œR˜£Œ"Øà‡œeQël•P‰ EJ8âD€65"thâDĞŸÆ‡Şƒ¡¤&å]p"(q"ª0À‘Ş¼PÆf£¡ã
ñ· ]–Š’AcNŒÒç¡fsG '¹€ö!iş -†‚¥@½5BthßµCNzj’š–÷zœØ©7fÁ„DÍ©Ç'°Y7 œ±&jŒ"sğÂœ 3çäräÄÎÎ" æÔ£Äœzq"À›ŠÌiÀsøĞ{P#”Ô¤¼×ãÄd•È‹>
gàˆØ,åù</êıÙÃhû]ŒFcNTRy¡CŒ'f<ŸÃANÌh>ÊC%)àˆØÔˆÑkû'‚şœ0>ôÔ%5)ï‚AéˆQ­€¡ ô–'åà,^¥nw)/-1'æÚ,•hŠµsÆópôZKÈ‰@. }HZ ?HË€¡`)HoC½¶ïÚ¡?'Œ½5IMË{=NìÔ]4ÉPsêqÄ‰ lÖ(—›Éc™Ó€æñ,¯Ïëò¡Æ3CÒ¶0§+ZšÓGœpÀf FŒBsğÂœ >ôÔ%5)ï^‰›ƒ£y˜Ä9ı3
V|VõXıÒ\éÛO‡î¢{ÇO¿Õ%h}ùïÓçƒË?«.œñéÇÿR¾ûÏã§ßª3÷ÈûâGäùÌÏg$€Öå—Ì‡Ñ—ªÒRÂĞrüˆ'ù©ø’4eëAhMñò5~$•ˆzK
ş™´¦,x¢Á ¶„²¤¦Kk>|ÊCõõÆPœCÆøÉQtnîX£µLÿŒM…ÿ|E7—UÚ›Š²ó¦âÓU'ÊñëJå_´æF –Ÿà¿rQ¶©b7
Uï‹¯è;êGÑ="“çUtûfyÎëÏt]á¼Œ?ÿŸgâ3šWûNôl=ğr0yÊVIwÓCÿƒŠ0°‚üñËïúü¥cñeUVĞM9E#òg"*"â
~;¼ıáGlœ±6å_r;ãu \hÙ”œ†Êe¸òŸ(Ë œGUe¡ˆÎöhçZf£7_œæ õSa´ÔF¿Y³ö›µSfY[OÄ¬»ÏT„\ÍÚ»)³ÎîdQ%fİ}&¢""®`ßf2ı@x7=i³.FÆù®zÖPUv“ú^+âYõn( +S"=Ÿçğb¼c)Š~Ç’rSi¾e)5¤×¨ú]Ù%EİGÚí²˜«ª‰
[’4é$¤íÇsëæ¬é2ŠìÕ˜Œ›&óPjp÷ûÒÜJ?O—V7ÏöÒËĞÊY†4¬ü
%â‘–eè~Œ‹0íJÄø¡M!ñÈœ@ˆØÊY’è‚¶„V– )”•‘4íˆ#ED¯J±Ò¦’Î°¥¾Òhmı
©–x–Ë5Õb¤°¬€ˆ*‰…¯°LÔî‹Ûùî÷æ•½õÛôíú¾ˆÄm¨²HK{×¥gMåZjÚo |;L©,2hJ×*œeU¶!´3zºw;$Ê%<Lˆ†+&bŸ<OPçù‰p-Q1_Ï“|w?°µ¡Fª%¶Œ	‘‘…ğrCª ¹²©”6ˆˆf£æ Şÿœÿ;¥‰Ë\Õ¬ˆfæÊ¯ò+¾Bª­u_YğİÖü¤äCÂ¢—oKæ ºĞ{èĞÜHJeöâı®ÁÙÄ·e	¨LŞh)­–xkø¶å'H-t1”ÊBÉMÈ”ÎÄ>‰¦HCÌTUì¡ó™oxU‘jyï¢aBäÎs-‡?í™4ÎÓ–j¶õËW2tÀ¯±’Ye¬>Ø
Bj¬Mvpx?•H…'›©0¾†™…˜Qhƒ†+Xõ iBEC<‡­åN‘TbX¼'ÏÒä*òX¾ökZÙîÅ&FÆ…¨ä+D—ÄxÂhu{õó–˜FÅÑŸïÑ¹?zè›@CdÄ’q°‹Ïî>Ë¢Ç;Şê¹Ol…¹¡Â×#Ã†4ûğÉ<û¦­C1øˆ;D Ş K
Rå’oî+;µPJ)ñX|Ô™_öÒé{yØrßG$ eùõJ
+ut&ÏUû`Rìòë³T„õJ	ñSÆÑÇ¨!®µÑ+/×m
@^0€p-ºÜ²î˜:¨1‘•º[@ûFôõgÄO‡ÔGÏ“¦C¥×ô5"\0€. —ô½‡5’š–÷×ç×?Pv‰™^7MÑ]“”\™f3ç8’éäÆb¬:îs+ŞÊEQ	P‘PÑ²·sñ§_™‹PŞøJ?W‚ŞÎD(oU;¡$O¸!æ%húL„ =U“Mñ[Ée5ÕQRïN§É‹çæ3ÖØ&9|ş>û›AÛÏ—x| ãµ–Q ”¹QRÙ“iHbâ÷‘+b|µéD‹elàt›EÙò7*C~ÆûÑw2¼ÚÑ½g>7jĞSCã7?‰å­NÊo~nÃgM“7‰Š‰†OcdGbS"©—íİƒí8éËÓ8 Í¥Ci~P¬B‹¡n¢P>xÀÇİÖˆÌñ)µ¤a„â6‹^5My¯±;“<ÏŠ~%a¶ŸË©±?ì²S“µ¦0ÙM\Šm¶oÙİ©¹4€êââØáp9­ı}oà¾®ù\İ°w~}´Š7t'ÁóGÎÙdÁWò¹WaöÔ/ Å°Ğß¿²ˆ¬'Îx¯|'9º‚S
—;b»Û2m÷‹N2ˆŸ­È›ğNÅ,ËùÊ+Ñ7Ú•˜”÷*[`H¸ª»s:9å
Ä¡a9A Gª0B½Á¨ên2çkú‚À=®Åİ¬.xå"Üz-Ÿîç°õTÜÁ¿Pˆ«_ÂßŞıÖ½n¿åˆİ@²Ä¸±ïÓ²¹¶Â¦–½øz¾ÚŠå.[Ï©pzg">|r÷­¾4„!x½”s-é\Å&iØ‡òmÇû¨>JEÖ/·F¶‰ù}c²QHÛN”Kº»<`D;Ã¡¹Uğ×Ò²OJ,ˆÊü>)!?„H¡µùa7j©h:«}Ê[¼æÈv=/S"~g4TÛœŸ¾ÄÖ«ƒı;öÕ£Ë.œ‹ª{(B™ |öü¼„ø	á)	#“³±píæpXÎwá«/ìİç»«ªLLGå’>ªp}ééï>ı]—C³lüLÂÀë¦Fz‰ªZâëw¬òB)Û­Ì?¬sÂh›ÂO×I„îŞv‰é~‡å<§‰i ˜înC«ÃsxNt°W*1åê‘ò›í;±6$dÊ_•G¦Ÿò+”~I-ì}Ë‚³!ŞÀ®¯ùU™[+²ˆ‰Ä–¯•é‚³öÖÃEa~‰>³ƒ¸h òË|ÒÛæEÚ×ºÄ[B¼—ÄË´aİ?³óµ$ÖH=^V/””øZºÏÛQÃò1F»?ãWïØñ4Jî^‘Êî°Ş;• ~B¸µ"i-½*Ì9–ó]8oTö„:ÅRºİÕÌ.zYJ7ÿ’TPâH:@Gk0j²«Sì6ÿ†Àã“7"ÚĞEˆ`£Ş`ûFôwªy¦§§çváÓo¾úÍîúÆ‡)ïş¿Oèßı©NøY4…/?›³†Ë[1§—[lÛøZ»}êf¹ƒídÅzÚì–Šõ¬¢Ê1fËÈXKÒ“Fmºf<o‰e»Ë'š’¤îÚ5Î¤9bU…ÎìÛßÊxn¸ˆU?UÔ†²$ï´"ò@$¶üTRÅ™#Òt^êË{®1
é'jgö½Ñ°ª`À¹Yr×g¼­	¸CDï²ZWùç¤¥3‘Ñ*ç<Öœ2³ÆÒpd÷.Gå+®³%¡œı–qöºìÑoK¿g“S+l„š I§ç=”†gsÇXÎmó¯ŸV9æÿX”ImhÉ^î)á¯Õ¥Úi8q¿‚×YqÇ3»uI‹ßX¨µ£ÅË6¼Í[q¿Î»âşöşæı’Ş6&±Æñæı{J^^_º&{ú*¼çnå!$ŞA{ G¾6™ïó6Ñ6.ìüQŞm¨ˆ!n³àİ†MŞN$¶Ë‡–ç¨k×l®İl‡˜gÙÛ FUEàƒ­eh¹eVJ(’ÔÒğjÍ£?|¢­ÁFRq“JC¤g›p	1›5n_Ødhatş©*~í¸<°S,xs)±Í}ÿ+pŞ#.|»û.5º0N*Ö ~0oF|n4¿ëË?C=“ÈzËœÌâ£ık\·S1A±^ESÅc¡+\õ]FùXóµ1S}¨lùZ©åò¢q’=@ ~?s…m‡çİ¹³Óˆwõªá“eøK@›—“¯¾ˆiáÄ†PÃè.%µlN&Ã½ßù}+Ù å™k“{ïŸ·è~º¹r~€(©[áòP0éòŸv–O|°‰Ağâ·ŠfŞ¬YÒ¹–ğ3ŸÓÙp"u‚ØyĞ÷ëÖò¬n+®mH%]!HVÔèÃ7‚J-9fkŒ˜5,yÃâw=aîİéİõÇZ™:ƒ…´I y•—zKÉ¢
B
üMà¯“ GY“MÑØæ¾ñûìØ,/´åM/>àÍ7ùùX»¶ôM36tÙğ¾EÃó>3ÑŞEöÊÌgb¶ÃËI›³r×‰w×Ú×—/è³A<7ì›’{|¾¯4{>Ráâ.]?Î°" Bª­xašª’RNèî$i·!xQáEğ™ÀËëÿ¬ÑÃ¬ª.wVŒ|_¬Ük‡ÎİIaVa»¥‰–µ'O“ü.«­X®6„«Ä^1]W,6gîY€â¡*r–ØQUAØDŠìu |ˆr“Læ~&½­Ùî$õÕ„r`jKÚÌ ÿûä^ğîúL dÏS@TavL4%²£‚_Ô4Ä©ïÈ'J¬;\%i«ù^ÕE3Í
¾cwö"£!noÅ Z¾ÏsÄ6›Ëûu’x‚ç·›×XŸóL\A!ËŸ÷ì_°Mİ¿7Í,W$Ïñi,ü[6<gòÏo¯p»UËN÷±ÉäÆÏ»|`¸2—û7t‚–¤é„í*(“aóon=Im1—µÜ®´Â]íƒ¼Æş£Ûw´é<¸!ÖTNf†DıÉt·Ü…®È7\aMØ°^±ïÉG"Èş+dKÂò^.¹iYÎ6Ì©»uˆ«Yu§`œÇ@÷7ÙiàüåÙâ›–¯´ö-SŒÃÅ~ßI &W)¯ôNxHVxR:_ı¯3î•â§ƒ6"•’µ×VDé£Ìô’>i—%‚Ğ r'|&îêÿÏÿˆ¨•ú|õ?ÀƒÈ•k Æ(£Ğ3êÚĞØ€£÷Ê} 5"thz¯ôç„ñ¡÷ F ©iyï•ïìŞş{_¾ŸÆû@ù'çM’ Ó?c9ğŸ¯Ã²JÏrÈãZÏrerS…ò%G)²‡IïHÓk3P.yæmE±e)=qÑ/`1‘|¦¢½~JÛ4êçgÆ¯v¶Gƒ÷z§´±Eß–ŞàL¨ŠäyØr´Üº–šøX3‘ù:LÉR[¾ÁÃûTwÊ`XF¬ÈÉäO:.×´4ı^W›ğ;çìÃŠ  GáÛAÊØäœ¯]şF‚†Ğã&—ì|u§ÙÍœFO]¯q÷Ë&÷YV$©osÑØ&qs»ù×JÈíO¬ñ~Â#¦!Âÿ¸IÜ-WËtH>ÁŞGò-e§Uäk¸Dõ›2©õ¬²Úy{¬m•çe¤;İ”½ÉFÂnR…·É÷†ß’lØ^|»(‰Ä*6pfÖ«»Ÿ‰I’lo²Å®§»€rĞ€
Qy(ì¦ávìúŒ«5!Ud„6êçónøG$Xò+N=îT;—©Ûºi¸é²áZ’5ˆï.y…‹ñJ—6½NòvÅõª§“¾-`µÛrF‹T‰Ù±>ËY”¯¨ØbAXaíñ¡Gˆîy=7F¶y(‹ßDØïÕkUÒbı”ìîS¯•l7–x­ .÷©÷L|ã]=Tt“’¾,âÅ>hU
eCVk‡hÈ!çWô‚·ØÇZe ñ1è5cnˆ°n“¡X6&õÕÚ•êíJvõñğñøåĞÕóùt©ûÓÕr‚¿*é¢ğIZ›qYşÚ}ø·Ã_8şÓÛ’ÕÂ»è•ÉE§ ¼ö!ñÂÏÍÕÆ:œ&7‹Ãrúêw–7)ïUò/‘p­³Âië“ÇB8",â àHN¨˜µ¥0jD®17ç=&ë„tIU*®ËÒ4J{˜÷Z>İÏ!ï±°íB\yÀMCö?Zwšûidº&=ZvÁgL1£÷Ó X!
'1£P„ÂùäRÆL„„ˆn:3•€2>°kf¿÷™ÄÑYP´¹h¥´FŒŸ”°Ş;åâ™Ãa9ßÅL²°woºM:eºµšsÙ2ÃñÏ~=Ÿ&x’ñwOÆj¼å=Çh›P­!œGx“™¢™7ÇOØr}á|ùV@×è›šo™kx è¾|³¡Õ9xŸ>¿t/aüq•;)b°±ğğçpTÎ“¯'øZ›3_[ıäë'_¾v××»xç™\iÍû¨s®KÜZ’D«ì/LÛ/	fò2Â§Ï'$eœÎ)i ~Â¸
y5œ¤)Ipå|$øF['¼æ¬ ]•¢°Îæ?X**%¢ÔÉCëÂ
gSTêò´ã’ëÎŸ"YÑÅªÑœİî´:¢½¡öèKÑ! æ™'‰_I<ØYW–8ªä¸fIÀÄ§.õò`Åq©é'.³^ÒÛ²ss7®ßj)ÙçšÙôYtVƒ½òƒ.¨Hú$‘:YQh~‰UVCÂw—ÔÛ«j§[ç@-¯Å;=:ÄçšğY@Ä[ä–ìçI…†L:>;ƒ´cùy‡ÏÎĞFVQ{&{§F®]Ù¡ıæğos’w‹Óà«<{AğG»ò!IKù³kœ¾ï êoú)–	ç¿È->#Ğ áJíøñğoøŒá)endstream
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
xœí]M9r½÷¯¨óâÁoÀX@ÒH|00>>½;65÷à¿o²*»*¯2™™ªî*uÖu?eÉ`ğEğ#˜?ıó¯ÿ¹û¯ì~úüëÿì‡¿?ÿú¤Uôúøß®şùÀr»dÒîù÷§?v<ıòôKùÿO/"/üãùïO?…?‘_?ÿkùéÿv´û—òÛßvÿşå¯¿¯×~Š”T®ÿÅòëÿj´O*dí\Áµüµ>üßOÿö§İßK=´JZ“ÉŞúc]šß?ÔWƒ:¼Z°ºÒçöšÃşêÂ:”æX²z—9ü´ûß¿>ıVŠ8ÕM¥0ü7ú3/>(§MôÒÎ¹¤QvU»Áec¢`9¾
Ş(£1ãÁ“21e2ÍÊäè¼mP¯•'ës±„'†Ç"Îé`}Óà¤¢%JyÇJŒŞİ„¤iÇêÇĞgŞ†ïŸ¼ÒÑg\à¸SZcˆ¼Ä=Õïù‰á¬=û?·•È5uQßÏÅ"“:õ:“^{¢<V›êÚR«JÍ¢ÎçıVêNN“6-Z”\`«¶˜ËIû¨ı û¤]­BÊŞ¥%2½°ú5Úbíiz9*cåà¼é·s‰=×¯éeÖ}‹ŸZÏJdšº¬ïÚ¿ı‰§R Ò¡zôç‰á”ÉŸq8x5ùÒÖ@Æ5ÏW“·1Åj¡åÅ`‹mQƒ¶Ãé„‹áÄpRÅ²sªCõTbZŸ¬N
ÃiÀëpòe¤ú˜Ç]é!cMğPbƒ6Ãé„‹átÆÏ­g%rM]Ô7tâjNLµq¶˜‘o;‘á'2œ±Yò®<Pş-µ¨WÎºpTôÏÅ“‘w!˜–3eå“.ÔÅ91ÛÒŸŞ[Ò¼Út"ÃNd8c3Vbƒê×p"kÏ¾ÅO­g%rM]Ô·àD&½áÄ¦TÆPoú-(ã+jĞXJ-0µœ˜)­8"j91ST¥9Å1sNdzaõk´ÅÚÓô2c(.…õ+‘£§ú=·V{jÏ¾ÅO­g%2M]Ö÷õ8±vo²Êø‡á4à'2œ±Y5(ï‹Åm†Ó	Ã‰áÅUÛäräœXÑ"Éèv8Ñv8ñ†ÎØŒ•Ø Íp:áb81üÔzV"×ÔE}_Kˆ­R´±T¸éD†7œÈpÎf¹ĞµKÅ\8Z4¦UÁœi9ÑhSüIŒQpbÁ­
Ú&Ï9± N…˜JLÀêÇĞ¦Şp"Ã›±[ô¥~'²ö4œÈZÏY˜iê¢¾'2é'6¥2†bx£—‚ælÚ¨º ¦ë’o9±´´–)¶œXp£|0FïšOziêÇ´Õ´‡õ2c(.¥é·S‰úR?ÑË§öìşÒú¦Ä“¦.ëûzœXM!D[#%1œNxÃ‰çl–³²Yb¹3*†Ã›áÄq«L0ŞqN< )¦2²ÚAåpzÁNd8c3Vb‹òáÄğf89ôÜzÎÂLSõ=tâ/«1â¼üs³L0ãy¾ˆ@çE„?VúéÛÓO_K·¸İ·ßvæ¸@süëÛïO¾ülÉùİ·¿ìş©Œüçİ·¿=¹ú@= é+xÅ
Àè`Ï€9 ñ{^A ÊŠ%	ü, M—«şå[1‰ûë«ÚÎ¢¯¢úô±Û¥Ö>I%I5‚:jŞè	›ËD>5ÃW> ?a²(ãkW!şØ\šBú
¶7c€Ğå¯àP9ÒÀˆ ÀO¬0èLñİzô­l¿õm¨/TÖe€ÙÆú2H’fŸEaÔæRâÑ}?ÚyNRÏd{VE_Ş‚U‘ˆV"tÀrS1¨dÕW*óe¹¹_cØBïûA[€¨`öÉ^AßöícÅ+}%/îP§ ô±‚A»†KĞsàÈútUïšÔ-ùÆ´\—Z.ò²ó±ef=«İ©_qAxì3iåÂâ.ûö™svœ|§Š<ª1-˜_ş`–N¹m¡ş$Y\İCƒF-_¶çnfLú.ô§½nŸ5|—Ïµ‡æ|‘OÈé¼•.ĞÀ9ƒ’ÎRâªÏòX6ğ²`'Z>aÍ¹sÎúÕL§—nWÇúÏÏèÔe…Ji¼SCj;ÕDÙ«&Èn5œn¿Ê—¬üÀQ¿ÄzúØÆÈNá•Áê9Y¾e£ù•aFåe…ñóQ¾4«)+G>Ê
KÀ€ÆçhÄtmã›nh½4j½®Hkvg&Bf‡Ÿä#Ciˆ\q’O4°ı‹¶Ij;N½E£ùÈ‹yi‡fêóQ¾ôbuÌqä£¬°tÁÍ€X’%s;|g{ÎúÖ~Ïv†ëß0yïN½¬–,j#øTğÔR
<A^
ÁÊŞÅÂÚd8ãâI)ár™
À…ø4öJ”º'Ğ=É‚A
<aP÷²²ÃbÊ†àİ{v#»÷®ÆC<õãoÆû,˜é{Ãø—`‰…´<°‰xäœÖí¢âŸ¡ĞâK€àl@Vf˜ÿŒå¦æG¶!°çi1Xá/ >¬LäèB÷»	ë¢±ã@ã8i›TğF“?¸“ªõƒÂ@§3Ÿ.å’MrØÀ}şÎjûnAFxÅ¡îŞü°¥ÑİãÀÕ»k”Ò_P_¡S¨‡ìl¬:È€R–o!å€Ğşî}ß>f¬ÄÊİl»ê÷bS+Aìœ»ZîŸnY^Ó±{£„ó¹Á.ı!§‚E€Œşpï›*làöÏÈ]á\N¯°ı]+fJı¨dâğVÿèÎŸ»gµúgDfì¬÷Ï&õI¥¯Âşv}wËõºâ¼ÛÍúñfZijÉ9¤Ó†	ÌZ/¬w+Ì$;şüÈ°Å×g?_¶tt8…/AÑğ†5İ9R¼KïT5G06Š#§aTø	ubõ°	Ã¸ ›~*ÛD°ŒÕ%	0çùÎæ>ÑØ½È¹Oÿ
F;}·ÙŸÙ¬vAWäôı0÷Œ©Şš»&.í×£{Ú}Íñ¢ş	r°©î©B<»¸âxß½Î¹®‘îr£ƒˆ³bXM»œ³~hßóT'Z;Úœ(è|““¸sNB‚Ôş¢ËŠE‡)$¯²ÆĞ§Ì5©?ùëO¯0×}_Ş?˜ßW*ÈÓ¸öLî^Ù+ä¡²/3'66ûÉ[¯ığch5‹Û¯pØÈ0²ÀÅ„Jv}!¤IŒHã¥¹(:ìßÙ%­…ªãi¨nE@Cz$;‘ò~¹÷Œ@>·¦öF	5+h/?,4ş&N5Î¢¢`[f>İ¹Ñš÷+Vlû¯¬HÒïíÇJı”EîowowY$¿/®Ş‚AÖÆÃÕnV‘‰ÖYËñ}ƒ—Ÿ-Ecêµ\ÎÎå|ç]•KW½¦5Ê)nÙ'F+§)y›[õQvFµi›Íq®&.‡ãYéë=tÄñFÙ¤È2-Z*LÁyj¯¢i®WÆ\/ÚñÏ5¿ÜÎÓM#âúÓ…J¼úı§ë+röxS_m/ùjS©÷´µî6Fğù²ßÅY
[¯‡g„ğ§Š‘ün¿ÜWƒ+ƒ1z_Eç¨Õë·,Ç÷“òÖP"1HÇp.çğêÂú(Ád1ĞbL¶VÑÄ—„Ô´j"7ºAòÈ¦*¤^1ù$Ÿ]ìÓ›í_Áô@r&4—âí1i5ÜqV1)G±Qâø¾Á³UÑúzÿtË|c8—³QF4±^¥¬~Pâ6)ÑÙÙ”8,yLÑ
ÒY?H’äÂ^•Ám( FV4Ø#çú@ÆM92{e­¯S²Ò¥Ñªàb¨Ó¯3¾ç¸×¥8›¹–ÇğFÎF9’’Û®.~pä692Ğ|”ÌıàlF¤)eh˜¿‚PXãíóĞ[?Ã ˆøK7&†[¹JĞçh¾–	sÀ+RÉ3^ñ€åú¾¨)O	½ñF+ï´õëÍá’a"ïœœ2ÎÆì…Ã¹œú—qvH²M’Ì(›Í½qŠª%­ ï‚cêFÄ CìÆA¶æ”y£5pˆ°^jäİÍÒ™‘ƒ"]ÄÛD3\w¿ë §@(¨ëes9æ?½ªÖÖï-‘wÊ…œq|ßà6+ëbb›nçr6ê‡Õ¦~x“~8ëñYÅòe&\Oõğ¡oáC¯ĞSwã!á´‡Ëw™N×OI9ËŸQ—¢ß7øáûaT<€pc8—³Q—iLı°QaÎğğ™Ûô™fôğíÛøÌÑ”‘©}&¹¹Â’¼i¸âp7 Ğ9 Ò‰’–ÅÂsXgì‡P¬ì(v}×İÔ>ëI>Æê¨~2·@ãûYE¬Î‚éÇp.g«Àº:kÊä`›À¦Ùà*œîşÖã,ÂãÑ(ëCt©Š¶*PéÙHß7xre4jwøÈ'—3†s9[¥b—©RqùõAÅ›¤bgS1îÈ¨WtVßö8µèÑç÷.Ïº£/›^1BtÕî)ÿB9ØÈñ=ÇƒÖÊ¼HyÃ9[%<ëé«¢¿ám“ğb˜Ox¯²†ÛM†ÅètEÖÒŒ¸6ùW|ßßœFƒ6*¯sM†Tò©xïÜxU/Ú#qçr¶J£!×Ü§œèA£Û¤Ñ<úU»~ÜˆÜtÖçÄÁ¨”±æTÓÈµGKX›Nò©º§Z­Üæà:æ*[›˜Ğ¸kØØŒÆİ>‹-˜Â8!S8dhúqŞ˜é3|ßàV+)g‘‰1Šs9[õnÙ×«ŠŠ‰<¼Û½›ÓfAf/ÄóàDú+Öıê‡»Ûœ»»©›±¤†wêáÑ2Y
ÙFËñ}ƒ;¯bŒ&ˆdQœËÙ¨›!ë=ešÙÒu3vA¶ô½|¸ª‡«šœ™õ£°8K4rƒûTGÁhYª½©—uQÙƒv‡ÉœSÚk—-Ç÷^oXKõ;êÂ›á\ÎV½¬«ùö…kùöõ²~A¾}	hx¬]><ä}Mæ)ŸLŒ5Ğøš¾`-r|ßà1(“|ınvëNÆp.g«n&êƒ›ñ”üº™¸ %¨¹O«03ñÂ±ÛÏè^pá0BÿÜkòÚwVËyÁçâI~.Ş_9'\ØŸeë†œŒ›òwŒ*&Ÿİ!-ÍåÂÓå=Ëñ}ƒg£lÊ!Šô³QœËÙ*§z¥JÅTîòwz şbíı0y°õ÷±u¦òzÑ@Í[0Ö)w8EÆñ=Ç£Êg›¼ÈOÃ9ek«Ãaë$?’ˆ·ÉÖF/H"Æˆµ8¶ÿÉàÑ×ğ.ş..:)“]	î*›¤êG	ô¾op2*æ¤I¤NŒâ\ÎV¹˜¨°3æ‘Î»Q.¦ùé¼H_İ«åf$¼v7ÿf|K¡›Q1ã‰åï†hÉ*›“ú@´5¸­yŞß7¸Ç—ÅgeFq.g«DkC]b.S‡Ñn“hİüd]$Z `Ãpy²îƒW_›Wmy¦TÄšÃb‚Wd£Ñ†ãû÷¤HDÒÚ(Îå¼^ı@%TW6Äh¤şH¥B¢¤şœ2(;7ÚÎªŠs¾A)Š´”õî¹é—‹¾|Ô^ö©ª:¼ÄsÏğúÑç¶A¼#GZº|!qK^!ÌÏh¾›ğÖ(úŞé½z–³ihf—nŒuÆó3ìqY¡ƒ=]²G_Í‘ÌIuÃ7œÙGÉäs„3àà+.Åã·€D@ _e·Œ~F=H#ï¨JÁÊ|”5CğœÚ\Ğ4
*l`U¾sA,(x¸j^ØıB’¾%_üªüÑîíKF´LXËÎú¼ùØQÄó5>ï.¿~ÅÏ»cŞ›iÚøU§ĞêZè€µĞÉ'ò=´pÌ–LÛ®øˆ½‡‘ˆè	¾8ÿs×¼®!cäh?“Ñµ{Ğ˜ùGÆÄµSc—¿LÔ¾½J!¨û"Â‹U2,Îäy>c	HŒÃ _úøK]NaĞ¸[up®÷¾IÎÙôÎYÎÉã`¡è!»f.³?†çòÀ*òzx?´€'ÀqÜ§än1ØŸä0²Ã>Õ{İG™N™ĞÇm8z†>nÃÑX
È9"<U±Œ´)šv,¾;Ò¦œEûÎZÂëb0b¥êq¨¤;.ÕİŠ`sß†(ûZîrüBÌ=ôÑyÆ“ó„‰Uß½,÷Œ3¦D]²|•Q„,ŞmşŒa£Jáù©yètùÑ»nîöW 'ïT°Î…šî‚r†¢µšãûI‘M&‹<ğQœËy'»F+§)y›[õEWt =Ñls5q9ÏJÇXœ»'7ÊÊµ¨WÉFoãî¹í‚¨´õ†HvWQ§ã—x®ùåv>?¶ş6´õge@H†¬îŠx* Ørûx{ÒL^iGéø7gËÍT‡èß7x.2]ğòcm£8—óNHsñQ´RÕëFêG|çĞ¶F;.·aæÔ¦|÷´Àúuõ‰ÜXWÇ;…F¢ı©+„–Ÿ|èßã5ãVş!»å_ÅÃ/b|¾9sg]ŒÒ…|øøš«ÔšdŠÉ1|ßàÆªäu”YÅ¹œ27éX©Ûûuo’ºC#ÄşàŒÛ€–S&sÿ*7Hè›ñá¡+Ü×¿Ûî^.eD¥öëÑ×‡t+NÎğv`†W02ì¹şiBh(¨?_‚‹PúÉ/Ïâ+`ëò–*4©±§<ûËĞğJ?Ã Ûû÷/Í8Âz…(?Î_Ü¡˜İ6¸ÇXÏøÃ'
_w4Ê”ÚÄÒ†ïœ²ÒŞ¥$2pGq.çÄz|JÊc}ú;ßı#ôWE•®hôÑh;(O>jÑXâg“t]«lú ¨àÖ*<ªœ´ÅX‰çáõ;£ÏmƒxG´ô‘Ø°©X5ÅQÿÕÎ¾æêæT±Ü³¬ˆÕfog/‰Mæ|e®4^Óı Ùq*;ÂÙ—Ëh	ü_áÈ1Æ`©˜ ğU<buÂF¦€€#…¸Øû‚”cçÃ!§	!/YL¢@),•Ã\	L„ˆ—¬ê]ä8ÿ’F°5ŞŸõdß]j{wgµ’|ÅÃë\iË¾D^ÊEGú›u„RàxÒ”wvÎ>oJƒË#éËQ£RtÉ—Ğ³ÁKBŒT—…[œj‚¯«÷J,¨­òõ‹sıúÌÛÃğæè ÃÙ¤…•Ø¢/õk°öìşÒzV"ÓÔe}Ÿ¼ULz§a§ËÔÒÜ¹»Õ¿Ëaò{wGhÂöôÂg.Ê@bÆQ¼Û¤	ÍÈ[X~örÆQ¼ågQÇº/&İ‡?ó×=v¿<ı?³Î›endstream
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
xœí]M¯c7rİ¿_¡õ ¾æ÷°Ûv€,n ‹AÁ›8Á@3ˆ3‹üı%õå9¬+QRëµÕ™×¸ß;–X¬"ë°Xä­ûí?ıòï»ÿüÛîÛ¿ü÷îõôï‡_^Ì’£9şÙµ¿ß àÂ®Ø²{ıËËo»ß^~~ùYşûÛË§&_øÛë__¾=6şrD~ùğ/òÓÿîÜîŸå·?ïşøoòÏŸN_oøËKve©íO–_÷ø«5±,©š7ã¯íÃÿõò¯ØıUúa–bŒ³5úxìışµ)Ä%ÖP›wwºëkñ«7öAÔ	1ú]µvWªÛıÏ¼ü*Ö®-%şœı¥§%›crå`Óê’sqÉÌ”¢]¬	Ö¶¤è›E¦h°˜¢õÒ@´eR,Éì^_ ÏqqÎ$/î	OK)v (ç%9ëšºĞ@_±Ó€ï_¢t+VSBB<,ÆXSsÊ(ÑŞ¿×ÀAŸ=â =H¡-_e•eGh«Y¹ˆD±À2š¾&Ùl*â`¿X›]’€(tíG0{±±5»SÛŸğ°DŒ÷ÇVNÁ
Ğ?²èCcš¥[ÅÕ	ÇQ‰€öşÑ˜‚>{ÄA{–Ú¶w‰_ÿ RSINFĞœıùœ‡€c²¯ÀÿhSÜ,If_ào´9îsÉÆÉŠ6ç|AtğŸü§ã©ùLÈ®µ½Š´8+Ó2ÿt”ı§ãÍ¢¸fÌ%!DëÅò%"Êş³âƒÿ¬8hÉTÛ6W#y7×Ù ıñ5	8±àHƒÂËÕ×¨
Ñ¼8™ì50ÚX÷©d¦A›ÌS-Ş!Úd—‚fÁşu”†p¢AÀ‘ÀºDD{ÿˆA¦Á®=JKmÚ{ Fhˆ‘¤MNã–—**ÉâOhYJ0Å{&FeuŞ‰·ì/KtYô@b»`ÿĞZ¨2Ğ¶v‰ˆ®ıãQîúì_µG‰İRÛö~1¶©|­Q¹ÓŠ-¬Òâ£t½0JîÔqv§Ëä¶.Gç‘ZB°np§ÜiÅ‰G>ëewê8»à«ö(,µiïÇq¢k¦,^Êƒ8q"àŠ9Ø*S0s¢Ó™lı!|#\Æ³æP)4tI–”ìŒ!/”pâDÀ1Øë	]ûÇ¡a×gÏøª=JKmÚ{{ë,¢T;NãV–,â›;!ZEj	52':a¢ YÃœèdûòiú$±Ûû‡ÖB}p”1tƒVÀ. Ñµ<Ê]Ÿ=ã«ö(±[jÛŞãÄ6d¯!öİiÅ‰Ç˜PØÂ– e”Ü©ãìN„YØB‘b›ò)‹ÇñéèàN+Nœ8Æ~]â€‚;uœİ	ğU{”–Ú´÷ã8ÑQ®¸œ†…pâDÀÍ¼qKÙåÂ¨GñÁyæDo“àbÒÄœ(&Ydé)É"'z+~Q²Ï´%”pâDÀÍ@"¡kÿˆAŸ=ã«ö(,µiï¡uâD’
8[›]ÒhbT˜¸xqhæDoƒXEÜ<3'zÅ³Œµ9ì‚ıCk¡>8ÊÀPØ
[—ˆèÚ?å®o »ö(±[jÛŞãÄ6‚ˆ-at§'NØÌ¿X	~Jf”Ü©ãìN„×lbtÈ‰mÊKÈfãàN+:¸ÓŠ'lÜ©ãìN€¯Ú£D°Ô¦½È‰mwR‹•İ#bÇ™;l&ëyÎ.µUĞ¶@Ô’«81ËÆ™ÓÜ/Áç*qâ!ß$3ÑÑ v”±ãÌ‰G6ë	]ûÇœØõaNìÚ£D°Ô¦½GNì­3'¢Td¨£]Ú¦ÆF_™)Û²^«ófàÄlÄ*-%=pbÏ*1KœØí‚ıCk¡>8ÊÈPĞ
[—ˆèÚ?å®sb×%vKmÛûœØÛZ|Tî´âÌ‰G6k»M+Q03%»SÇÙ¯%VgˆeÊËÿÃRÚÑÁVœ9±ãÈf]â€‚;uœİ©ã]{”–Ú´÷ã81XQÎúh†CÀ‰6²Km¬g4ÉÄ6æDa¡–Ñ2'W—Ä$	91xñ[¬¥@9ßqâDÀÍ@"¡kÿˆAŸ=ã«ö(,µiï¡uâD’
8[ZŠ79YF³H±-Á¥6ëŒZ‚Ë-^BAN»`ÿĞZ¨20¶v‰ˆ®ıãQîúì_µG‰İRÛö~'¶©­|İiÅ‰6“N-Â÷Ş9FÉ:ÎîxmsÔ¢Í.QĞ¶é­ìNeCwœ8p`3H(¹SÇÙ _µG‰`©M{?“(çŠ„¶Ã vœ9±ãÈf¹ y_,£ò£«ÑùÄPÂ"R±C>1”¸„Xj¢|¢ì–è}È”O”±ãÌ‰G6ë	]ûÇœØõaNìÚ£D°Ô¦½GNì­3'¢Td¨£]é2/&vµ¦!Ÿ(Û±ŠóeÈ'†"ñ³'¢|"Øû‡ÖB}p”‘¡ ·.Ñµ<Ê]æÄ®=Jì–Ú¶÷9±¶N&ÀèNgNì8²™Í.ÄT˜)Ù:Îî¸ÌF›R¤|bC³÷nXJ;:¸ÓŠ3'vÙ¬K$”Ü©ãìN€¯Ú£D°Ô¦½Ç‰Ñ‰rAöôC>pâDÀÍD/Ù³”
£â8!”:äc0‚Ëç‡|bv	9xOùÄÄ/B)|ÅPDÀ‰6‰„®ı#N}öŒ¯Ú£D°Ô¦½N„Ö‰I*0à4nE]v‰Qù1Èš0ä£/b•œÃO”İç¼¬à”O»`ÿĞZ¨20¶v‰ˆ®ıãQîúì_µG‰İRÛö~'¶©C1Œî´âÄ‰€›E	š]²&fFÉ:Îî¸]$Ú2ò‰Í-G;¸ÓŠî´âÄ‰€›DBÉ:Îîøª=JKmÚûœXD9Ù;š!8sbÇ‘Íd=/^>•B>™†|¢|]pãO”­Ğ"&J•ò‰±Š_¤à,ååAì8sbÇ‘ÍºDB×ş1'v}˜»ö(,µiï‘{ëÌ‰(ªã4n2»²¸n`T˜8™l†|b¬²õH¾™™9±Jü,!m¤|"Øû‡ÖB}p”‘¡ ·.Ñµ<Ê]æÄ®=Jì–Ú¶÷9±¶2×œr§gNì8²™Í.Ële¦dwê8»ày1QWÊ'64·ë+¼”vtp§gNì8²Y—H(¹SÇÙ _µG‰`©M{?S”]H®>ùDÀ‰6KQt’E=FÅE¨£2'¦$U$8sÌ‰Iö•ÑÔpZ?Iláq»ÒG¾("àÄ‰€›DB×ş'‚>{ÆWíQ"XjÓŞ'BëÄ‰$
p7‰Y«ÌÇ¨LábÂqkx’e¶¸’=sbJ²VÈLEN»`ÿĞZ¨20¶v‰ˆ®ıãQîúì_µG‰İRÛö~'¶©sE¹ÓŠ'l&^¤ë¶Íˆ’;uœİ	ğ6rù(¦KlÉ›âsdwê(ºãÄ‰€›DBÉ:Îîøª=JKmÚû4ˆ?ßı¬Í$ú%ÂkµK2&È²Ó²3ÖÖÅy—­A|O¸Sˆ4Û6‚t}øí|æÓKµèow;¨52cœPteó9Y•McãAmÄÑLØâµ}º=à§»Ğ-K$¬EÙ;ëZÊ5ÚÃæ³zøX
=j’rh¹&³C‰½çÛz®1<w£şDÜıy†ùØuĞĞöÏÔèŸG‘®‹üín¡ß|ùö§²³~÷ñ×=>:yüç£Hû¥å*wÿ´ûcÌOÿ¸ûøç—6´GÀ–ğ#P@Xã@µáTJJšIqf”â€ï€{{×¿»oïú(Vyì©ûnìÇ±§?~øïäçrx¬Qæ÷Kò2Õâ{ÄÛÅs¡7{È6#ÃÁ©Ï]|nôË·Z|nìÿ7²P´Ç.d·éƒ¬ùÓƒ·ïüıĞ!}VN&½)˜³fÈ‘ÿ¬â?Õè´ëïÔı…©»=‹$a©ó-ğmO†}:wïøñœ–v/.ÆÊ}§vşŸP÷7îpîär;°%ûÉvÕ:Wƒì';Z/«W»%Üq´¶_BµÉgOhkî˜My¥1ÀçêKépc$ÂÈ@ÿ }%…h Ïhºß:ü=-=bês$¨ˆT-=# Éøn†?ğfWÜ€²Û?ó†kşù+¬}›ĞƒµóÎ¹-kÇƒ±KıdÊ£m­ëÆu
9Z&ë'|ä´,õ˜ãw, §vı8H€œF	Æñ»±İã ÔqØœyt_68ª}
5ĞaªAQßQqak*~E{ÿpv*æF
%½‡V¹è‘J~ í÷*Lûil£ÌÚ8Åmğ„˜ÓÍÈi±?€2Ğ¹³÷Cƒú+Ê¦cö‡›-f`¾>*wÚ|=¤ŞÛá†—p$ûà=âíi‰ÁÛV1
ğÔ6üÇ\+KÿF±‚àTAq‰R=>KÔ%¶Ç6YOì_G_IŸs·ã”0_%
4(ã4†ª'íQb·Ô¶½?ÿpã+bª!J•áÂ.L1?Nı½Ÿp_ä¶‡OºF”Ok„ûa @œisŞĞW¬+ãª¡HñMš‡pñ¸İ£ş4Ùq
¸Ë…6Îda cãÔ|î™h…{i.šÇåXøt¡GÇ˜ÊÔßM™—û0ÕèØÆ5}ŸO5J©¾Ï{¦¼ä¨]¼ÁB§=ĞÆÜåõw®˜*0œ«w;³\1EÔ¬mvEÇÆÙ¬e5ï´™ÕŒ¸#êwÏL‡%¬˜7¥»ÎgŞèVã©†·˜½Z»)[İÁ‰ºÊ%¦)ş³«Fæ”¯VÊ©+Î»ª¿2FwÍ¡©Ÿc?Ô²ÜòEÙbŞ¨Â%»mZµÙ7êçb}5çUœ~!¥`òè®ß?ƒ©Ï±#ï¹•qiV+G˜§UT£*ø
¿n4ß÷;›>2³ÔÊ¯¹$q}{nØµ:E±6 |/xneXZMLÀ]+(kõÇ:„íPLä
uÇ:„„×%ª'íPb«Ş’m»%…ıë(e– §Ìàx¯¯K$êRA¨C8Ô<i»¥¶íıY:f–Jg#¬é ½«ë#¨¯ÄqÕóêºf¡nf(@m²Æ8NåÑtºj~gâD€öÏ¨ï(ªeCÕ‘3±ğ…›)Q;]‘ã-âÍHø^aãwBZİhÄK{Iı']8«©ƒ‚}VÜ“¡šŸ"«kÜ›jàöÈ|¾€»g[İmM¥œ»Ğ/ØCó{Sªcj ¦#wÎÅª	3¨±*Û®S$ó)uGfæÁ™²©štê†šAóù¡Œ¬“ˆÓhu!ÆP”Ø
Rºâi·Ûùšõ¾Ú„øş%šÅúê‚!<ÚV¶ÍÄSùNs¶™Q¨ÌŠ8Vf%<¶+V¡=‰­UIÕ·ê"½¥(pŠ§:®«DB¡2+UU…Ê¬CµÕ“ö(±[jÛŞïQâ1J¬á|”¨¢“fÑÙ<«=i>uH× ©ò<‘>®4*„}îÕÑ‹^7æô<¦
æ‰æsw‡/­ÖoršxG®Z­,Ó“¥+îõ|‰…¥Uõ¬%æVÂÙ»lF¼=üW–£Kôykd7îÉéP3ÔgoJdÊÛ"åm	·K:¯íl—Øª—šVeo‡ıë(/,ç…¥ãTw•H(”·¥Ò´PŞv(Y{Ò%¢¥¶ìı¾°±t<Çww<å¡SÊßÕ–]móu#Ïõ4…¢„K‰ÕS|"ã)—ÍhÂ—^6ßâ¢ÎÓı‡pµÀ©´Z6Ô¶g~^§¤œéé#—V<ÕËöÁ·ªø.¼ï_r+¨•ª³ñ,$z¸âh¥Y}+‚ç…*ÂˆcaÂóRZ±¶¼C‰í	›S¶ô®¾ÒÒ8-=€SÍáU"¡PE˜* Cá¡2ğI{”Ø-µmï÷¥ç´ô”x–6ã«œ¬Zœ®Í]ZFæzOPÑ»/8¶zRÆ·öïäĞQßO“TWÜ?™ß8{–[—óË‚óa<½“Rkõí7VŞfgíÇ™{:DoœU+êNÈ<¯9¿å4<æ—¿?mÕ„½«ŞÇ]hµPÛóc€ïoå”dm¶ˆ»CÑMçÃ±°t0¾8Ã(”ÕFËjî—Ktq‡KXª—eÙaÿ:ÊABÇ9Hè8á^%
eµ©$6”ÕJeŸ´G‰İRÛö~AB{ÃÔ9|?Ÿl‚ßÇ§Çã>ñÍü¼<NÏËİÓŸ—G[ŞÏËÏµñ~^¾E=Œ,ZMnBÊÃ‘*àt¤
8†¶Šßí]Ä%3
ÅéÇâô„×¥dßãD‰AÔÀÀĞ‘* Y N‘àX¹K$ŠÓSay(N?œ?i»¥¶íıY#çŞTo^5\ªGÀš7ßÎosÌùıYµ<óÜûg-M_4ğ¬Ïi4>ã™öÔnakâî^±òOÏL®¸v»§|™ÛóæGæ=7ĞïÃz”Ø9s¨®+*™_¿»gnO­¬†î\‰Ö¾EˆZüâ[1ãv9#8ùÅ&ëâ{ÁÃ’$;¼<aÅC{)“M¹ß|ˆ‡Z
ï
AßBx\Š„‹©–u‰5‰>·¢nĞ¿rˆÚqQ;NoY%
ï
¡÷|À»B†÷œ´G‰İRÛö~QO!jì—ò4gÖñf¨Û[Ò¯á¢Åİçp—®,Ou9]²ÇôR×Sü; Âó{ÚøúPéFT“[Oÿï†)`~¿i^P¥:uşXMÕ†JäêÉ<Nw-F9Äøàü]™7»BßÛ‹<Ë.^ò»iše”É?¯ëİ—¾½u®4â-!ß<|×NïQÍãÈ+6MÓû\jõºb³¢ï¯¬RJÃT³Ï¯dÏ·cWìzæOTÍ·ÉóC‡ÛÓğØ'éôÙ|#}{=YççÊáŸeŸüÄ…^¦êŞót ZÀÏœ—=)×«õ¶ñfWÒÓùÚâışm²Òw$ç«õãó"í5i>×\ïì5Ûß·*­9¸š*áPo¾½„-´ò©Qz_`Çù}€ç¥š*Öİ¡ÄT–Z|lïı†şu”ò"€S^pz»à*‘Px_ ½ëŞ8¼ğ¤=Jì–Ú¶÷{^ä˜ñŸusXïanOÜ_öwæâ|‰‹ƒ]ßÅõaèŒ
¤ÎÔ²S)àÑ±Ğ•úŠQk­Q•Á­Ún¨ºğŠ¯ã(8«‚úÄ)¢=çğŠÃßëß²ûùåÿ »"¨ıendstream
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
xœ}T}LSW?çõõU¥‘ÒBÕµ…~ØG¡´¥£U,CeŠDatR
­€ôK*_aH%š-Y¦Ûâ˜Æl·ğ™s›ÑlÉb–Å¯%Ä%K–¨s.Ù²ìŸ¹ìÃÇÎ{­Ä˜¹{{ûÎïÜ{Ïùß»ï€ª€[WtpÇÅE£=ä`»#¡p¸¸v)Ù7Èçì&Ç‚Yn@º€°¾;Ö¿×R!m%\L¸8šèq}²­„[çÇB{“°ÖNÖÆC±HÑNÇbÂ¯àEÊyzî¦t)†°‡ce5•B©TÚËô.'5—‘šL©TqM¦ròJ6Ÿàÿ=zNu½‚úJ¸zàôÑ¶8¢Y_:éö¢cûÆñ¡²ÁÉ)_ğXoÅØ¨mïäáê¶7{Ü?0¯ÄëŞZÛÀÑdÇÙ‰ÄGÅû¤Ä'Šˆu¹J¥@c©HÃÄÉT"‘ˆC ÂŒñ·ùñÙág'£Ãß¾D,ko¸vøî–by åkj·RlãŸ¿1k·· ö_Åìã¡ã‰JÄJ˜Ñá™ıq¤·}f=Pş}s7ÙO)¿Ê)¿ÓA9éWÈ‰ÅÏ+Cªèiá2èÒˆÑ¤Š=ªG›µb&éİ“Ø®·7xu¸ºo:ôÙw{,üºá_êF”âO¼W¾BaØµÆÙ¨de2ÄëS©u‡Ü5ë1ßâ18¦Ş>¹)ôNÒ3u`›§#ÍYFë%[•ÚæB,µÈU†"ãÂ9 ®ËHt¹Î4'€CÔ«“¹0öjöËñÚÍÈqS¨™–£µ>Q½ë\ƒmü{†I¬éŒ2è¯UØ´Ç˜{î
oÇz¶¶Ÿ²‘"ç)ËA1¬I#Sª„‚•yÂÛ(trèD…Ti‰œ®r£‰¼mhû¡TŠî“Ÿ_ñU×ã¾ƒ§J¼ºlÔ6]å*_Ê¢¿¦òö}ßõãÈØ—õnCMMmˆ†ùU]˜SKÑ	s{ß­k±–çä«ÔKÔæçTÊ‹>_-_?¾R¯ñ$§Ã“;o¥¦”Ş±»taœª8$h%µÂ§j•‹Wø/±ìñÈ†ºy±,õ1_ìœ?%ıËÊ$¼qk£¢D“ËÓ±Á„ cÎåaîQ	}Ót~%:a0¯ówè —¿SAréìœ í ÉyZO Èå´çÇ•á"+’Ù‰œ]²ãlANİ3ËòVU•¯û`ÅòãæéË¨¹|š­Œµ D‚·qòÈKÿLHF…¸×çnHüÒôÉ(ÊÕI„P\BiW:].3Ò·ã¢ĞşUüíª#æ#¯.Ø]Ö`5çi²fùØ	¶Íü­K[ŠWnkÅ,ùW¬ÕKœL+EŸ ¨ĞJ5¦+|À_­B;ZùYºd ÓãZ<z?˜íù@¸ªlÂWNu#pó.Ú#ù„ÿ`a?Í—HÄH·,–şØ»p††Šíƒ	zÓs˜‡7³pÆu²'Äà |9Øgğ2şÌ¨³5K¼o±}²IÁGµ!»¦éîÍØjBi›ÅXœ±Yò?Ÿ±90bTC’0»¡º úA/ƒ4¶B#4gP)X©ÿçúRp‹]4óûµğD OÜ'dÌxR4¢bäYqŠZI3Õ™<Qê=ĞI.²iU7ÅĞBÂÔ#4eŞF¾(yzÉ^'îì¡ÕIŠœzŒWõ<'-”‘e#kUÆrÀfÚ£xb-1.Z›¨š1 ¨!âõôuÏ¤ı›(¾XD‰k-UG,ÿ¶ôwªendstream
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
xœ}W	Pgş__Ê¥ãrÏ43ÃÍ0#ˆ9EQ.¹DåFK.Šh4lbÊdMbÆ¬Q4^IÊİdÑÊA\Ë•rS©5•MUN«b¶4ûºgPk¯îú{ş÷ïï{×?!2’H(bÜÒĞU³§|(Gvâv©¶º¼ªº>CEˆ{4Ykq`ÁË\;ÒHÕ6¶ïØ½ØËé¤÷54W–Çşÿ%!KNi,ß±‘R¤‹l*o¬æ;bHï ®á™/ÍİbN0ÙDMBq„ãd>Š%J¥Òh³âcÓëz™R©çdz}L4Y­ôâÑ²‚–‡ªl[şŒvy¸ ÎZû~K/@TèöÛÍ½Z^{ŠÉ†VËîá‘ÄÂ¡ë÷Æ]Ã£©¹G­UÏSƒ½›/¯ı`¨·èPapmJã!d2gQoFˆÜ"W*mfë¼(ˆV”OfãYI$8+<ì=‘»>ÍNô0oÚ›“2°Âd^¬;—Úû tyËdën0Eµ
™TBU!ÔVšúFÆÖ–­]!† «ŞŞG(,Ô}L¡LßÊ™B‰ìˆÏK(Q0A€m^{•
±2‹"òÇ#@z«Í!²4¦Ÿs÷ˆßú»ÜÔşíU:]BÔÒ¤1ƒÅ%§U.µ/;YÓ³XN'_]ÑØØGMÃ—üê°Œ]¥6€€¸³eÏğğëŸ‹‹1Yª®¯o€ÃûüC•O¥µçGµ¿İÓOE€ÂŒIØ -r§ K8™HÄD;Ğ³AÛ={¯îXWÚÚJŠãÆÎ¼èÒ´{û,oÆ4=Ee¿:ljcº[°z6†¦ôÁq¥ÕT^Î ²$;‰äŸŒ„Õã„APpè-*DA5o×¢Ÿˆx<ÄÆª7¦²ZD±dŒŸŒsqWFóÅ„Ø$ğOjÌ3Z= T~*·àîä†Væ¢0y¡õÊÀ*€¯C ?_‘º¡(šó7È­…‰A 	Ë—fÓc#äµ§—Ş#`Y€«&(kİ’ >RÕ;hÛztÓÆ&­!4' ÅW«¤x…z/öñC}à1¼8'b`HÈáCáO"fİéY›Ğ:sQ£F÷ÄUGu°w~sâ¶)ËÕÍS½d6‰¦ºî°ØN…ô¢øiÁ³hŒt<m^f¡Tgşn‡'ìv{öÎmå‹„ĞëØ/ˆJ\‡`©ÌJºB)“á”ÌB=8ëï™œäªVø†¨º^Xjñ´OeL‡×$Ğ‡Yv·]œ)¢_yNÎİ¢~`‹ˆ¿ÈSÎÓ"ÑqEËØl¨£Öa/dıÃ›‰öÄQ¿#'¹ÒBÏ Ø¥u€ÂÃ%HÏŒ_dL`>œ]°n=p²ãœíïí*§~Ï8‡Ÿ	r5$:äw"îÜ–4:Œõ¢ßxÎû¥¨-:cË={§á“×t
?¯ˆÜÎ¼ä„W/³¯S4¨Rë_¥‡ï¨)ªOä™†š”şğ-ÕwçÒĞ†¿²v¢ÃS5¢2A´˜®=C[¤<…6U*Dğ¤ˆÕ0¦™™¥¯}ODÇŒÕ|'|³|bQˆ¯ñHI}C»ïœkÏ
¤ß=·æXjÇÒeŒ…‚R©OÎ ª8ÛXõÇ•[Ówx£-{sîcæ&{óg$Ê§<'(e.Gş”BÃ •R¨”C‹æ^3ç%h,Ó`æŞ¿óx <ÙTİ ö}âéŠÊE°%`ùqÖÓ«nüãÇæ²1“Ñİıé“_ÿ¸íÚ³¶ç`pçêóW^^±¿{V¿üjR_¯ˆû(!Ü-Äİö08\ö81ïíó‰^ÏkÅ$ÏKoƒ{ö·øü
kf	¸<ov[QT»*ÃÏ•=j?	,MğşÚ’ÔêÅŞİU1
Š¢©ädlÍºp Ö$ò!³~ÔÉøš5á yn‹ù/M£fdšÀ†Ï¯/ÈÏCEÌ2p½e-º@’x	5õÓß.@LgHZÉÁfÁôÖW§ñèG4£&0¶‰YŠd›Ò‰¾õñÊáH×2¹ÜYÉ…C\váÏ¿çó*CgªeKEa%o¹ÀV±/3±7Ê;„Wu^jé¥À¶ë/õ ÓªâŸƒ~<Ê¦	UhœŞ:øì‹ÙGã´>^z­š²ÌŞÅb²áÍÕb-é).ÒWmE›œ@Y›Ñ&¦‡µÄàˆíGnã(xÎZbĞKZ8ìÆÔböÁÚlÜS0ô]®~E¸*"Â<R¹ëÃUz›·İøbsC7€§o¨wÛ[åM@Q7ı•œ¹9Üh„–:Ó®áciC¶¤' ??¼½ o/vk·”‡\ ¨,’{‹yj¥ÄL¡|Ñ$%”9ci¾Ö©¤kºµH‰~ÃËÄ/fÖrö‘§?,ÎVÆÂ+ÃBÊ,+ÚKua)&0oîÏ);¿Ö%ü`oöÖ6;†;ï_ßıQº.Ş¡xGPWl§ÀCÍ+bz6DÔu€1rÙIÆ4nŠUùjÀÏ¶&2zà©±´ü¡*+äæ>>kÓÜ½|Ôn;êø´d¾¨åX½·‹£©¦ªDW–íƒ÷ŒWs*E=Ğ‡PÏ²	3BÍÙô6)
ÖµGér¦çGLóÁ­ò¨Ò±˜H¹T"¥ÌVO6-·—aPIË¦}YŸÍúÙİ|•Ú”ˆ¬8-&lÎÅ'<Ã¶e¤zmPNá³CÖ±ª`CT`ö™»—z	íµà®Ûªúİ)6ÅùªÌôÂX³¶y­XèJÕÉU]¢óW Ë¾q:$Z¡	Eùº{ëC}¼WùR2ú™âŞAP(d‹¼õ~.‰é@cÀàm4¬J_iŞè¯ğ[èêîæî†èŸ»ÅZ0¢Txë«•ä¢å¸:Ü3¼3P]‡‘Y‹½ÇôdCÿçã…Æ’şÜ¤	á¥æ”ğU+^¿Œ‘WÚz *,î8{gözEÕòğıÉ’#[lƒ÷²°ô9jxï¦‰ìF
.e×Õˆl­t1‘¥„h°l=×&R´  ôİ{gúå©å‰ùåÜÉ3g¹cû·_+V3¦Ùñürs~†:€úçÌ{†­í ë
;ï!t©£v`¡:ìXàÅÆ9/a%s	ÏTˆ¹„æå’ÍœŞ€)Ü†çC	üæËCõŠ  0_½^ãéWÿ‡$êg,-ïĞ+§'OiBÕ® ÷Œş4´²‹E]~ÃJuùr¨Šœ©Lª÷ªà^}íiÜ9N—MOáº¹oæ>¥»œ²h—™/[h
G±‚È‡G>§‘ÏBq^âƒ«°pw'…Óoÿ,¨nBÕ¥ëOy08{ö.<#ˆxÎÆ˜ZA˜¯¤Lí´UÅ¼/à$ûX-†‘¯Û¼|"käÌ´Q¾W„fÕ§B¯áJî»0‚ÈÎ¼E'‹mzŠ.š‘n("(I…ˆÊñ*!JG•anµ}ñí{ÂW0ywösdŸ˜µSoC›„¾†ú°±¸S&e|¹…·ë4À˜l·¦~™yııi*Z0À¸.$H»¯¿@&â&lÁ/Œ^-õŒÿ…òïj»’»…7)1w>¸‡¾-Ü#ÄoBwKâôø£ağÃ´‘—°y`³cÆ±^ñ&É*–\Ä6‰íJrÛ$Î¥a»É&£LœÆ~3î9¿IØ°Ç6ûá¸¶ß¨Ø¹oğ—gÚæ°“ä>ö;‘'aDLğI'#äkP@/œ‡pŸ
¢LTUJSßÓ«èrúMFÆô°Øul7û$;ÁŞ`?cpæ²D|7JšiÈfÄØ©ù<,IB_ Æ§ÑI} ŞH9úøÂ}Çãœ}èa=şh&ÛHi%ud©%íXƒ7#‰Á–OrI¡“2á¿¹0ş_×›H¬ô’
œùûI
©&mÒŞ&¤ôÎ‘íØ$ÎØkB®Ëq&ÙyN¾u¤G¶`¯WÕ"@RNªğ­Æ6r5àH=öÓ¤u¸zrŞş˜\ÉeïF|M$ÂÙ‹!ëpO#òëÎÈCMR/µ©F	:k9Êõ¿×=>ãÏDşó»3P;”ò_s4²endstream
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
xœ}X	\T×¹?ß½wfXÜXfF„q`D–a˜Fd•]ö}—Me !H]b·¸`Tb]øŒµfqI¢íëó¥jµ<šgß³Ijmúk|µÏ.æÒïÜ\Ú¼73gî=çŞsÎ·ü¿ÿ÷İK€"!Q„!Aµ5ÛÿòûßãH!²ßÖm¨¨®Ù‘¤&D^cú:°gl´ØÅ¾Wé¥—U—eßbÿ*!@šª*.i.²ûd›©âåfK¢	q‰Å¾gc…iÃŠ«!*ìãzp§ÍİuŠ‘•ØW©Ô*/µX,f¤Î2™6X¯×b±d…J¥2„Ğ^°L.“Éä¢6›€À|şÉ©1óùÒ’L~í7'*lùÉ%ïì.z½BÚê=%}«ä²Å6ì½²áˆ– Ó-şş{ïñ÷olJÙû³m{ß„¸í×:;´#ôzƒ¿;A$ÎİávrÕÄ‰ Î€’ˆ¥Î²yIP•DF·§”T(Š©ëûtWRÒ®}=ÿ¾; yçÍŞÕåqŞ ª¸rcXyœ—W\9W™‡~98üùHzúÈ/‡õ½ŒßBHé@fzippÙ@FZYÚ£Ÿ®%p$ÄÉAá€ÛÊ¤xDÓ¬Ktıà›>ÄÿkçšÇÖpY3g™C•mósóàƒëPP4Fá>÷S'ª&rì(qºRªu`¼ezƒN,V‹Ñ˜Z¦î(ÿÅÎ¸úgª¥Ë¹{/graàËO}l.àg ì|Ê± vê$¦mã¶Ñ¢dJ²
WÕëu!è.”ë¬¤LƒWÔ½VFİ%ç4 KV_ŞŸÕñÑö¸Ø+í¥Ç_-wá¸mN‹(_.ud¸eŸè‹NRÜvÚgéñÈıï×^ıÅ¾4MÙ+Ùk5néÏ‚f¥G²uCy|Q­€•JiD.¸H$“IQ± ‰BÆiƒ(\ˆÚ[@’!XÎÙ1±İï6m:½%ÜÃcárµÑòt~°¹*4ßU¾Ô†(óƒÎğ8øœ?æÇ¦Şd™GùC:ĞVæK<Ë¥2û¾!F:-XõÁ¥Êàİ9“ÑõÊş¡p€"*sî¶èˆoWHÅI¨”r1QæÍ¡LhHƒB²ß,ÖãÈ)Ó¦\\©ÚO Â¯¥ê—ƒ©ªŠ?\6Ò`3—˜V¯6ˆA]a`ÿXVîÛûûCî0ÌmßşÃ™ï‚c}ÿ-$ÿ¨ã¥+;‡®¶·]İ‘L±‚ˆKæ²ˆ˜(XVÌ-èæïüúø;0ÀeÍN±¾3g‰›Ì_Ğâ‹-ØÑb4:P»Àœ•ú¸»ØmP™2+â@ÉÀÖæÏÑ
C8}\4IXd
áãüàA!šœ£{Ø"V 4æ¥¡)œœ¸‡°šŸ?É1~Ÿ‚PPıàÊ6ÍŠi›9Ë.˜}BçGmáN¢ù}`Š¿ÅòfhrÚ¨GB7ÔÂ‡„Bá@ƒË“UPWhƒ4‚‹$ø/w–STÄ2¹¿èTzƒà3§Q¹<¸ÏG¹€3ç˜¤?	Ëd‹åaÚÖÇ Móêº‹#°P
ş$´™ÖeBJa¥›—Üy‘ÒsSszøş•«•Mîşlìlì$ÎîgöíÉ	ÖñÁ•Wã##ã9‰­¥î˜ûŒûê%§L‰Ö×Éd++Ñ(èÁÁé†æ!ÔÁë«Æ»"îiÅUšºƒÚÇ!Ñ^ ^Ñ!M
ETµÎæì4(82ÙÛ<™å°Ò³GóhK{SR{J40ÜŸ¹®«˜†9†VæQûgŞl=ÉÜ0ëXnæS®dvŠ Y@»éDÏøÃ‚d6„Ïs'%„DT'xÔ”%fÃÓsñdİhäÊÑÚ Ì±æÛĞ
cöxvÆ.zû‡LzNZ8²†,èfú»!êTt+Å\R)eE2aÿ¤;úIWÆù,Ü3üÖ[à1Á…™rXfŠa ††_ıxv€íF/ÄóÑ\€5¸ôé NdÔRk «Q¬D/†¶AEC;6ú`iõ©®µ‘í§j3’}Á;ª($»n	?¥¾Ò7}3ÌÓ!Å±*Ì#±%†Üp€""Ëš¨(†¢cŸ÷m»;’	‹½#†d†{DGEU­Òë ªâÚÿôëûSRº‚‚
ºS0¹è¨ÚE9]N]¨:•HlÀg*¾AÊåğ_0¥¹Ú‹ÀñÉ›ÆÂ¹,sJuşr¸Î\Ÿå?¼y¥¸Ê0!¢«÷Ÿ9ß[!üOÍçù[ eNšSæ;Là´sÒ:'çØâÎôf6œ´ü-ó9ş_A+šœµaÿ6íÇÙàİˆ¯Êçw0 UQ¶hÈàMĞÁ_b³„×ÆnŞ…9Çp¦g&¢†t¦…Í({(˜)¨ãÇÏ_àÇñ¸
®\†ÆŸñæÏCšùù.ğãèßv>†£u!şVdÏ‡Yˆê¹@RŒôE®†ƒT6íÆZW8zø¹º§WjêG´õ…‘^à¢/Š¢ÁÆe}ûG&º´ òOõ[7–«U‘oÅÅFĞ–õ§¥ôk4Å}é)}%ZÔèw
YX“Æ«å—ƒ×–ÍÇ­¨t´fQ[ia<<Â2ƒË4¶öÁc³¦/~ãÑ0ºs( ÃˆZ»ØÕ/Ä\Â<¸Uæã……ŒmL*Úˆk{‘`ºs°Lê,;K…Ô¥ĞQµ®JIå  õ™\ P5LAye)gë¼’¼–ÃÙ«"BWÌÂj}õ•Ùû …Ö¨x7=€»‹KR“‘Wâìãì K\fpÕdõì­ñssX£Æši?6¶;È‚jÙÈ—‡!KPFeEW/ÖÕìw8‹§‰G ¦z¢'.Â¸z¨*¤æ€ş±>?Ê¼¢
BG!‚e¥CÑÑ_t·Nfd&,…´l–³8©«8HSÜ›šÒ[*0bÖ±K0ÏÓP©Ÿ%z”Dbe§˜‡“Z€­Jh‰tO«K{26xwï:€€ê·[îŒlæèë‡ß‘ğ“‹`xîùâh6îúÙ×ÙM‘Xìèxãˆ-·¨f_xV>@Ä–‰†üWÊc¤¾nÕ…åu=g£;/´æï8àã¿Héæ›[ĞŞ‚rÆaöó·°°P5Q1YñóÕ•9;z”Ëß6©ótm÷~
´^îª>Õ“jÏ?r+ÏlÚ
î®K‹#óÊ\˜ÕcÍa ¿åır_jXÓXõ¦R€÷§kıƒ ÊĞWÄª¿èfø…–ª¤ÔaZopş#üYó7L<xŒğÉüvèdÙîÙÁÇüÇócB¹pÎûà÷4
Ş§,~ü$®¼Q İ R©}Œ|‰Üâ}D'­®$2K](uèTR	P@E™À-×b"Ã¡6êfÿ–Ob;A«¹ÙkÈu³sX –Ø-”,+oÕÉe"ÛE¶K‹D7 ¼(‡ÿòßw¢¾JËÃÁçÜºÆ‡°Æà’iz%)rKmš4f-4NîÜº1ciL<EëŒ¨VDëbÄ+ÑR ôA>¥yÎ‹uô>Â$ä¼ş/Éehµ‚ä¯&ÌQMg(àO8E–Ôúİ3àİP˜=ãÇNïÄË0ÉG>‚KCÖsEı)çI¥‚š*µùK&(‰Àª<A®×äÅ²åË\Œ9>îşJ¥#\Çjêë=ÓÏˆ}×¦ ˆl§D"<,^b¯Œ¹[+@¸ğ] ^°r­#?ÅkÏUx¬3¼7“ÈîÜ$92Cï{#%Ìš‘œéãÍ@b™PkQIuœÍÎİo¼¸xÂºÌß¼6øUNræ‡ƒ¯ ¼2È>™]Ğs1&9559æbû×dc˜{¸æ"\S"7ÈjƒZ¢SJÕX4Ô>„¿ûş÷÷ß÷çŠ®\Å_âîäG’w¢Oğ9ãvëM©ÀrÖ’jÍ/j¸½5'¶Düõk³	İáÑ±eKã»íbë¯ò’3\kŞÜÒ¸¦YÑ˜`¬dÁ	kWÌ?øã˜JXcåÏ˜¿ÕÕpïü1øów…ªÔ'&Zr$+Æ‘X²’Iá!x|Çï`¿•‹Îğfø÷xˆ`rå|_¬¦Wş&æ_l4*8_Œ áèŒ_zŸ^o‚n>ğ%bdrKıeüSp.æ7xEÔe–ö$+ aÛû-­ç.b5›ª×›À-íöÒ®T5Ëş
ˆkpXzXl[ãÖuõ§;¢b.ÿÎQ¸u;@§)l}Y{NäË}oU¡$ˆLI›`çëzÑá/İÿçáïøËpœŸL‹&gÆ¸ò™c\–;gZ‰õiOš`ÍB9õ´Ğ¥¥Ö<}!ó>Sµ“*••J¸â´Âİ9K;OczÀÍ…ü×q}6·^Ş/m­*èÓõ=×#ò°»Î%Qy¥€•Å*/âd­šÌÕğeã»Ñ‘ï4ôœ]±¯ºèÚP€œôMW]Œqn€ª¢{TbJ¬DozQÛÓÇƒ ²DH/¼T IÚI.ş[?0²òµ¦N`º6­¯áøß{¶¡õÚ0dLÇ‰ê„öˆ@¦@tfvJgæíÛvCqaÅáæ5ë†¯µ7}°=V@ åšøç"ºÏA¶Fœ´NJ\ø›9¯åQ˜ˆnóYæA¦Ãl‡PAyu0ÎT2Wæc›©4ßÅ
é
ÿ¼vQ}ÅZYK1¡Ş¿ñ&üÍ&&‡?`¾(Pò“£f›Å˜73»§)_ÏÍ‰r„íIq¨UÈ¬t4ï,ı)ë(iØYÏÆ™±Ş÷c:µ:»×CBdÌé6sî‘VßĞTÅ[Sş­Mü^Ğ]“r‹Ï¯‹İ³>õÀêPİü¬ì\È2Ÿ…ª²õ•¨Ç >ƒè,(|ªƒ@d—`!®kƒå¨†ŸæÿÄãC>7<ÓF¢±„;ªXìÀ³T±Ï{à³ÓÜÊ<˜ùÖ½OŸyhÎâG…œµ„VgZ¤‰t>ÎåF”®\îëº€Æ«¸¾Å¡E¢TÈ±¥kÀEÀÚ¹•ØXdÄe‹às~œÿŠ¿ÍOÀq;_öZßlyŠÎÁ+òÇ9–gy:‡õgƒ¿Ä_àoÀßP—Q®šêÂhÄ§#ÊŸDXjµ5jhù$Ğ±ü„Zéƒ¾‚c_xSãÜ"û¥Ò…aµï˜\«p_ šĞ¨É†sı	X›4½UZ8yI,vn-ˆÍrûtCŠğÌ -§‚,®26ÆGš†uÌK&}Ûc•—§sk›`İ®¿\{¶;ÖÄ…Æ¨<–V™ <–ï`vv¬©HRyÇ—‡u˜èk:’7÷™èÖ^Öšİ’àÑTÂ;CªŠÂB
Üü»E¡\+:g€±—§ñhaÙhk8MoU¾]»|¥3(–Ôşõà÷ù¿^­­½<÷æşÏó¼?d•s$¢@—œ2|µíåO¶'@‘[”±åâ+ñ -Ÿñ_}‡ÿòç­ĞÚó±+FŒ§y©¬ŞÑÑÑÀgæîŠâõiRu˜¿r!(lâº?ê™#Ş»3ŸºÖ2Ñ¦õ(]µ­1hñ­ğCHÜâGùo¶ûà:ïÕàĞÀL3÷xgøƒÙÕ¼„›§1Ğã:ôø
¬R#…wx†yÿÎ;¾ôxM!øÙû5}?bñ¼Dğ:¯\éàĞuººv¢'Š«º›!iè£Ö–+¯­ƒ¾9 #Ÿ¸¶r@~z0³q+ÃtmÜØ¬Üq™ƒoWRÎz,Ã6îÍ­Û{¾·~¢+&¦k¢¾÷<³Ä=%we‚Öêó³SÜÍ×˜şÖM ]Í}ˆ_ãÜm!#øĞœëdeÔùü¦ş‡“TQG5R¯“E!‹iÌÚö±òáŸG»­òp­&şÎ¶¦Ûâ"ZV*¼½•ğ8µLt±®áZXY½š +wW­±¥)¨wäTá‘¿fµ½°nÇåÍ›/mOt]¶@åÃWÂºv7³¿/¼ª`Woï^B½'´;_ß»~ñš?Ôÿôá#0C>ÂûÄO‡p{—¿EˆmãÜsHÚ„•ÿDqø'ºNŠ¸¯H"¶~f‚¸s­Ä[˜ØH²ğèÎºã¸‘aßï9cF<vàå‘cwÒ)ÌûŠÄckÇõ†iÃû:°)èÇ!?Ç0œƒ×â±iğÚ İ¯Á£#öûñwìâŞxï(ëğÚ0îóá’Ä•ÎÁfÀ±ØtxÏ!lãâ	2ˆóÑuq®›ï‹Aùó„}òı©‚Èò™Dä7Ã5øø_Æ†ñaŒÌ~æ~ÿÌ±ùìì²O8{Î‡KàörG¹["QµèCÑŸÅÎââ-âï‹§ÄÄßJ”’(IäUÉ÷$ïJØ8Û˜lÎØüÄæ®Íc[ƒm¾m£íNÛS¶Ù­°3Ù°{ßŞİ¾Õêß(ü²ó^û§ˆÄàU|ÆËØ·œY†=Ë9CÁ*ë9‡ã«­çb²rÈZÒDšIi!õ¤–Ô‘—0›– Ä~É%Y$ßÚÓ?ü®úÎû5h-úõ$•xåÿ›ïIbÉÒ*ÌmÄÊ:²[ƒ°²	ÏqÕ0¼²ÖºO~ëIÔâYŞU‡kx’
RßØæwÎÃ±Ù„çñÂÌz¼»WŞòœ\kŸÊä‰OvAøÕ ZÎt$ç˜p½6al\±Q8KAm6 m¸jÊõß÷üËx
®ƒR4ê¿9¸Ïendstream
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
xœ}Y	\SWº¿ß¹7	ˆB¤"›€1„°ˆlaÂ* ¢,²K
ˆ–R‹ÔR\jİµ*jK):UÆq:¨µÖik•2ÖçØj§3µ‹¿®ËûÎM°¶Ó÷n8Ü{NÎ9÷[şßvÂ Ã0f.C˜ÊÚÖŠÌ#óŞÇ‘Õã¾¿ª¼¤¬âÙ”r†™>ÇÂªpÀ&_òös±ï]ehj1x¦b¿…a ¸Ö¸´¤äğ‚7Æãcüş¸¡¤¥)dªÆóEì{Ô•Ê½.ÍÂş Î?Á s•aÈEÑ 3	ûR•T!ÆK"#'›å*}G7iôGÑ@ne„§MÎ>³º˜†e…L]#xá¸a89îˆãaxi4Ø|}•ø‡ûÑ=U8€ÎxÉÅ‰ğOÎÖÄ‰¼¢‹şº}@ÒÜØŞŠ÷¢”nÖp’urR¬Í‰®Ì òöŸ—ï,±ïHÓ%)ÙŸ¬[x J«(^Ñ°P“\â—
à—²4âwõ5s×l<±	eâÆ¯rvHÕlì¨4œ#¥ÄW©@œU³(•a¾Ê0µ¯¯™ÊÇÊÍ$+à‚s²wÃË[­Nˆİ]5×¶Ov$¬èx¢VŞú'wì¥ÓŸÎo] t
Ì)$»áÿóÂv€íû
Ú‚kªç4÷U=ÿj`æ­Å[*5 _}›ã• äÙF}±ÜÚÆ5¯Eùù	Z°3ëA¥VH óñòÊ‰ë×;Mµ¤œ×ÂE(äAa/{tÌx¦—´Q.“‘KW\€OV%Hß,edÃKà÷g†^½ÄGOöŠÉ¡öÕé1ºÀä¦œ € ¶—›·L?a%î1çƒ5†ÁÎ€„5•éÏÎ‰ …¢±/¼Uö !‹:22W¯…–¶ øLŸùR»Ï4-;Ö¡ÿ™°yÉ·ĞãK¹úB…Yr§ÿ¢D,qp ½b…«gãvÌ^WÓ½êıØ„P{°söŒøckåÑö$€ø•½%¯$‡÷=-gÖ• UÑsk3ü3\hÁ‹¥j0”Ô|ôZiáÎgÁ%={¢¶ìõ¶€0	¦,¯âÉš¦dİòù3CòW&Ç³‚P–K,z˜Le)óBH$ç7¦f¥Ï­/Su[ºé|›hàøùwù›üÇ@2DÃœCÚÅ<ä~îàÉÌdbq—°ŸyÅK&ˆÀ,	ÁŒ7œ€=éŠ›ƒgXÚLÀÜÆıÅ%ûWÌqJÿ$>û¦¡æDG2 /oZGHWcS@WS|]V @`[w|]¦¿–‘ŒyÄ&f«s7T¢±h+7äª²u±­*5ÇÆ6*û<OÚj*[Z««Úˆi?ø¥UÅÄU/¿yÕ±1Ui~¨Q=òä€<ù0†qDgQÂÌ†ó$g*ç0JAÎ5Š(†§>~½u[GB,UæôèÓ-5GÚcW,«Ø¯c_ÛUü´Ä1ÕY‰™†¸Î­à¯¯†´“ +mV%¸^X¸££vV~!@ÊÚã5•¯·ÅAzÿÿ94Ô°oÃ¬üf]¢1; oMlœŒºÌf»ÈhDĞ¥\)‘Kä¹F©QJ4<é†òVOEG{õ¦[¾ÿc#¹—Ş2g0õÌ™ÔÁ9-é÷Š'#ÏRÆ×S ùy˜ƒ£/A%œt
Qz³Sˆªêˆ6)	Üÿç÷ ‰I‘G*@±yÿl@î¼bşæ{üF¾ Z êø–¦åìÓ)ş€ÌğEjÑz9J­„"OØ“ªÈü{Ô _‰‚úúS[ßˆ»‹³08¢—˜m¶u´)ö,¶´J7ö+Ókãı2<^ıRĞ¦×eÍó<
 ™YÅ*€§œ]3ÂM.l@|í<ù%å»‹úJõğ”	èçUıı\èèÑÈuJ‡nüCv€ËdB7@L5NI¬˜â=F ùl_%ö-Î•í`ÿrºh»A^™k‹÷çg®ÑCæ,>!ş¨ì`ÓØüÊ¡ê"„dM…cÅ¯¼œ×šSœæ¬tN
×/ôV8E‡Ÿ>	ÁOg4oğUÊS´©ù ù¹H[7Ò¤8èÍÀ eyËÿK¨FËôÈTK'"uÿ*$é›£“XâDeK‰F64à„Ct‰/È—l?E—ß]ù¯°nkijˆNœµ¨A,ÿw¿ºôw‹¬rs§ÎöãG¦ûTo­0@ÛóqZç2üHó†mhÚQ~Uúâ%“æç ²•N¶·J¿–ºr5À¼Üœ4Ø€1 Æ³davÎ'k;{ª)ãø5.ùtbfhPOH{ÂÇKŸ0ÂÇîÄ¸3êµ†ê7VÇÄ´¾^mì€ ]µº™Ù‰:C†Ÿ_†Ê«»h!díºÑÕqe‹òµé&Dwn3hµ†ÅKv"QÚ›Fì‚2õû%"ù8Kx—¨7ø&.R/©z[Rp`[Ø‚ôdŸîŠeÍ:/
5Ò«­HCgf¬4¹M<7”›ÜXŸM»ÀA8?#>>d»™öÒ ÿ/&DoT¦ÕÆ—¯ ÔNkîO^a6R_B-!®6ÍÊëhVÔ‰ø¾É…2.˜)IÒ	?†7‡o±7ûÁ?­6®rô´gF”æ§+¹PÓşÜuE³À¸”<»`HW‚,8-ŒFÆl‘Îé4O‚Ù‚ó|Ò{â¦ŠÇÆ£ù9;I8W‰½lZ^ßöåƒ	qí'O}­xÃ§§"ç¹ ©Àq¡Yµ±Ñµ™3À§Qem‘q•õrv}ô\ç0jïíãËj“k2ºSZó‚BóâÄÔ¼·ñ«ÄJTÀ8¶¢ ¶bdÒ¨ÅJ±¯Õ±şÍ›«+Üâ=C53à
JşF÷ØHnØjÓ$Ìº´äSº—Ç£ÌdØP ‘ÒK)5}`]ùëüWƒP+‹Uù¨]Âş9
ß0¸Å…ı™½Ô¯»]“m]rÍ˜+r (OE™9¡ÌoÁ›e%tÉ¬‰ˆ9p´üÄêØØ·şUÿf;¢<nõÉ†ä†ÌZ7lnõóË\ÎeBÆÖºÿÛmHßr­ó…Ûô{#{—o?ppwiñîÚH‹·%[ğİf\MØ½Ú‚©5ÇÑO$s³Ïy1Y@TĞò]AvNvbr”°P»âmÊƒzüûã„¥¢œ2ÑÁş†¥²?ök^¯©éoÓz¤Îp8aï—`É0Ä§4ed7‰FL#Y¹ ™[¯´¯¿±#”mdAdİÎâ%Ûá†E‹w¢(‘¨Ÿ#7vA&¤erÔ¿=áºå³Ìüª¥"ŠÁ'$Ì¦Å(¯êkMŒ:_º7É}º÷}d…—»›äèäÛgZ‡4îş®v|p÷Nğox~C³R©Ç´l÷âÅ0ÏßíIKL…EÃ‹¡ªin2Mğî× )Î{AÓÖ"¶£üıı’û¡‰˜ñ«ìUÁr„xó_VCÌY†^.Xy¹kÿP_wìé¸¸¶cÆsŸ9İØ´vo¨yÖ¼—nš‡ËÙùqçs¢q\ÿÏÃÈ¹÷oh5Òw-/‰´ñã0ÑñSá_¤}ıÎ–aDıˆq¼{‚‚eé¨9#D¹võòÍ?CøÙ+7Ì€@}…MDùßäcA‹(°7ãÉ­C0tÚj)µ¼“ÎÙM<ÕqÓÖ~|Ë¨*c.!›9êDSàyh€ˆ
¨‘dØ}–¿Êß9­øŞ]lÅèªï!¤ÕˆïsPç9ËY†ñL®²6sêF%‰™†TŠ_Ë©’•°î?İBäNÿrU8Yi>ju=ß4eœËú
E:lÜFÖv¬ïÔ=33X[6oÑÓó£\#ßh?w°X/Ms‹ëzn µıHƒi°±T—RêMUR®êÌ3t–ô™
Ám¤“>œ
³ Ï-ó1’Z4³AcÃlÚè\ğØ&Ò×·úô	Qã‚æ(¨’ş"ÒX£ıVˆÛWUùzk,‚ı5Æ7¢öÂuİr!f-Ÿƒ|	ÎMıË×:º®ïÌ(]ÒÛQõBŒĞĞÆv|bêÏ% İ"Á¾)Å¥Cì~“;¤”/jí=ÔåË¬5ÀLEò ê,×y¨ä;ß)Ø^$DÌ·A§é[Ó-ØÃ—ájdtŠè¦ÙK«Ã4¨+µ`¾2uØø!SÃJk™›[ÀÔ–ç6nì?Î…öÕ¢î‰ ½i°{l!û*•Ò!Ò
Y&­÷U@ÑëãéÈ^Ú9búşGÓ——öŞûG8ÇÇPÚáÜ>A/ÍÈgÑU †’Lxö÷¿
5Ã|*¬ø;!¬è=d:M† ‘×âº2ôŞE_OT‚f«%"‘%Ro#¦Æ¬y\’kÌªSúàdÍDç.p#ïu¬~§«_h|qDÎœÙ½pUßlrüƒÒLo¬Iñ‰BoxÿBbQ.	ÎoKÿıY–›ş÷7c€–êeü7óJ}šóæ½<¦CtlpCbåKQÕµ‘áÓôÏ—½p. \ê—§Yï°w3Õéq~Ö3#´"GŞ‘Œ ­ª·ÙMV,«ñ	Kòs}Wç8ÿ2.êy"ïì9{Ö’wbı$z€RpfüiãÄDæäàÌYøE†‰¯·ä·"€[/ÿğLEÅ°>ØuqTQW9Äÿt¨åî4€ô·W´ïI×}^ô54\áoı=ûJ]F†jİ¾ß->Ş.¼×óü§òò~ÖıÂƒ”7¬iD©H«Õc<JU¬	ıŸÇ§Ş'1gH*Ûmò#×ÇV˜‘ƒÓ¨ÿ"*ŠAOgJ¸ú±ïW@+ŒämŒŠ‹!_ß2m?=ëw²c=iuXÔÎÊá;½ƒ'±%ëÛÖ¬Ç=Ñ)ŠòpO[š1¨<Ñj¨$pSGÜÒÁ‘Å ™ÛsûôÖ¹{ïô˜Îâ[÷ îİ*dÇÀé\%<æ:ÿş.ÿş&µ4ŒU¸ëTêq&"šZ­ı\rKI¿³‹{q¸¡ñm´á’’İ†HŒŞ+hğyá¹âµ…/U†iëv—rÅ´¢ïçÆ„è­`fQJîiMóøˆ‹R,8PÔ(s×ÙR•½¤·ê@”&Öö”U#µ‘û«M½CĞ /÷Í$à¯ô-×óájB±ÂÓÛÛSQœ€ Ü±pİMÈÁÆ¬Ãf«À´nºL›Ó½Øİ}*˜òñöö.ÒhŠ¼|ÔÓ–(ªAŒQ_ïëi¶D@¡áÍ0?Ë\3ÊEiAüg?l]±¬nÙüÏ^"^	ïØy:‡œhYşûöø˜¶#u‹v‡*gK9ñß/ªçÿ:xš¿lX8ËÖ¬tcà’ÒÜ}w6l¸w ]Y€oMEÖQÄºß„ü…ƒjà‰³Yş\¨·<¼,\gô[>Z·ö£íYTŸ§5·ƒŞ¯%—sı¼q°=>á™“Ë9šAaîòã„—–¿N¡~³ÖaÜı»šÚ7Úbç4÷×Dñ#ñu¿J ø8Ñ7s Äv}Ü¹öêËó {é¢¨"»‹—l£)ÔNL¡ê¢èy"ÂFksf 2êèÙî±OI¾©ƒ­2•‘5\èÖ1~×6–Ã)ãÆ¯Å#P‡9Â»ÖÃ?Ñ)O¿æwpûy~"Óàöª¸Ë<_AåÖAåøsœgD|‰_Ê§\&.(¬)ÜƒGôÈÙ…˜\°#œ‰öè‰noÀÁ¡“üO¼×ñO@wwÔßı¥ÈéQ }¦ñàn0ˆ	Õ>=ÑªıÁáâBGKLîÅı­ŸˆÉ*h&1…³cÎg&Â1»Q8€(6s$³èƒÖ9ı9æ Øóñús0ëO®˜6ÃEHZÓ_Ñx>Ş7r†RºÏ¶än~İë¼sÕ·ü8ÿÍÑØòª¥'Gwn5·²N¯ùUô­Š×§(«V­Ó­ÿô@>Mñ7×ÿşOd“¦û§÷òw?4BÓªw‘®m¼ä"²Ç5„ƒ…‹AÀ]}[~PP~›¾!±:ÉÛ;©:Q4RqŒoigF¿(3Üÿé?«W=üé¾wÓãn¶‚G`>ßS8;˜(J[U€eVpÁª´ú®ZôÙŞÉUñ¼¾ì‹Q¾m?v¿âS¾çaÛjÜ­wBM‡Zbë¹ë	ÿÁ·óŸÃ7¦ŸÃ.ØqŸğäºi¤šüL„M›qõ\`ÑB*gP‰NŒ}÷Á	–»@‰ä. ÂOê¨—`A! yŠ£ÌQå¨.ÏÖˆîò_ã]Ãx=$›K+Ëm¢‘‡­’.3•ãÊB‘NÑ÷Ğ6ÂÅ\æOòŸ@ûUĞ&u£	Ü[´á«/ª)Ö*˜»œ[N–(:(æucìmÚÈğÆ«›è¼v44ÚLP©ş×„gjÖk2Ã'è}LuÅø×\&{‰Ú
€Œşq™cÎ¬rìûQ@_/Œ< }Ô›W£rÁİg2s=ÎwK„3Ú‰_&²ÄÖ–êU®bñ¿ÈŒ…Œ h•+dÔì· pçdÔÆºÃ¬­ÉóÚ‹Õ`¯Œ)~&İƒº”¢yİZ÷ÄˆöÛÂç€éxH„Û$(Êò‰K%òĞ¬˜’÷Rº¶$Å\"Š“È@ÄZè³r
Ãu+òB f4Å{ëÒkÃ—–7$,Ş¾,ÜÇÇ!2|?¨Î-¹8;Y=Ó5s	W]šwTD´éÕED™R¤ñK›§ú•GrDõ×Ã½ê¨ív"ªÉÄ	$Z9B‰~-¬¡(Ø".¡³‚!æY8‹zŒ`XÃ¯æõ’®-ÿÙ‡t¿Îå‰¶`–Aë5ëé¨`Ñ¯Må(4µ‚6	~ÅŞÙ›<Î¤îI}øÉÜ_ÑïÎäõ{2¿¹>÷ÆĞbÆ™XÑŞ›yc7¿»›Ï„c´uCy7ö¡é)DİëÌºw5à_!û*^9æÛø‚	©½|õ“Ä‡›Âv0î‚Ö•bz$©øÅÏ>rs5©fÁ¬pÿ¨®á®õ’ZVleâ6Eíø—y3J›€MÍIâÓcï ;6yÎ°÷ôp´îxÊº[<)‚uü-Éô‚uå’_Ç*ú_cIû”æ“F‹KRB%E”7"*Ì!Ì[ãÌıâ]ã(”3–Ê'b(;HÙ[ıÖËóCµ¦döèìKoïÍ]dışÂ›…§ï‹Ok°q²Şiü²^»f(ó0ÿÅÕ&hÿ¼¿Ü» %m±Z°™|ŠWø'«¦ëäáã´L˜ªqW6sâ®ü… ‹\ªÏZ_©$}¦ü±ìË¶İàpµ™€ObITbß[Ëğ×o·¬÷v‡ê·L/€éŸ´XzäÎ3‹_ïÌ •ÒNíCæ€{X’ÿŒÒ²ùnq	Şñ³óö®N¡(ëE¯–`ñ‰–ZƒPü=™ü™i')şÁ4uhˆLúŞDØ¤ØdK¾Ç Ä2Zç|Ä~Ìl&ŠI¦§T®r!5šÛĞO‹å2•:Ì\lÌ¶ŒJ-ñ@©fÍ.–™Ë	|ûî/9Ddiu^¶Rkö€Í'7[²V©’R!?_æVXõ×šİjYµÚ[ÒkbÜ h†O~¬ØÏèríèù*{W{Ó°udè¯àxÕÇßM)<\õ[Vö¨&I¦É—ôÔç÷ì›b49M_UTş´”wzgjhdzhtµÒÛKŒèzã±¢Ë}f¿óä¯L2•pP…U"uQH‘Ëäh~äØxÅªÃ3‚ÑMF/?°ôÓ;GaŠ“[SnDI5IÉœ©rs´ñtS§NÁbµ:n–jÁü…ª…›*Ã¾ı*±ÈGŠÅ5º$ÿ™nò)Yaõçé/ÀìUH°ü¬VøÒD,O!a)	Q/)a¯ä-´Ò[¿Ğzç®eAjwõï*ôÀ2jukË D]XŠ‰àÈÂ±^²~5KÑÀ,º2k¼È>ê†,¿º0‹Š•ìAõ–×°äïâü—hW²GØéÉ«€Ğß\™«x?nyÖa‹Ã¦Å–Œ­ ÛliØô¬“-Œİeğ¾.2]˜åéğŞı<lFq?³ï´ubËÆ}İp>§’~f#ŞÕØ"q,ûKD[¸8~ûNø<„­_”Çœ¢{a;„ã
ÜÃÇøÜŒ÷2½—ÅZF}Wl§qİ ‹Ï½ø\Ší¨ğ.†‰#Úñ\ãø0~ôíÂµw‡S¸~!Ò°İ'×ì.¦”81—%=L7ÀTëL½ã÷5t\Û‰-÷vÃñBl»¬¦3:ú^o¯ <:á³V²k&SÇœgî€tAq ò"y‡\g­XW¶š]ÉŞâ<¸R®›äÆE>¢LÑÑqÑâñzñvñIñÇâ¯$Á’$I±ä äMÉ5ÉOVVÁV=V‡­[Z;ZG[WYo¶şÇ¤“r&m›ttÒĞ¤¿Nº3iÜFj£´i´ÙesÎæ¶ÍO¶['[µmŠm©m‹íOv"»©vşvÅv+ìú'Ï›\9ù†½·}„}¦7LSIã£¥÷ëK„U Ë Gó-†±<óöÌÏ„™–gÇ#,ÏbÆr™xÆÈÔ3­Ìr¦ßSÅ41L!Â¨±Íg²™|K/”	ÀOàoÎe´ÂÇƒ)Åoş¿õLSÎ4
kë°çkY‰­VØÙ€Ou¸k$~oyO-~ª™¥8R‰O­8«
÷ğ`J˜2ü”c›xsÕâÈ2|Ö	+«qv=î¼ò	ºâÓät~B1Ÿ4?©1«F*J™Â;rpÇ:á)¹)G
Và®%H×ÿ=ïÉoÌãi¸¿eõÿ¡<endstream
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
