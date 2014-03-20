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

# END HOST SETUP
             

**Lab Configuration Complete**

<!--BREAK-->
