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

