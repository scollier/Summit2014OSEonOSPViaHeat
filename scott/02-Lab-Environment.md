#**Lab 2: Lab Environment**

#**2 Server Configuration**

Each student will recieve their own server or will share with another student. The server has Red Hat Enterprise Linux 6.5 installed as the base operating system.  The server was configured with OpenStack using packstack.  Explore the environment to see what was pre-configured. The end result will consist of a Controller host (hypervisor) and 3 virtual machines: 1 OpenShift broker and 2 OpenShift nodes.

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
    
These two images were pre-built using disk image builder (DIB) for the purpose of saving time in the lab. The commands used to build these images will be inserted here. <SCOLLIER TO INSERT>

**Check out the software repositories:**

    yum repolist

**View OpenStack services**

Load the keystonerc_admin file which contains the authentication token information:

    source ~/keystonerc_admin

List OpenStack services running on this system:

    nova service-list

**Lab 2 Complete!**

<!--BREAK-->


