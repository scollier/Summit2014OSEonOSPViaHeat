# BEGIN HOST SETUP

# Get images and templates:
mkdir -p /home/images/repos
# cd /home/images
wget http://file.rdu.redhat.com/~calfonso/images/RHEL65-x86_64-node-v2.qcow2 -O /home/images/RHEL65-x86_64-node-v2.qcow2
wget http://file.rdu.redhat.com/~calfonso/images/RHEL65-x86_64-broker-v2.qcow2 -O /home/images/RHEL65-x86_64-broker-v2.qcow2
cp -v /pub/projects/rhos/scollier/summit2014/heat-templates.tgz /root/.
tar xvf /root/heat-templates.tgz -C /root/

# To run packstack, must be subscribed to rhn or you'll get errors on mysql packages
rhn-channel -u admin -p 100yard- -a -c rhel-x86_64-server-6-ost-4
rhn-channel -u admin -p 100yard- -a -c rhel-x86_64-server-rh-common-6
yum -y install rhel-guest-image-6.noarch
yum -y install openstack-packstack
yum -y install git
# copy answerfile local so it can be inspected later
cp /pub/projects/rhos/scollier/summit2014/answer_new.txt.localhost /root/.
packstack --answer-file=/root/answer_new.txt.localhost

# This should be tar'd up once confirmed and replaced with the steps below setting up repos.
# To get heat templates:
# cd /root/
# git clone https://github.com/openstack/heat-templates.git
# cd heat-templates
# to get funzo's updates
# git fetch https://review.openstack.org/openstack/heat-templates refs/changes/83/77583/1 && git checkout FETCH_HEAD
# These will make calls to external github and openshift site, so need to clean that up.
# NOTE: by summit (A3 release) we should be able to yum install -y openstack-heat-templates
# installs in /usr/share/openstack-heat-templates/

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

# An attempt to reduce the external calls from the heat templates.  Will change those to point local.
# mkdir -p /var/www/html/ose-files-from-github
cp -v /pub/projects/rhos/scollier/summit2014/github_files_to_be_placed_local/enterprise-2.0 /var/www/html/.
cp -v /pub/projects/rhos/scollier/summit2014/github_files_to_be_placed_local/openshift.sh /var/www/html/.

# reboot
# END HOST SETUP



# BEGIN STUDENT LAB
# Explain what was done to the system.  Have them explore.
# Expore the packstack answer file
Pull that from here....
look at the neutron config, bridges, etc...


# Configure the IP addresses on the host
# check out the openvswitch bridge configuration
ovs-vsctl show

# Look where the IP address for the system is.  It's on the em1 interface. We need to move it to the br-em1 interface.
ip a

# Set up the bridges to function properly.
# The /etc/sysconfig/network-scripts/ifcfg-br-em1
DEVICE="br-em1"
ONBOOT="yes"
DEVICETYPE=ovs
TYPE="OVSBridge"
OVSBOOTPROTO="dhcp"
OVSDHCPINTERFACES="em1"

# The /etc/sysconfig/network-scripts/ifcfg-em1
DEVICE="em1"
ONBOOT="yes"
TYPE="OVSPort"
OVS_BRIDGE="br-em1"
PROMISC="yes"
DEVICETYPE=ovs

# Restart networking after making the changes
service network restart
# NOTE: got knocked off of ssh

# Confirm the IP address is now on br-em1
ip a

# Configure Neutron networking
source keystonerc_admin 
neutron net-create public --provider:physical_network=physnet1 --provider:network_type flat --router:external=True
neutron net-list
neutron net-show public
neutron net-create private --provider:network_type local
neutron net-list
neutron net-show private
neutron subnet-create public --allocation-pool start=10.16.138.219,end=10.16.138.234 --gateway 10.16.143.254 --enable_dhcp=False 10.16.136.0/21 --name pub-sub
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

# The OVS stanza in the /etc/neutron/plugin.ini should look like this.  Confirm with Steve an Vinny.
[OVS]
# vxlan_udp_port=4789
# network_vlan_ranges=physnet1:1113:1114
tenant_network_type=local
enable_tunneling=False
integration_bridge=br-int
bridge_mappings=physnet1:br-em1

# restart neutron services or reboot.  I need to figure out if the below works or not.
/etc/init.d/neutron-openvswitch-agent restart
/etc/init.d/neutron-l3-agent restart
/etc/init.d/neutron-server restart

# After configuring the network, check out the network configuration in horizon interface.  Launch firefox and point to 127.0.0.1

Username: admin
Password: password

1. In the left pane, click on "Project"
2. In the left pane, click on "Network Topology"
3. In the middle pane, click on the "Normal" view
4. Hover your mouse over and click on the different network components.


# Open port 8000 for the cloud init stuff
# This needs to be confirmed.  There is a problem telneting from the broker and node to the openstack host over port 8000, that's needed for the cloud-init stuff to send signals.

iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
service iptables save

# create keypair
nova keypair-add rootkp > /root/rootkp.pem && chmod 400 /root/rootkp.pem
nova keypair-list

# copy over images and import into glance; these will be local for lab, already copied over.
# wget http://file.rdu.redhat.com/~calfonso/images/RHEL65-x86_64-node-v2.qcow2
# wget http://file.rdu.redhat.com/~calfonso/images/RHEL65-x86_64-broker-v2.qcow2
glance add name=RHEL65-x86_64-broker is_public=true disk_format=qcow2 container_format=bare < /home/images/RHEL65-x86_64-broker-v2.qcow2
glance add name=RHEL65-x86_64-node is_public=true disk_format=qcow2 container_format=bare < /home/images/RHEL65-x86_64-node-v2.qcow2
glance index

# Deploy the heat stack
# Aarons command
# heat create openshift --template-file=./heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml --parameters="key_name=rootkp;prefix=novalocal;BrokerHostname=openshift.brokerinstance.novalocal;NodeHostname=openshift.nodeinstance.novalocal;ConfInstallMethod=yum;ConfRHELRepoBase=http://refarch.cloud.lab.eng.bos.redhat.com/pub/projects/rhos/scollier/summit2014/repos/ose/rhel6.5/;ConfJBossRepoBase=http://refarch.cloud.lab.eng.bos.redhat.com/pub/projects/rhos/scollier/summit2014/repos/ose/jbappplatform-6-x86_64-server-6-rpm/;ConfRepoBase=http://refarch.cloud.lab.eng.bos.redhat.com/pub/projects/rhos/scollier/summit2014/repos/;private_net_id=875baaaa-51c0-4c23-8347-4d6d27b6d1f6;public_net_id=0426e6e2-e025-4ce7-9500-3c334ba4a43d;private_subnet_id=788ed38f-5d05-44f6-9ec4-d73c5bdc94bc;yum_validator_version=2.0;ose_version=2.0"

# Get the public / private network and the private subnet use these to replace the heat create networks
neutron net-list
neutron subnet-list

# Funzos command
# heat create openshift --template-file=./heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml --parameters="key_name=rootkp;prefix=novalocal;broker_hostname=openshift.brokerinstance.novalocal;node_hostname=openshift.nodeinstance.novalocal;conf_install_method=yum;conf_rhel_repo_base=http://10.13.129.61/rhel6.5;conf_jboss_repo_base=http://10.13.129.61;conf_ose_repo_base=http://10.13.129.61/ose-latest;conf_rhscl_repo_base=http://10.13.129.61;private_net_id=4ca13381-e3c3-45c4-ac89-b2715a031adb;public_net_id=a22951aa-bb86-4cf3-8520-5a7732608c34;private_subnet_id=c9277f3e-bc31-4133-bbd1-ec633b877304;yum_validator_version=2.0;ose_version=2.0"

heat create openshift --template-file=./heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml --parameters="key_name=rootkp;prefix=novalocal;broker_hostname=openshift.brokerinstance.novalocal;node_hostname=openshift.nodeinstance.novalocal;conf_install_method=yum;conf_rhel_repo_base=http://10.16.138.52/rhel6.5;conf_jboss_repo_base=http://10.16.138.52;conf_ose_repo_base=http://10.16.138.52/ose-latest;conf_rhscl_repo_base=http://10.16.138.52;private_net_id=c2aeaf3d-748e-42bb-bce6-d969662fa632;public_net_id=5a9d6365-3b77-4e8b-ad2f-d360143b2ae1;private_subnet_id=ce2c78ba-3396-46f5-98be-b0fbef034685;yum_validator_version=2.0;ose_version=2.0"

# aweiteka: Since there are so many params I would prefer we use an environment file:
# cat openshift-environment.yaml
parameters:
  key_name: rootkp
  prefix: novalocal
  broker_hostname: openshift.brokerinstance.novalocal
  node_hostname: openshift.nodeinstance.novalocal
  conf_install_method: yum
  conf_rhel_repo_base: http://10.16.138.52/rhel6.5
  conf_jboss_repo_base: http://10.16.138.52
  conf_ose_repo_base: http://10.16.138.52/ose-latest
  conf_rhscl_repo_base: http://10.16.138.52
  private_net_id: FIXME
  public_net_id: FIXME
  private_subnet_id: FIXME
  yum_validator_version: "2.0"
  ose_version: "2.0"

heat create openshift -f /usr/share/openshift-heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml -e /root/openshift-environment.yaml

# Watch and explore the stack-create
heat stack-list
heat stack-show openshift
heat event-list openshift
heat resource-list openshift

# heat template issues (fix or be ready to explain):
# * passwords are not hidden
# * description not accurate: "Template for setting up an AutoScaled OpenShift Enterprise environment"
# * node_count_min/max param not used (intended for autoscaling)
# * wait conditions aren't being triggered so the stack technically fails after timeout
#   * bad call to cfn-signal

# From another terminal, watch heat engine logs
tail -f /var/log/heat/heat-engine.log

# From another terminal, look at virtual machines that were created
# aweiteka: virsh feels like an openstack "anti-pattern" to me but interesting to some
virsh list
nova list

# Once you see the instances in "virsh list", give it a couple of minutes and try to ssh in.  Get the public IP address from "nova list"
# SSH into both the broker and the node.  If you get a "No route to host", it's still booting up.
ssh -i ~/rootkp.pem ec2-user@10.16.138.x
ssh -i ~/rootkp.pem ec2-user@10.16.138.x
# to do anything useful, at login...
$ sudo sh -
#

# Get vnc session to VM; open the link and watch the process.
nova get-vnc-console broker_instance novnc
nova get-vnc-console node_instance novnc

# aweiteka: this stuff is pretty deep. went over my head as far as usefulness. lots of explaination needed, IMHO
# look at nat table on host, notice the mapping
iptables -nvL -t nat

# look at namespaced networking 
ip netns show
ip netns exec qrouter-b97b3167-ad47-4465-b873-fabe0fca9bee iptables -nvL -t nat
ip netns exec qrouter-b97b3167-ad47-4465-b873-fabe0fca9bee route -n
ip netns exec qrouter-b97b3167-ad47-4465-b873-fabe0fca9bee ip r l


# ping the private / public interface
ip netns exec qrouter-b97b3167-ad47-4465-b873-fabe0fca9bee ping 192.168.0.2
ip netns exec qrouter-b97b3167-ad47-4465-b873-fabe0fca9bee ping 10.16.138.221

# END STUDENT SETUP

# BEGIN OPENSHIFT LABS
# from broker host:
oo-mco ping
oo-diagnostics -v

Login to OpenShift console.
User: demo
Password: changeme

Deploy app via web console

Deploy app via client tools


# END OPENSHIFT LABS



# GENERAL TROUBLESHOOTING STEPS, NOT GOING IN LAB.
# Troubleshooting steps to bring up another base, none heat instance
glance add name=rhel65basic is_public=true disk_format=qcow2 container_format=bare < /usr/share/rhel-guest-image-6/rhel-guest-image-6-6.5-20140121.0-1.qcow2
neutron net-list
nova boot --flavor 2 --image rhel65basic --nic net-id=db6c8dbe-e7e3-4939-901c-77bdc003a08d --key-name rootkp rhel65basic
neutron floatingip-create public
nova list
neutron port-list --device_id 4b37f6d1-d9ee-447e-a433-9b001b8a209e
neutron floatingip-list
neutron floatingip-associate 6086d84e-88fc-4dda-b78a-1c267a5e667b 268e5140-d4ba-4673-87c7-f9227aa43df4
nova list
# Could not ping that public IP either.
After talking to Vinny, the problem was that the IP address was on the wrong interface.  To fix, he moved the IP address from em1 to br-em1.  This became evident through some exploration of "ovs-vsctl show" and comparing to what funzo had on his system.

# Changes to heat templates
pointed the wget for openshift to refarch.  that will need to point local, or to a lab server at summit.
if using external github, had to add a --no-certificate-check

had to change all repo paths.

