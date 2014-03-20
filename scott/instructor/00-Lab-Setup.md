#**Lab Configuration - INSTRUCTOR ONLY**

# Subscribe to the appropriate channels:

    SAT_PASSWD=#Enter Satellite Password Here
    rhn-channel -u admin -p $SAT_PASSWD -a -c rhel-x86_64-server-6-ost-4
    rhn-channel -u admin -p $SAT_PASSWD -a -c rhel-x86_64-server-rh-common-6
    yum -y install rhel-guest-image-6.noarch openstack-packstack git

Verify repositories are available

    yum repolist

# Sync and create local repos

    mkdir -p /var/www/html/repos
    reposync -lmnp /var/www/html/repos/
    yum -y install createrepo
    createrepo /var/www/html/repos/rhel-x86_64-server-6-ost-4/
    createrepo /var/www/html/repos/rhel-x86_64-server-rh-common-6/
    createrepo -g /var/www/html/repos/rhel-x86_64-server-6/comps.xml /var/www/html/repos/rhel-x86_64-server-6/

# Create local repo file
    cat << EOF >> /etc/yum.repos.d/summit2014.repo
    [rhel-6.5]
    name=Summit 2014 rhel6.5
    baseurl=file:///var/www/html/repos/rhel-x86_64-server-6/
    gpgcheck=0
    enabled=1
    
    [rhel-osp-4]
    name=Summit 2014 rhel-osp-4
    baseurl=file:///var/www/html/repos/rhel-x86_64-server-6-ost-4/
    gpgcheck=0
    enabled=1
    
    [rh-common]
    name=Summit 2014 rh-common
    baseurl=file:///var/www/html/repos/rhel-x86_64-server-rh-common-6/
    gpgcheck=0
    enabled=1
    EOF

# Remove Satellite registration and test local repos

    rm -rf /etc/sysconfig/rhn/systemid
    yum repolist

# Create user on the system

    useradd user
    echo password | passwd user --stdin

# Get images and templates:

    mkdir -p /home/images/repos
    wget http://file.rdu.redhat.com/~calfonso/images/RHEL65-x86_64-node-v2.qcow2 -O /home/images/RHEL65-x86_64-node-v2.qcow2
    wget http://file.rdu.redhat.com/~calfonso/images/RHEL65-x86_64-broker-v2.qcow2 -O /home/images/RHEL65-x86_64-broker-v2.qcow2
    wget http://refarch.cloud.lab.eng.bos.redhat.com/pub/projects/rhos/scollier/summit2014/heat-templates.tgz -O /home/user/heat-templates.tgz
    tar xvf /home/user/heat-templates.tgz -C /home/user/

# Add NFS mount if needed

    mount -t nfs -o vers=3 refarch.cloud.lab.eng.bos.redhat.com:/pub /pub

# Set up the remaining repos

    mkdir -p /var/www/html/jbeap/6
    mkdir -p /var/www/html/jbews/2/
    mkdir -p /var/www/html/rhscl/1
    cp -rv /pub/projects/rhos/scollier/summit2014/repos/funzos_config_keep/* /home/images/repos/.
    cd /var/www/html/jbeap/6
    ln -s /home/images/repos/jb-eap-6-for-rhel-6-server-rpms /var/www/html/jbeap/6/os
    ln -s /home/images/repos/jb-eap-6-for-rhel-6-server-rpms /var/www/html/jb-eap
    ln -s /home/images/repos/jb-ews-2-for-rhel-6-server-rpms /var/www/html/jbews/2/os
    ln -s /home/images/repos/latest /var/www/html/ose-latest
    ln -s /home/images/repos/rhel6.5 /var/www/html/rhel6.5
    ln -s /home/images/repos/rhscl /var/www/html/rhscl/1/os
    wget http://refarch.cloud.lab.eng.bos.redhat.com/pub/projects/rhos/scollier/summit2014/RHOSE-CLIENT-2.0.repo -O /etc/yum.repos.d/RHOSE-CLIENT-2.0.repo

Verify OpenShift repositories

    yum repolist

# Copy github content local

    cp -v /pub/projects/rhos/scollier/summit2014/github_files_to_be_placed_local/enterprise-2.0 /var/www/html/.
    cp -v /pub/projects/rhos/scollier/summit2014/github_files_to_be_placed_local/openshift.sh /var/www/html/.
    cp -v /pub/projects/rhos/scollier/summit2014/openshift-environment.yaml /home/user/.
    
# Copy answerfile local so it can be inspected by the students

    wget http://refarch.cloud.lab.eng.bos.redhat.com/pub/projects/rhos/scollier/summit2014/answer_new.txt.localhost -O /home/user/answer.txt

# Run packstack

    packstack --debug --answer-file=/home/user/answer.txt

# Validate Setup

Load keystonerc file

    source ~/keystonerc_admin

List OpenStack services

    nova service-list

Brose to the Horizon dashboard at **http://localhost** with username: admin password: password

To login to the horizon dashboard via CLI:

    yum -y install links
    links http://localhost

# Copy keystonerc_admin to user directory

    cp /root/keystonerc_admin /home/user/keystonerc_admin

# Change ownership to user

    chown -Rv user.user /home/user
    restorecon -Rv /home/user

# Add sudo permissions for user

    visudo

Add the following line in the file

    %user ALL=/usr/bin/ovs-vsctl, /sbin/service, /sbin/reboot, /sbin/iptables

#Modify the heat.conf file

Ensure the following variables are set in the **/etc/heat/heat.conf** file:

    sed -i '/^heat_/s/127.0.0.1/172.16.0.1/g' /etc/heat/heat.conf

This command will change these specific parameters in **/etc/heat/heat.conf**

    grep "^heat_" /etc/heat/heat.conf

Output:

    heat_metadata_server_url=http://172.16.0.1:8000
    heat_waitcondition_server_url=http://172.16.0.1:8000/v1/waitcondition
    heat_watch_server_url=http://172.16.0.1:8003

Restart heat services

    for i in openstack-heat-api openstack-heat-api-cfn openstack-heat-engine; do service $i restart; done


#**Set up the interfaces on the server:**

For this lab we will need 3 interfaces. The DHCP interface will be *em1*. The interface *em1* will be associated with the *br-public* bridge. Lastly, a new interface *classroom* will be created and assume the MAC address of *em1* for external communications. Ensure the *ifcfg-em1*, *ifcfg-br-public*, and *ifcfg-classroom* files look as follows.  The *ifcfg-br-public* and *ifcfg-classroom* files will have to be created.  The three files on the host should look exactly the same as what is listed below.

Before configuring these files, first copy the MAC address from the system *em1* interface

    ip a show dev em1

The MAC Address is on the second line of output on the link/ether line:

    2: em1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
        link/ether f0:4d:a2:3b:a0:59 brd ff:ff:ff:ff:ff:ff
        inet 10.16.138.52/21 brd 10.16.143.255 scope global em1
        inet6 fe80::f24d:a2ff:fe3b:a059/64 scope link 
           valid_lft forever preferred_lft forever
    
Alternatively, this script will display only the MAC Address:

    ip a show dev em1 | awk 'NR==2{print $2}'
    f0:4d:a2:3b:a0:59

Create the file **/etc/sysconfig/network-scripts/ifcfg-br-public** with the following contents. Note the line MACADDR will use a fabricated MAC address. Change the 1st and 2nd bytes (5th and 6th octets in the right most position) to match your lab station number. Remember to convert to hex:

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-public
    DEVICE="br-public"
    ONBOOT="yes"
    DEVICETYPE=ovs
    TYPE="OVSBridge"
    OVSBOOTPROTO="static"
    IPADDR="172.16.0.1"
    NETMASK="255.255.0.0"
    MACADDR=de:ad:be:ef:00:00
    EOF

The configuration file for em1 exists already, edit **/etc/sysconfig/network-scripts/ifcfg-em1** to contain the following contents. Use the same MAC address specified in the previous file:

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
    DEVICE="em1"
    ONBOOT="yes"
    TYPE="OVSPort"
    OVS_BRIDGE="br-public"
    PROMISC="yes"
    DEVICETYPE="ovs"
    MACADDR=de:ad:be:ef:00:00
    EOF

    
Configure a new interface called *classroom* to provide external access. Create the file **/etc/sysconfig/network/ifcfg-classroom** with the contents. Use the MAC address that was copied from the original *em1* interface:

    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-classroom
    DEVICE="classroom"
    ONBOOT="yes"
    TYPE="OVSIntPort"
    OVS_BRIDGE="br-public"
    DEVICETYPE="ovs"
    BOOTPROTO=dhcp
    OVS_EXTRA="set Interface classroom type=internal"
    MACADDR=f0:4d:a2:3b:a0:59
    EOF

**Restart Networking and review the interface configuration:**

Restart networking services

    service network restart

Note: Due to the reassigning of MAC addresses errors may occur until a reboot. If needed reboot:

    reboot

# END HOST SETUP
             

**Lab Configuration Complete**

<!--BREAK-->
