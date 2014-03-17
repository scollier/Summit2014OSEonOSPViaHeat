#**Lab Configuration - INSTRUCTOR ONLY**


# Get images and templates:

    mkdir -p /home/images/repos
    wget http://file.rdu.redhat.com/~calfonso/images/RHEL65-x86_64-node-v2.qcow2 -O /home/images/RHEL65-x86_64-node-v2.qcow2
    wget http://file.rdu.redhat.com/~calfonso/images/RHEL65-x86_64-broker-v2.qcow2 -O /home/images/RHEL65-x86_64-broker-v2.qcow2
    cp -v /pub/projects/rhos/scollier/summit2014/heat-templates.tgz /root/.
    tar xvf /root/heat-templates.tgz -C /root/

#Subscribe to the appropriate channels:

    rhn-channel -u admin -p PASSWORD -a -c rhel-x86_64-server-6-ost-4
    rhn-channel -u admin -p PASSWORD -a -c rhel-x86_64-server-rh-common-6
    yum -y install rhel-guest-image-6.noarch
    yum -y install openstack-packstack
    yum -y install git


# Copy answerfile local so it can be inspected by the students

    cp /pub/projects/rhos/scollier/summit2014/answer_new.txt.localhost /root/answer.txt

# Run packstack

    packstack --answer-file=/root/answer.txt


# Set up the repos

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

# Copy github content local

    cp -v /pub/projects/rhos/scollier/summit2014/github_files_to_be_placed_local/enterprise-2.0 /var/www/html/.
    cp -v /pub/projects/rhos/scollier/summit2014/github_files_to_be_placed_local/openshift.sh /var/www/html/.
    

# Reboot the system to complete setup

    reboot

# END HOST SETUP
             

**Lab Configuration Complete**

<!--BREAK-->
