#**Contents**#

1. **Overview**
2. **Lab Environment**
3. **Configure Host Networking**
4. **Configure Neutron Networking**
5. **Deploy Heat Stack**
6. **Explore the OpenShift Environment** 
7. **Installing RHC Tools**
8. **Using *rhc setup***
9. **Creating a PHP Application**
10. **Deploy an Extra OpenShift Node**
11. **Using Cartridges**
12. **Gear Scavenger Hunt**

<!--BREAK-->



#**Lab 1: Overview of Deploying OpenShift Enterprise 2.0 on Red Hat Enterprise Linux OpenStack Platform 4.0 via Heat Templates**

##**1.1 Assumptions**

This lab manual assumes that you are attending an instructor-led training class.

This manual also assumes that you have been granted access to a single Red Hat Enterprise Linux server with which to perform the exercises.

A working knowledge of SSH, git, and yum, and familiarity with a Linux-based text editor are assumed.  If you do not have an understanding of any of these technologies, please let the instructors know.

##**1.2 What you can expect to learn from this training class**

At the conclusion of this training class, you should have a solid understanding of how to configure Heat to deploy an OpenShift Enterprise 2.0 broker and node.  In addition, you will learn how to expand the OpenShift node environment.  You should also feel comfortable creating and deploying applications using the OpenShift Enterprise management console, using the OpenShift Enterprise administration console, as well as using the command line tools.

##**1.3 Overview of OpenShift Enterprise PaaS**

Platform as a Service is changing the way developers approach developing software. Developers typically use a local sandbox with their preferred application server and only deploy locally on that instance. Developers typically start JBoss locally using the startup.sh command and drop their .war or .ear file in the deployment directory and they are done.  Developers have a hard time understanding why deploying to the production infrastructure is such a time consuming process, they just want to develop and test their applications.

System Administrators understand the complexity of not only deploying the code, but procuring, provisioning, and maintaining a production level system. They need to stay up to date on the latest security patches and errata, ensure the firewall is properly configured, maintain a consistent and reliable backup and restore plan, monitor the application and servers for CPU load, disk IO, HTTP requests, etc.

OpenShift Enterprise provides developers and IT organizations an auto-scaling cloud application platform for quickly deploying new applications on secure and scalable resources with minimal configuration and management headaches. This means increased developer productivity and a faster pace with which IT can support innovation.

##**1.4 Overview of IaaS**

OpenShift Enterprise is infrastructure agnostic. OpenShift Enterprise can be installed on bare metal, virtualized instances, or on public/private cloud instances. At a basic level it requires Red Hat Enterprise Linux running on x86_64 architecture. Red Hat Enterprise Linux provides the advantage of SELinux and other enterprise features to ensure the installation is stable and secure.

This means that in order to take advantage of OpenShift Enterprise any existing resources from your hardware pool may be used. Infrastructure may be based on EC2, VMware, RHEV, Rackspace, OpenStack, CloudStack, or even bare metal: essentially any Red Hat Enterprise Linux operating system running on x86_64.

For this training class, Red Hat Enterprise Linux OpenStack Platform 4.0 is the Infrastructure as a Service layer. The OpenStack environment has been installed on a single server with all the necessary components required to complete the lab, but in a real production environment a deployment would consist of many servers.

##**1.5 Using the *openshift.sh* installation script**

This training session will demonstrate the deployment mechanisms that Heat provides. Heat runs as a service on the OpenStack node in this environment. Heat also utilizes the `openshift.sh` installation script.  `openshift.sh` automates the deployment and initial configuration of OpenShift Enterprise platform.  For a deeper understanding of the internals of the platform refer to the official [OpenShift Enterprise Deployment Guide](https://access.redhat.com/site/documentation/en-US/OpenShift_Enterprise/2/html-single/Deployment_Guide/index.html). For details on Red Hat Enterprise Linux OpenStack Platform refer to [RHEL OSP Documentation](https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/).


**Lab 1 Complete!**

<!--BREAK-->

#**Lab 2: Lab Environment**

#**2 Server Configuration**

Each student will receive their own server or will share with another student. The server has Red Hat Enterprise Linux 6.5 installed as the base operating system.  The server was configured with OpenStack using packstack.  Explore the environment to see what was pre-configured. The end result will consist of a Controller host (hypervisor) and 3 virtual machines: 1 OpenShift broker and 2 OpenShift nodes.

![Lab Configuration](http://summitimage-scollier1.rhcloud.com/summit_lab.png)


**Local User**
Everything in the lab will be performed with the following user and password:

    user: user
    Password: password

When you first boot the system up, you should see one user selectable for login with the description of "Deploying OSE on RHEL OSP via Heat Templates". If you see a list of mulitple users with *labX*, then you are booted into the wrong partition. If this is the case then reboot via the icon in the lower right with the password *redhat*

Sudo access will be provided for certain commands.

**System Partitions**

**WARNING!!!** There are multiple partitions on this system. It is VITAL that you only ever boot into or modify partition 3 "Deploying OSE on RHEL OSP via Heat Templates". Do not mount the other partition or make any changes to the boot loader. Doing so will violate the spirit of Summit and make the panda very sad.

The default partition table has the following 4 partitions selectable:

* Red Hat Summit Labs
* Installing & Administering Red Hat Enterprise Virtualization 3.3
* Deploying OSE on RHEL OSP via Heat Templates
* Red Hat Enterprise Linux

Select *Deploying OSE on RHEL OSP via Heat Templates*

**Look at the configuration options for Heat and Neutron:**

Open a terminal and explore the file.

    vim ~/answer.txt

**Each system has software repositories that are shared out via the local Apache web server:**

    ll /var/www/html

These will be utilized by the *openshift.sh* file when it is called by heat.

**There are also local repositories for RHEL and RHEL OSP:**

    ll /var/www/html/repos/

**Explore the Heat template:**

    egrep -i 'curl|wget' /home/user/heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml
    
Here you can see that the Heat template was originally making calls to github for the *enterprise-2.0* and *openshift.sh* files. These lines were modified to point to local repositories for the purposes of this lab.

**Look a the images that were pre-built for this lab:**

    ls /home/images/RHEL*
    
These two images were pre-built using disk image builder (DIB) for the purpose of saving time in the lab.

**Check out the software repositories:**

    yum repolist

**View OpenStack services**

Load the keystonerc_admin file which contains the authentication token information:

    source ~/keystonerc_admin

List OpenStack services running on this system:

    nova service-list

**Lab 2 Complete!**

<!--BREAK-->


#**Lab 3: Configure Host Networking**

##**3.1 Verify Interfaces**

The server has a single network card. Run the script to create the bridge configuration.

**Explore the current network card interface setup:**

    cat /usr/local/bin/create-bridge-config

Run the following script to create the bridge config:

    sudo /usr/local/bin/create-bridge-config

Ensure the *ifcfg-br-public* file look as follows.  

    cat /etc/sysconfig/network-scripts/ifcfg-br-ex
    DEVICE="br-ex"
    ONBOOT="yes"
    DEVICETYPE=ovs
    TYPE="OVSBridge"
    OVSBOOTPROTO="static"
    IPADDR="172.16.0.1"
    NETMASK="255.255.0.0"

Packstack does not configure the interfaces but in this lab they have already been configured for you.  In the original state, the single Ethernet interface has an IP address from the classroom DHCP server.  

    sudo ovs-vsctl show
    ip a
    
**Lab 3 Complete!**

<!--BREAK-->

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

Show more details about the *private* subnet:

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

#**Lab 5: Deploy Heat Stack**

##**5.1 Import the Images into Glance**


All actions in this lab will performed by the *admin* tenant in this lab.  In a production environment there will likely be many tenants.

    source ~/keystonerc_admin


The names of these images are hard coded in the heat template.  Do not change the name here.  These images were created via disk image-builder (DIB) prior to the lab to save time.  For more information on how to create these images, please check the upstream README.

https://github.com/openstack/heat-templates/blob/master/openshift-enterprise/README.rst

    glance image-create --name RHEL65-x86_64-broker --is-public true --disk-format qcow2 \
        --container-format bare --file /home/images/RHEL65-x86_64-broker-v2.qcow2
    glance image-create --name RHEL65-x86_64-node --is-public true --disk-format qcow2 \
        --container-format bare --file /home/images/RHEL65-x86_64-node-v2.qcow2
    glance image-list



##**5.2 Modify the openshift-environment file**

There are two ways to pass parameters to the *heat* command.  The first is via the *heat* CLI.  The second is to via an environment file.  This lab uses the environment file method because it makes it easier to organize the parameters. 

Review the provided environment file with placeholder text:

    cat ~/openshift-environment.yaml

    parameters:
      key_name: adminkp
      prefix: summit2014.lab
      broker_hostname: broker.summit2014.lab
      node_hostname: node1.summit2014.lab
      conf_install_method: yum
      conf_rhel_repo_base: http://172.16.0.1/rhel6.5
      conf_jboss_repo_base: http://172.16.0.1
      conf_ose_repo_base: http://172.16.0.1/ose-latest
      conf_rhscl_repo_base: http://172.16.0.1
      private_net_id: PRIVATE_NET_ID_HERE
      public_net_id: PUBLIC_NET_ID_HERE
      private_subnet_id: PRIVATE_SUBNET_ID_HERE
      yum_validator_version: "2.0"
      ose_version: "2.0"
    
Run the following three commands to replace the placeholder text in the file with the correct IDs. For a full explanation and detailed manual steps see the next section:

    sed -i "s/PRIVATE_NET_ID_HERE/$(neutron net-list | awk '/private/ {print $2}')/"  ~/openshift-environment.yaml
    sed -i "s/PUBLIC_NET_ID_HERE/$(neutron net-list | awk '/public/ {print $2}')/"  ~/openshift-environment.yaml
    sed -i "s/PRIVATE_SUBNET_ID_HERE/$(neutron subnet-list | awk '/private/ {print $2}')/"  ~/openshift-environment.yaml

The scripts in the previous section should have added the correct network IDs to the yaml file. Run the following two commands to list the configured networks and subnets. 

    neutron net-list
    neutron subnet-list

Inspect the *~/openshift-environment.yaml* file and verify the placeholder text PUBLC_NET_ID_HERE, PRIVATE_NET_ID_HERE, and PRIVATE_SUBNET_ID_HERE were replaced with the actual UUID from the output of the previous commands.

    cat ~/openshift-environment.yaml

Contents should resemble the following (the IDs will be different):

    parameters:
      key_name: adminkp
      prefix: summit2014.lab
      broker_hostname: broker.summit2014.lab
      node_hostname: node1.summit2014.lab
      conf_install_method: yum
      conf_rhel_repo_base: http://172.16.0.1/rhel6.5
      conf_jboss_repo_base: http://172.16.0.1
      conf_ose_repo_base: http://172.16.0.1/ose-latest
      conf_rhscl_repo_base: http://172.16.0.1
      private_net_id: 9eb390d1-a1ad-4545-82db-a16f18fac959
      public_net_id: 84078660-baf4-4b51-a790-759fb897a5f5
      private_subnet_id: bbd59b2e-0eee-4e3d-8bae-85cc91201ecd
      yum_validator_version: "2.0"
      ose_version: "2.0"

##**5.3 Open the port for Return Signals**

Once the *heat* stack launches, several steps are performed, such as:
* Configuring security groups for the broker and the node
* Setting up the *broker* and *node* ports
* Setting up the floating IPs
* Installing any neccessary packages
* Configuring OpenShift


When these tasks are finished, the *broker* and *node* VMs need to be able to deliver a completed signal to the metadata service.

Open the correct port to allow the signal to pass.

**WARNING**: Do NOT use *lokkit* as it will overwrite the custom iptables rules created by packstack

    sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT

Save the new rule:

    sudo service iptables save


##**5.4 Launch the stack**

Get a feel for the options that *heat* supports.

    heat --help
    which heat
    sudo rpm -qa | grep heat
    sudo rpm -qc openstack-heat-common
    sudo rpm -qf $(which heat)
    source ~/keystonerc_admin


Now run the *heat* command and launch the stack. The -f option tells *heat* where the template file resides.  The -e option points *heat* to the environment file that was created in the previous section.


**Note: it can take up to 10 minutes for this to complete**

    heat stack-create openshift \
    -f ~/heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml \
    -e ~/openshift-environment.yaml

##**5.5 Monitor the stack**

There are several ways to monitor the status of the deployment.  

Open Firefox and login to the Horizon dashboard:

* Open Firefox and browse to http://localhost
* Login with *admin*:*password*
* Select *Project* on the left
* Under *Orchestration* select *Stacks*
* Select *OpenShift* on the right pane
* Enjoy the eye candy

To use the CLI, open another terminal and tail the heat log:

    sudo tail -f /var/log/heat/heat-engine.log

List the *heat* stack

    heat stack-list

Watch the heat events with the following command:

    heat event-list openshift

Each resource can also be monitored with:

    heat resource-list openshift

Once the instances are launched they can be view with:

    nova list

Once the stack is successfully built the wait_condition states for both broker and node will change to CREATE_COMPLETE

    | broker_wait_condition               | 65 | state changed          | CREATE_COMPLETE    | 2014-03-19T21:51:30Z |
    | node_wait_condition                 | 66 | state changed          | CREATE_COMPLETE    | 2014-03-19T21:52:01Z |

Get a VNC console address and open it in the browser.  Firefox must be launched from the hypervisor host, the host that is running the VM's.

    nova get-vnc-console broker_instance novnc
    nova get-vnc-console node_instance novnc

Alternatively, in Horizon [dashboard thingy]:

* Under *Project* select *Instances*
* On the right pane select either *broker_instance* or *node_instance*
* Select *Console*

*NOTE*: Do not use ALT+2 to switch windows (shortcut used in Firefox) as this will reboot your system!

**Lab 5 Complete!**

<!--BREAK-->

#**Lab 6: Explore the OpenShift Environment**

##**6.1 List the Instances and Connect**

Confirm which IP address belongs to the broker and to the node.

    nova list

###**6.2 Explore the OpenShift Broker**

Ping the public IP of the instance.  Get the public IP by running *nova list* on the controller.  The public IP will start with 172.

    ping 172.16.1.BROKER_IP
    
SSH into the broker instance.  This may take a minute or two while they are spawning.  Use the key that was created with *nova keypair* earlier and the username of *ec2-user*:

    ssh -i ~/adminkp.pem ec2-user@172.16.1.BROKER_IP

Once logged in, gain root access and explore the environment.

    sudo -i

Check the OpenShift install output.  At the end of the file, you should see "Installation and configuration is complete".  This ensures that everything worked as planned.  Spend some time in here to look at all the configuration steps that were performed.  Also explore the cloud-init output files. Ignore any notices about NTP, it is because the lab does not have network connectivity.

    view /tmp/openshift.out
    view /var/log/cfn-signal.log
    view /var/log/cloud-init.log
    view /var/log/cloud-init-output.log

Now confirm OpenShift functionality. See what tools are available by tabbing out the oo-    command.

    oo-<tab><tab>

Check mcollective traffic.  You should get a response from the node that was deployed as part of the stack.

    oo-mco ping
    
Run some diagnostics to confirm functionality.  You should get a PASS and NO ERRORS on each of these.  Warnings can be ignored.
    
    oo-diagnostics -v

Look for the output: **NO ERRORS**
    
###**6.3 Explore the OpenShift Node**

SSH into the node, using the IP that was obtained above.

    ssh -i ~/adminkp.pem ec2-user@172.16.1.NODE_IP
    sudo -i

Once logged in, gain root access and explore the environment one file at a time.
    
    view /tmp/openshift.out
    
    view /var/log/cfn-signal.log
    
    view /var/log/cloud-init.log
    
    view /var/log/cloud-init-output.log

Check node configuration

    oo-accept-node -v

Look for the output: **PASS**

Logout of the node:

    logout

##**6.4 Connect to OpenShift Console**
Confirm Console Access by opening a browser and putting in the IP address of the broker.  Accept the self-signed cert.

    [http://172.16.1.BROKER_IP/console](http://172.16.1.BROKER_IP/console)

username: demo
password: changeme

**Lab 6 Complete!**

<!--BREAK-->


#**Lab 7: Installing the RHC client tools**


The OpenShift Client tools, known as **rhc**, are built and packaged using the Ruby programming language.  OpenShift Enterprise integrates with the Git version control system to provide powerful, decentralized version control for your application source code.

OpenShift Enterprise client tools can be installed on any operating system with Ruby 1.8.7 or higher.  Instructions for specific operating systems are provided below. It is assumed that you are running the commands from a command line window, such as Command Prompt, or Terminal. If you are using Ruby Version Manager (rvm) see the instructions below.

##**Red Hat Enterprise Linux 6 with OpenShift entitlement**

The most recent version of the OpenShift Enterprise client tools are available as a RPM from the OpenShift Enterprise hosted Yum repository. We recommend this version to remain up to date, although a version of the OpenShift Enterprise client tools RPM is also available through EPEL.

With the correct entitlements in place, you can now install the OpenShift Enterprise 2.0 client tools by running the following command:

*NOTE*: Run the following command on a client system, in this case the bare-metal student workstation:

	sudo yum install rhc
	

**Lab 7 Complete!**

---

##**NOTE**: The following section includes commands for additional Operating Systems

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

	$ rhc --version

##**Fedora 16 or later**

To install from yum on Fedora, run:

	$ sudo yum install rubygem-rhc

This installs Ruby, Git, and the other dependencies required to run the OpenShift Enterprise client tools.

After the OpenShift Enterprise client tools have been installed, run:

	$ rhc --version

##**Ubuntu**

Use the apt-get command line package manager to install Ruby and Git before you install the OpenShift Enterprise command line tools. Run:

	$ sudo apt-get install ruby-full rubygems git-core

After you install both Ruby and Git, verify they can be accessed via the command line:

	$ ruby -e 'puts "Welcome to Ruby"'
	$ git --version

If either program is not available from the command line, please add them to your PATH environment variable.

With Ruby and Git correctly installed, you can now use the RubyGems package manager to install the OpenShift Enterprise client tools. From a command line, run:

	$ sudo gem install rhc



<!--BREAK-->

#**Lab 8: Using rhc setup**



##**Configure DNS**

The broker instance is running a Bind DNS server to serve dynamic DNS for OpenShift. Add the broker's public IP to the system's */etc/resolv.conf*. First determine the Broker's IP.

Collect the Broker's IP from *nova list*
    source ~/keystonerc_admin
    nova list

Once the IP is determined add it to */etc/resolv.conf*:

    sudo vim /etc/resolv.conf

Add it as the first nameserver

    nameserver 172.16.1.BROKER_IP

Test hostname resolution

    host broker.summit2014.lab

##**Configuring RHC setup**

By default, the RHC command line tool will default to use the publicly hosted OpenShift environment.  Since we are using our own enterprise environment, we need to tell *rhc* to use our broker.summit2014.lab server instead of openshift.com.  In order to accomplish this, the first thing we need to do is run the *rhc setup* command using the optional *--server* parameter.

	rhc setup --server broker.summit2014.lab
	
Once you enter in that command, you will be prompted for the username that you would like to authenticate with.  For this training class, use the *demo* user account.  

The first thing that you will be prompted with will look like the following:

	The server's certificate is self-signed, which means that a secure connection can't be established to
	'broker.summit2014.lab'.
	
	You may bypass this check, but any data you send to the server could be intercepted by others.
	Connect without checking the certificate? (yes|no):
	
Since we are using a self signed certificate, go ahead and select *yes* here and press the enter key. 

At this point, you will be prompted for the username.  Enter in **demo** and specify the password **changeme**.

After authenticating, OpenShift Enterprise will prompt if you want to create a authentication token for your system.  This will allow you to execute command on the PaaS as a developer without having to authenticate.  It is suggested that you generate a token to speed up the other labs in this training class.

The next step in the setup process is to create and upload our SSH key to the broker server.  This is required for pushing your source code, via Git, up to the OpenShift Enterprise server.

Finally, you will be asked to create a namespace for the provided user account.  The namespace is a unique name which becomes part of your application URL. It is also commonly referred to as the user's domain. The namespace can be at most 16 characters long and can only contain alphanumeric characters. There is currently a 1:1 relationship between usernames and namespaces.  For this lab, create the following namespace:

	ose

##**Under the covers**

The *rhc setup* tool is a convenient command line utility to ensure that the user's operating system is configured properly to create and manage applications from the command line.  After this command has been executed, a *.openshift* directory will have been created in the user's home directory with some basic configuration items specified in the *express.conf* file.  

    cat ~/.openshift/express.conf

The contents of that file are as follows:

    # Your OpenShift login name
    default_rhlogin=‘demo’

	# The OpenShift server Connected to
	libra_server=broker.summit2014.lab
	
    <snip>
	
This information will be read by the *rhc* command line tool for every future command that is issued.  If you want to run commands as a different user than the one listed above, you can either change the default login in this file or provide the *-l* switch to the *rhc* command.


**Lab 8 Complete!**

<!--BREAK-->

#**Lab 9: Create a PHP Application**



In this lab, we are ready to start using OpenShift Enterprise to create our
first application.  To create an application, we will be using the *rhc app*
command.  In order to view all of the switches available for the *rhc app*
command, enter the following command:

	rhc app -h
	
This will provide you with the following output:
	
	List of Actions
	  configure     Configure several properties that apply to an application
	  create        Create an application
	  delete        Delete an application from the server
	  deploy        Deploy a git reference or binary file of an application
	  force-stop    Stops all application processes
	  reload        Reload the application's configuration
	  restart       Restart the application
	  show          Show information about an application
	  start         Start the application
	  stop          Stop the application
	  tidy          Clean out the application's logs and tmp directories and tidy up the git repo on the
	                server


##**Create a new application**

It is very easy to create an OpenShift Enterprise application using *rhc*. The command to create an application is *rhc app create*, and it requires two mandatory arguments:

* **Application Name** : The name of the application. The application name can only contain alpha-numeric characters and at max contain only 32 characters.

* **Type**: The type is used to specify which language runtime to use.  

Create a directory to hold your OpenShift Enterprise code projects:

    mkdir ~/ose
    cd ~/ose
	
To create an application that uses the *php* runtime, issue the following command:

    rhc app create firstphp php-5.3
	
After entering that command, you should see output that resembles the following:

	Application Options
	-------------------
	  Domain:     ose
	  Cartridges: php-5.3
	  Gear Size:  default
	  Scaling:    no
	
	Creating application 'firstphp' ... done
	
	
	Waiting for your DNS name to be available ... done
	
	Cloning into 'firstphp'...
	The authenticity of host 'firstphp-ose.summit2014.lab (209.132.178.87)' can't be established.
	RSA key fingerprint is e8:e2:6b:9d:77:e2:ed:a2:94:54:17:72:af:71:28:04.
	Are you sure you want to continue connecting (yes/no)? yes
	Warning: Permanently added 'firstphp-ose.summit2014.lab' (RSA) to the list of known hosts.
	Checking connectivity... done
	
	Your application 'firstphp' is now available. OpenShift should
	return a URL that you can visit with your web browser.
	
You should see the default template that OpenShift Enterprise uses for a new application.

	Run 'rhc show-app firstphp' for more details about your app.

##**What just happened?**

After you entered the command to create a new PHP application, a lot of things happened under the covers:

* A request was made to the broker application host to create a new php application.
* A message was broadcast using MCollective and ActiveMQ to find a node host to handle the application creation request.
* A node host responded to the request and created an application / gear for you.
* SELinux and cgroup policies were enabled for your application gear.
* A userid was created for your application gear.
* A private Git repository was created for your gear on the node host.
* The Git repository was cloned onto your local machine.
* BIND was updated on the broker host to include an entry for your application.

##**Understanding directory structure on the localhost**

When you created the PHP application using the *rhc app create* command, the private git repository that was created on your node host was cloned to your local machine.

    cd firstphp
    ls -al
	
You should see the following information:


	total 8
	drwxr-xr-x   9 gshipley  staff   306 Jan 21 13:48 .
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 ..
	drwxr-xr-x  13 gshipley  staff   442 Jan 21 13:48 .git
	drwxr-xr-x   5 gshipley  staff   170 Jan 21 13:48 .openshift
	-rw-r--r--   1 gshipley  staff  2715 Jan 21 13:48 README.md
	-rw-r--r--   1 gshipley  staff     0 Jan 21 13:48 deplist.txt
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 libs
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 misc
	drwxr-xr-x   4 gshipley  staff   136 Jan 21 13:48 php


###**.git directory**

If you are not familiar with the Git revision control system, this is where information about the git repositories that you will be interacting with is stored.  For instance, to list all of the repositories that you are currently setup to use for this project, issue the following command:

    cat .git/config
	
You should see the following information, which specifies the URL for our repository that is hosted on the OpenShift Enterprise node host:

	[core]
		repositoryformatversion = 0
		filemode = true
		bare = false
		logallrefupdates = true
		ignorecase = true
	[remote "origin"]
		fetch = +refs/heads/*:refs/remotes/origin/*
		url = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.summit2014.lab/~/git/firstphp.git/
	[branch "master"]
		remote = origin
		merge = refs/heads/master
	[rhc]
		app-uuid = e9e92282a16b49e7b78d69822ac53e1d


**Note:** You are also able to add other remote repositories.  This is useful for developers who also use Github or have private git repositories for an existing code base.

###**.openshift directory**

The .openshift directory is a hidden directory where a user can create action hooks, set markers, and create cron jobs.  

Action hooks are scripts that are executed directly, so they can be written in Python, PHP, Ruby, shell, etc.  OpenShift Enterprise supports the following action hooks:

| Action Hook | Description|
| :---------------  | :------------ |
| build | Executed on your CI system if available.  Otherwise, executed before the deploy step | 
| deploy | Executed after dependencies are resolved but before application has started | 
| post_deploy | Executed after application has been deployed and started| 
| pre_build | Executed on your CI system if available.  Otherwise, executed before the build step | 

OpenShift Enterprise also supports the ability for a user to schedule jobs to be ran based upon the familiar cron functionality of Linux.  To enable this functionality, you need to add the cron cartridge to your application.  Once you have done so, any scripts or jobs added to the minutely, hourly, daily, weekly or monthly directories will be run on a scheduled basis (frequency is as indicated by the name of the directory) using run-parts.  OpenShift supports the following schedule for cron jobs:

* daily
* hourly
* minutely
* monthly
* weekly

The markers directory will allow the user to specify settings such as enabling hot deployments or which version of Java to use.

###**libs directory**

The libs directory is a location where the developer can provide any dependencies that are not able to be deployed using the standard dependency resolution system for the selected runtime.  In the case of PHP, the standard convention that OpenShift Enterprise uses is providing *PEAR* modules in the deplist.txt file.

###**misc directory**

The misc directory is a location provided to the developer to store any application code that they do not want exposed publicly.

###**php directory**

The php directory is where all of the application code that the developer writes should be created.  By default, two files are created in this directory:

* health_check.php - A simple file to determine if the application is responding to requests
* index.php - The OpenShift template that we saw after application creation in the web browser.

##**Make a change to the PHP application and deploy updated code**

To get a good understanding of the development workflow for a user, let's change the contents of the *index.php* template that is provided on the newly created gear.  Edit the following file:

    vim php/index.php

Look for the following code block:

    <h1>
        Welcome to OpenShift
    </h1>

Update this code block to the following and then save your changes:

    <h1>
        Welcome to OpenShift Enterprise
    </h1>

**Note:** Make sure you are updating the \<h1> tag and not the \<title> tag.

Once the code has been changed, we need to commit our change to the local Git repository.  This is accomplished with the *git commit* command:

    git commit -am "Changed welcome message."
	
Now that our code has been committed to our local repository, we need to push those changes up to our repository that is located on the node host.  

    git push
	
You should see the following output:

	Counting objects: 7, done.
	Delta compression using up to 8 threads.
	Compressing objects: 100% (4/4), done.
	Writing objects: 100% (4/4), 395 bytes, done.
	Total 4 (delta 2), reused 0 (delta 0)
	remote: restart_on_add=false
	remote: httpd: Could not reliably determine the server's fully qualified domain name, using node.summit2014.lab for ServerName
	remote: Waiting for stop to finish
	remote: Done
	remote: restart_on_add=false
	remote: ~/git/firstphp.git ~/git/firstphp.git
	remote: ~/git/firstphp.git
	remote: Running .openshift/action_hooks/pre_build
	remote: Running .openshift/action_hooks/build
	remote: Running .openshift/action_hooks/deploy
	remote: hot_deploy_added=false
	remote: httpd: Could not reliably determine the server's fully qualified domain name, using node.summit2014.lab for ServerName
	remote: Done
	remote: Running .openshift/action_hooks/post_deploy
	To ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.summit2014.lab/~/git/firstphp.git/
	   3edf63b..edc0805  master -> master


Notice that we stop the application runtime (Apache), deploy the code, and then run any action hooks that may have been specified in the .openshift directory.  


##**Verify code change**

If you completed all of the steps in Lab 16 correctly, you should be able to verify that your application was deployed correctly by opening up a web browser and entering the following URL:

	[http://firstphp-ose.summit2014.lab](http://firstphp-ose.summit2014.lab)
	
You should see the updated code for the application.

![](http://training.runcloudrun.com/images/firstphpOSE.png)

##**Adding a new PHP file**

Adding a new source code file to your OpenShift Enterprise application is an easy and straightforward process.  For instance, to create a PHP source code file that displays the server date and time: 

Create a new file located in *php* directory and name it *time.php*:

    vim php/time.php

Add the following contents:

    <?php
    // Print the date and time
    echo date('l jS \of F Y h:i:s A');
    ?>

Once you have saved this file, the process for pushing the changes involves adding the new file to your git repository, committing the change, and then pushing the code to your OpenShift Enterprise gear:

    git add .
    git commit -am "Adding time.php"
    git push
    
##**Verify code change**

To verify that we have created and deployed the new PHP source file correctly, open up a web browser and enter the following URL:

	[http://firstphp-ose.summit2014.lab/time.php](http://firstphp-ose.summit2014.lab/time.php)
	
You should see the updated code for the application.

![](http://training.runcloudrun.com/images/firstphpTime.png)

Return to your previous directories

    cd
    
**Lab 9 Complete!**

<!--BREAK-->
#**Lab 10: Extending the OpenShift Environment**

As applications are added additional node hosts may be added to extend the capacity of the OpenShift Enterprise environment.

## 10.1 Create the node environment file
A separate heat template to launch a single node host is provided. A heat environment file will be used to simplify the heat deployment.

Review the _~/node2-environment.yaml_ file and and notice the placeholder text included. This environment file instructs *heat* on which SSH key to use, domain, floating IP, and several other items.  Please take a minute to read through this and get a good handle on what we are passing to *heat*.

Review the file:

    view ~/node2-environment.yaml

The default contents will be:

    parameters:
      key_name: adminkp
      domain: summit2014.lab
      broker1_floating_ip: 172.16.1.3
      load_bal_hostname: broker.summit2014.lab
      node_hostname: node2.summit2014.lab
      node_image: RHEL65-x86_64-node
      hosts_domain: summit2014.lab
      replicants: broker.summit2014.lab
      install_method: yum
      rhel_repo_base: http://172.16.0.1/rhel6.5
      jboss_repo_base: http://172.16.0.1
      openshift_repo_base: http://172.16.0.1/ose-latest
      rhscl_repo_base: http://172.16.0.1
      activemq_admin_pass: password
      activemq_user_pass: password
      mcollective_pass: marionette
      private_net_id: PRIVATE_NET_ID_HERE
      public_net_id: PUBLIC_NET_ID_HERE
      private_subnet_id: PRIVATE_SUBNET_ID_HERE

Run the following four commands to replace the placeholder text in the file with the correct data:

    sed -i "s/BROKER_IP/$(nova list | awk '/broker_instance/ {print $13 }')/" node2-environment.yaml
    sed -i "s/PRIVATE_NET_ID_HERE/$(neutron net-list | awk '/private/ {print $2}')/"  ~/node2-environment.yaml
    sed -i "s/PUBLIC_NET_ID_HERE/$(neutron net-list | awk '/public/ {print $2}')/"  ~/node2-environment.yaml
    sed -i "s/PRIVATE_SUBNET_ID_HERE/$(neutron subnet-list | awk '/private/ {print $2}')/"  ~/node2-environment.yaml

Confirm the changes.

    cat ~/node2-environment.yaml

Verify the value of BROKER_IP matches the Broker's ip from **nova list**

Verify the network and subnet IDs match the output from **neutron net-list** and **neutron subnet-list**

The file should now resemble the following, with the correct IP and IDs:

    parameters:
      key_name: adminkp
      domain: summit2014.lab
      broker1_floating_ip: 172.16.1.2
      load_bal_hostname: broker.summit2014.lab
      node_hostname: node2.summit2014.lab
      node_image: RHEL65-x86_64-node
      hosts_domain: summit2014.lab
      replicants: broker.summit2014.lab
      install_method: yum
      rhel_repo_base: http://172.16.0.1/rhel6.5
      jboss_repo_base: http://172.16.0.1
      openshift_repo_base: http://172.16.0.1/ose-latest
      rhscl_repo_base: http://172.16.0.1
      activemq_admin_pass: password
      activemq_user_pass: password
      mcollective_pass: marionette
      private_net_id: 9eb390d1-a1ad-4545-82db-a16f18fac959
      public_net_id: 84078660-baf4-4b51-a790-759fb897a5f5
      private_subnet_id: bbd59b2e-0eee-4e3d-8bae-85cc91201ecd


## 10.2 Launch the node heat stack
Now run the _heat_ command and launch the stack. The -f option tells _heat_ where the template file resides. The -e option points _heat_ to the environment file that was created in the previous section.

    heat stack-create add_node2 \
    -f  ~/heat-templates/openshift-enterprise/heat/neutron/highly-available/ose_node_stack.yaml \
    -e ~/node2-environment.yaml


##**10.3 Monitor the stack**

List the *heat* stack

    heat stack-list

Watch the heat events.

    heat event-list add_node2
    heat resource-list add_node2
    nova list

##**10.4 Confirm Node2 Connectivity**

Ping the public IP of node 2

    ping 172.16.1.NODE2_IP

*Note the IP address of node 2. The address will be needed later in this lab.*

SSH into the node2 instance.  This may take a minute or two while the instance is spawning.  This will use the key that was created with *nova keypair* earlier.

SSH into the node

    ssh -i ~/adminkp.pem ec2-user@172.16.1.NODE2_IP

Once logged in, gain root access and explore the environment.

    sudo -i

Check the OpenShift install output.

    view /tmp/openshift.out

Check node configuration

    oo-accept-node -v

Logout of the node:

    logout

**Note that this will fail because node2 does not have a fully qualified domain name.**

##**Add Node2 To Broker DNS**

SSH into the broker instance to update the DNS zone file.

    ssh -i ~/adminkp.pem ec2-user@172.16.1.BROKER_IP

Once logged in, gain root access.

    sudo -i

Add node 2 instance _A_ record to the zone file so node 2 hostname resolves. Verify the IP address matches the IP from **nova list**. 

**Note**
Replace NODE_2_IP with the last octet from node 2.

    oo-register-dns \
    --with-node-hostname node2 \
    --with-node-ip 172.16.1.NODE_2_IP \
    --domain summit2014.lab \
    --dns-server broker.summit2014.lab
    service named reload

Check hostname resolution

    host node2.summit2014.lab

Check mcollective traffic.  You should get a response from node 2 that was deployed as part of the stack.

    oo-mco ping

##**Verify Node2**

SSH into the node

    ssh -i ~/adminkp.pem ec2-user@172.16.1.NODE2_IP

Once logged in, gain root access and explore the environment.

    sudo -i

Check node configuration

    oo-accept-node -v

This time it should succeed.

    PASS

**Lab 10 Complete!**

<!--BREAK-->

#**Lab 11: Using cartridges**

Cartridges provide the actual functionality necessary to run applications. There are several cartridges available to support different programming languages, databases, monitoring, and management. Cartridges are designed to be extensible so the community can add support for any programming language, database, or any management tool not officially supported by OpenShift Enterprise. Please refer to the official OpenShift Enterprise documentation for how you can [write your own cartridge](https://openshift.redhat.com/community/wiki/introduction-to-cartridge-building).

	https://www.openshift.com/wiki/introduction-to-cartridge-building

##**Viewing available cartridges**

To view all of the available commands for working with cartridges on OpenShift Enterprise, enter the following command:

	rhc cartridge -h
	
##**List available cartridges**

To see a list of all available cartridges to users of this OpenShift Enterprise deployment, issue the following command:

	rhc cartridge list
	
You should see the following output depending on which cartridges you have installed:

    jbosseap-6       JBoss Enterprise Application Platform 6.1.0 web
    jenkins-1        Jenkins Server                              web
    nodejs-0.10      Node.js 0.10                                web
    perl-5.10        Perl 5.10                                   web
    php-5.3          PHP 5.3                                     web
    python-2.6       Python 2.6                                  web
    python-2.7       Python 2.7                                  web
    ruby-1.8         Ruby 1.8                                    web
    ruby-1.9         Ruby 1.9                                    web
    jbossews-1.0     Tomcat 6 (JBoss EWS 1.0)                    web
    jbossews-2.0     Tomcat 7 (JBoss EWS 2.0)                    web
    diy-0.1          Do-It-Yourself 0.1                          web
    cron-1.4         Cron 1.4                                    addon
    jenkins-client-1 Jenkins Client                              addon
    mysql-5.1        MySQL 5.1                                   addon
    postgresql-8.4   PostgreSQL 8.4                              addon
    postgresql-9.2   PostgreSQL 9.2                              addon
    haproxy-1.4      Web Load Balancer                           addon
    
  Note: Web cartridges can only be added to new applications.
	

##**Add the MySQL cartridge**

In order to use a cartridge, we need to embed it into our existing application.  OpenShift Enterprise provides support for version 5.1 of this popular open source database.  To enable MySQL support for the *firstphp* application, issue the following command:

	rhc cartridge-add mysql-5.1 -a firstphp
	
	You should see the following output:

	Adding mysql-5.1 to application 'firstphp' ... done

	mysql-5.1 (MySQL 5.1)
	---------------------
	  Gears:          Located with php-5.3
	  Connection URL: mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
	  Database Name:  firstphp
	  Password:       9svQXLVtv89Y
	  Username:       adminxzGaLVm

	MySQL 5.1 database added.  Please make note of these credentials:

	       Root User: adminxzGaLVm
	   Root Password: 9svQXLVtv89Y
	   Database Name: firstphp

	Connection URL: mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
	
##**Using MySQL**

Developers will typically interact with MySQL by using the mysql shell command
on OpenShift Enterprise.  In order to use the mysql shell, you will need to use
ssh to login to your application gear.  

    rhc ssh firstphp
	\> mysql
	
You will notice that you did not have to authenticate to the MySQL database.  This is because OpenShift Enterprise sets environment variables that contains the connection information for the database. 

When embedding the MySQL database, OpenShift Enterprise creates a default database based upon the application name.  That being said, the user has full permissions to create new databases inside of MySQL.  Let's use the default database that was created for us and create a *users* table:

	mysql> use firstphp;
	Database changed
	
	mysql> create table users (user_id int not null auto_increment, username varchar(200), PRIMARY KEY(user_id));
	Query OK, 0 rows affected (0.01 sec)

	mysql> insert into users values (null, 'gshipley@redhat.com');
	Query OK, 1 row affected (0.00 sec)
	
Verify that the user record has been added by selecting all rows from the *users* table:

	mysql> select * from users;
	+---------+---------------------+
	| user_id | username            |
	+---------+---------------------+
	|       1 | gshipley@redhat.com |
	+---------+---------------------+
	1 row in set (0.00 sec)
	
To exit out of the MySQL session, simply enter the *exit* command:

	mysql> exit
	
##**MySQL environment variables**

As mentioned earlier in this lab, OpenShift Enterprise creates environment variables that contain the connection information for your MySQL database.  If a user forgets their connection information, they can always retrieve the authentication information by viewing these environment variables:

**Note:  Execute the following on the application gear**

	[firstphp-ose.summit2014.lab ~]\> env |grep MYSQL
	
You should see the following information return from the command:

	OPENSHIFT_MYSQL_DIR=/var/lib/openshift/52afd7bc3a0fb277cf000070/mysql/
	OPENSHIFT_MYSQL_DB_PORT=3306
	OPENSHIFT_MYSQL_DB_HOST=127.10.134.130
	OPENSHIFT_MYSQL_DB_PASSWORD=9svQXLVtv89Y
	OPENSHIFT_MYSQL_IDENT=redhat:mysql:5.1:0.2.6
	OPENSHIFT_MYSQL_DB_USERNAME=adminxzGaLVm
	OPENSHIFT_MYSQL_DB_SOCKET=/var/lib/openshift/52afd7bc3a0fb277cf000070/mysql//socket/mysql.sock
	OPENSHIFT_MYSQL_DB_URL=mysql://adminxzGaLVm:9svQXLVtv89Y@127.10.134.130:3306/
	OPENSHIFT_MYSQL_DB_LOG_DIR=/var/lib/openshift/52afd7bc3a0fb277cf000070/mysql//log/
	
To view a list of all *OPENSHIFT* environment variables, you can use the following command:

	~]\> env | grep OPENSHIFT

##**Viewing MySQL logs**

Given the above information, you can see that the log file directory for MySQL is specified with the *OPENSHIFT_MYSQL_DB_LOG_DIR* environment variable.  To view these log files, simply use the tail command:

	~]\> tail $OPENSHIFT_MYSQL_DB_LOG_DIR/*
	exit
	
##**Connecting to the MySQL cartridge from PHP**

Now that we have verified that our MySQL database has been created correctly, and have created a database table with some user information, let's connect to the database from PHP in order to verify that our application code can communicate to the newly embedded MySQL cartridge.  Create a new file in the *php* directory of your *firstphp* application named *dbtest.php*.  Add the following source code to the *dbtest.php* file:

    cd ~/ose/firstphp/php
    vi dbtest.php

	<?php
	$dbhost = getenv("OPENSHIFT_MYSQL_DB_HOST");
	$dbport = getenv("OPENSHIFT_MYSQL_DB_PORT");
	$dbuser = getenv("OPENSHIFT_MYSQL_DB_USERNAME");
	$dbpwd = getenv("OPENSHIFT_MYSQL_DB_PASSWORD");
	$dbname = getenv("OPENSHIFT_APP_NAME");
	
	$connection = mysql_connect($dbhost, $dbuser, $dbpwd);
	
	if (!$connection) {
	        echo "Could not connect to database";
	} else {
	        echo "Connected to database.<br>";
	}
	
	$dbconnection = mysql_select_db($dbname);
	
	$query = "SELECT * from users";
	
	$rs = mysql_query($query);
	while ($row = mysql_fetch_assoc($rs)) {
	    echo $row['user_id'] . " " . $row['username'] . "\n";
	}
	
	mysql_close();
	
	?>

Once you have created the source file, add the file to your git repository, commit the change, and push the change to your OpenShift Enterprise gear.

	git add .
	git commit -am "Adding dbtest.php"
	git push
	
After the code has been deployed to your application gear, open up a web browser and enter the following URL:

*http://firstphp-ose.summit2014.lab/dbtest.php*
	
You should see a screen with the following information:

Connected to database.1<br>
gshipley@redhat.com 
	
	
##**Managing cartridges**

OpenShift Enterprise provides the ability to embed multiple cartridges in an application.  For instance, even though we are using MySQL for our *firstphp* application, we could also embed the cron cartridge as well.  It may be useful to stop, restart, or even check the status of a cartridge.  To check the status of our MySQL database, use the following command:

	rhc cartridge-status mysql -a firstphp
	
To stop the cartridge, enter the following command:

	rhc cartridge-stop mysql -a firstphp
	
Verify that the MySQL database has been stopped by either checking the status again or viewing the following URL in your browser:

*http://firstphp-ose.summit2014.lab/dbtest.php*
	
You should see the following message returned to your browser:

	Could not connect to database
	
Start the database back up using the *cartridge-start* command.
	
	rhc cartridge-start mysql -a firstphp
	

Verify that the database has been restarted by opening up a web browser and entering in the following URL:

*http://firstphp-ose.summit2014.lab/dbtest.php*
	
You should see a screen with the following information:

Connected to database.<br>
1 gshipley@redhat.com 
	
OpenShift Enterprise also provides the ability to list important information about a cartridge by using the *cartridge-show* command.  For example, if a user has forgotten their MySQL connection information, they can display this information with the following command:

	rhc cartridge-show mysql -a firstphp
	
The user will then be presented with the following output:


	mysql-5.1 (MySQL 5.1)
	---------------------
	  Gears:          Located with php-5.3
	  Connection URL: mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
	  Database Name:  firstphp
	  Password:       9svQXLVtv89Y
	  Username:       adminxzGaLVm
	    
##**Using port forwarding**

At this point, you may have noticed that the database cartridge is only accessible via a 127.x.x.x private address.  This ensures that only the application gear can communicate with the database.

With OpenShift Enterprise port-forwarding, developers can connect to remote services with local client tools.  This allows the developer to focus on code without having to worry about the details of configuring complicated firewall rules or SSH tunnels. To connect to the MySQL database running on our OpenShift Enterprise gear, you have to first forward all the ports to your local machine. This can be done using the *rhc port-forward* command.  This command is a wrapper that configures SSH port forwarding. Once the command is executed, you should see a list of services that are being forwarded and the associated IP address and port to use for connections as shown below:

	rhc port-forward firstphp
 
To connect to a service running on OpenShift, use the Local address

	Service Local               OpenShift
	------- -------------- ---- -------------------
	httpd   127.0.0.1:8080  =>  127.10.134.129:8080
	mysql   127.0.0.1:3307  =>  127.10.134.130:3306

	Press CTRL-C to terminate port forwarding

In the above snippet, you can see that mysql database, which we added to the *firstphp* gear, is forwarded to our local machine. If you open http://127.0.0.1:8080 in your browser, you will see the application.

##**Enable hot_deploy**

If you are familiar with PHP, you will probably be wondering why we stop and start Apache on each code deployment.  Fortunately, we provide a way for developers to signal to OpenShift Enterprise that they do not want to restart the application runtime for each deployment.  This is accomplished by creating a hot_deploy marker in the correct directory.  Change to your application root directory, for example ~/code/ose/firstphp, and issue the following commands:

    cd ~/ose/firstphp
	touch .openshift/markers/hot_deploy
	git add .
	git commit -am "Adding hot_deploy marker"
	git push
	
Pay attention to the output, the output may vary slightly because of updates:

	Counting objects: 7, done.
	Delta compression using up to 8 threads.
	Compressing objects: 100% (4/4), done.
	Writing objects: 100% (4/4), 403 bytes, done.
	Total 4 (delta 2), reused 0 (delta 0)
	remote: restart_on_add=false
	remote: Will add new hot deploy marker
	remote: App will not be stopped due to presence of hot_deploy marker
	remote: restart_on_add=false
	remote: ~/git/firstphp.git ~/git/firstphp.git
	remote: ~/git/firstphp.git
	remote: Running .openshift/action_hooks/pre_build
	remote: Running .openshift/action_hooks/build
	remote: Running .openshift/action_hooks/deploy
	remote: hot_deploy_added=false
	remote: App will not be started due to presence of hot_deploy marker
	remote: Running .openshift/action_hooks/post_deploy
	To ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.apps.summit2014.lab/~/git/firstphp.git/
	   4fbda99..fdbd056  master -> master


The two lines of importance are:

	remote: Not starting cartridge mysql because hot deploy is not enabled.
	remote: Not starting cartidge php because hot deploy is not enabled.

Adding a hot_deploy marker will significantly increase the speed of application deployments while developing an application.



**Lab 11 Complete!**
<!--BREAK-->

#**Lab 12: Gear Scavenger Hunt**


###**Steps**

Choose an app that you have created and find out what public IP address it is
using? (hint: use the <code>host</code> or <code>dig</code> command) 

Using the web console or CLI tools, find out the ssh login string for an
application. (hint: <code>rhc domain show</code>)

Now, <code>ssh</code> into the application.

What is your home directory? (hint: <code>pwd</code>)

Try to list all home directories. (hint: <code>ls</code>)

What private IP addresses is your app using? (hint: <code>env</code>)

How much memory is this app using? (hint: <code>oo-cgroup-read
memory.usage_in_bytes</code>)

Stop your app and check the memory usage (hint: <code>ctl_app
graceful-stop</code>)

Restart your app (hint: <code>ctl_app start</code>)

What is the total memory available for your app? (hint: <code>oo-cgroup-read
memory.limit_in_bytes</code>)


**Lab 12 Complete!**

<!--BREAK-->

