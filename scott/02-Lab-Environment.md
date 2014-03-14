#**Lab 2: Lab Environment**

#**2 Server Configuration**

Each student will either recieve his / her own server or will share with another student. The server has Red Hat Enterprise Linux 6.5 install as the base operating system.  The server was configured with OpenStack with packstack.  Explore the environment to see what was pre-configured.


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