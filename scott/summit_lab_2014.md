#**Contents**#

1. **Overview of OpenShift Enterprise 2.0**
2. **Overview of Red Hat OpenStack 4.0**
3. **Explore the Lab Environment**
4. **Configure Red Hat OpenStack 4.0**
5. **Explore the Red Hat OpenStack 4.0 Environment**
5. **Deploy Stack**
6. **Using *rhc setup***
7. **Creating a PHP Application**
8. **Managing an Application**
9. **Deploy an Extra OpenShift Node**

<!--BREAK-->#**Lab 1: Overview of Deploying OpenShift Enterprise 2.0 on Red Hat OpenStack 4.0 via Heat Templates**

##**1.1 Assumptions**

This lab manual assumes that you are attending an instructor-led training class and that you will be using this lab manual in conjunction with the lecture.  

This manual also assumes that you have been granted access to a single Red Hat Enterprise Linux server with which to perform the exercises on.

A working knowledge of SSH, git, and yum, and familiarity with a Linux-based text editor are assumed.  If you do not have an understanding of any of these technologies, please let the instructors know.

##**1.2 What you can expect to learn from this training class**

At the conclusion of this training class, you should have a solid understanding of how to configure Heat to deploy an OpenShift Enterprise 2.0 broker and node.  In addition, you will learn how to expand the OpenShift node environment.  You should also feel comfortable creating and deploying applications using the OpenShift Enterprise management console, using the OpenShift Enterprise administration console, as well as using the command line tools.

##**1.3 Overview of OpenShift Enterprise PaaS**

Platform as a Service is changing the way developers approach developing software. Developers typically use a local sandbox with their preferred application server and only deploy locally on that instance. Developers typically start JBoss locally using the startup.sh command and drop their .war or .ear file in the deployment directory and they are done.  Developers have a hard time understanding why deploying to the production infrastructure is such a time consuming process.

System Administrators understand the complexity of not only deploying the code, but procuring, provisioning, and maintaining a production level system. They need to stay up to date on the latest security patches and errata, ensure the firewall is properly configured, maintain a consistent and reliable backup and restore plan, monitor the application and servers for CPU load, disk IO, HTTP requests, etc.

OpenShift Enterprise provides developers and IT organizations an auto-scaling cloud application platform for quickly deploying new applications on secure and scalable resources with minimal configuration and management headaches. This means increased developer productivity and a faster pace with which IT can support innovation.

##**1.4 Overview of IaaS**

One great thing about OpenShift Enterprise is that we are infrastructure agnostic. You can run OpenShift on bare metal, virtualized instances, or on public/private cloud instances. The only thing that is required is Red Hat Enterprise Linux running on x86_64 architecture. We require Red Hat Enterprise Linux in order to take advantage of SELinux and other enterprise features so that you can ensure your installation is stable and secure.

What does this mean? This means that in order to take advantage of OpenShift Enterprise, you can use any existing resources that you have in your hardware pool today. It doesn’t matter if your infrastructure is based on EC2, VMware, RHEV, Rackspace, OpenStack, CloudStack, or even bare metal as we run on top of any Red Hat Enterprise Linux operating system running on x86_64.

For this training class, we will be using Red Hat OpenStack 4.0 as our Infrastructure as a Service layer.  The OpenStack environment has been set up on a single node with all the necessary components required to complete the lab.

##**1.5 Using the *openshift.sh* installation script**

In this training class, we are going to take advantage of the deployment mechanisms that Heat provides.  Heat runs as a service on the OpenStack node in this environment. Heat also utilizes the *openshift.sh* installation script.  *openshift.sh* automates the deployment and initial configuration of OpenShift Enterprise platform.  However, for a deeper understanding of the internals of the platform, it is suggested that you read through the official [Deployment Guide](https://access.redhat.com/site/documentation/en-US/OpenShift_Enterprise/2/html-single/Deployment_Guide/index.html) for OpenShift Enterprise.

##**1.6 Electronic version of this document**

This lab manual contains many configuration items that will need to be performed on your broker and node hosts.  Manually typing in all of these values would be a tedious and error-prone effort.  To alleviate the risk of errors, and to let you concentrate on learning the material instead of typing tedious configuration items, an electronic version of the document is available at the following URL:

    http://PUT IN IP ADDRESS OF WEB SERVER HERE.
    
    
**Lab 1 Complete!**

<!--BREAK-->#**Lab 2: Lab Environment**

##**1.1 Server Configuration**

Each student will either recieve his / her own server or will share with another student. The server has Red Hat Enterprise Linux 6.5 install as the base operating system.  The server was configured with OpenStack with packstack.  Explore the environment to see what was pre-configured.

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

<!--BREAK-->#**Lab 3: Configure Host Networking**

##**1.1 Configure Interfaces**

The server has a single network card. bla bla here....
Configure both of the interface files at one time and then restart networking.

**Explore the current network card interface setup:**

        ovs-vsctl show
        ip a
        
Here you will notice that out of the box, packstack does not configure the interfaces.  In it's current state, *em1* has the IP address.  We need to migrate that IP address to the *br-em1* interface.

**Set up the interfaces on the server:**

Ensure the *ifcfg-em1* and *ifcfg-br-em1* files look as follows.

        
        /etc/sysconfig/network-scripts/ifcfg-br-em1
        DEVICE="br-em1"
        ONBOOT="yes"
        DEVICETYPE=ovs
        TYPE="OVSBridge"
        OVSBOOTPROTO="dhcp"
        OVSDHCPINTERFACES="em1"

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
              

**Lab 3 Complete!**

<!--BREAK-->#**Lab 4: Configure Neutron Networking**

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
