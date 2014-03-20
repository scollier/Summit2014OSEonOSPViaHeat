#**Lab 2: Lab Environment**

#**2 Server Configuration**

Each student will recieve their own server or will share with another student. The server has Red Hat Enterprise Linux 6.5 installed as the base operating system.  The server was configured with OpenStack using packstack.  Explore the environment to see what was pre-configured. The end result will consist of a Controller host (hypervisor) and 3 virtual machines: 1 OpenShift broker and 2 OpenShift nodes.

![Lab Configuration](http://summitimage-scollier1.rhcloud.com/summit_lab.png)


**Local User**
Everything in the lab will be performed with the following user and password:

    user: user
    Password: password

Sudo access will be provided for certain commands.

**System Partitions**

**WARNING!!!** There are multiple partitions on this system. It is VITAL that you only ever boot into or modify partition <X NEED TO FILL THIS OUT>. Do not mount the other partition or make any changes to the boot loader. Doing so will violate the spirit of Summit and make the panda very sad.

If you have to reboot the system, select partition X NEED TO FILL THIS OUT.


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
    
These two images were pre-built using disk image builder(DIB) for the purpose of saving time in the lab. The commands used to build these images will be inserted here. <SCOLLIER TO INSERT>

**Check out the software repositories:**

    yum repolist

**View OpenStack services**

Load the keystonerc_admin file which contains the authentication token information:

    source ~/keystonerc_admin

List OpenStack services running on this system:

    nova service-list

**Lab 2 Complete!**

<!--BREAK-->


