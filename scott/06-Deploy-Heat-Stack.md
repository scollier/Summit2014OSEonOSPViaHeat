#**Lab 6: Deploy Heat Stack**

##**6.1 Import the Images into Glance**


All actions in this lab will performed by the *admin* tenant in this lab.  In a production enviroinment there will likely be many tenants.

    source /root/keystonerc_admin


The names of these images are hard coded in the heat template.  Do not change the name here.

    glance add name=RHEL65-x86_64-broker is_public=true disk_format=qcow2 \
    container_format=bare < /home/images/RHEL65-x86_64-broker-v2.qcow2
    
    glance add name=RHEL65-x86_64-node is_public=true disk_format=qcow2 \
    container_format=bare < /home/images/RHEL65-x86_64-node-v2.qcow2
    
    glance image-list


##**6.2 Ensure the heat.conf file is confirgured correctly**

Ensure the following variables are set in the /etc/heat/heat.conf file:

    # heat_metadata_server_url=http://IP of Controller:8000
    heat_metadata_server_url=http://172.10.0.1:8000
    # heat_waitcondition_server_url=http://IP of Controller:8000/v1/waitcondition
    heat_waitcondition_server_url=http://172.10.0.1:8000/v1/waitcondition
    # heat_watch_server_url=http://IP of Controller:8003
    heat_watch_server_url=http://172.10.0.1:8003


##**6.3 Create the openshift-environment file**


**Create the openshift-environment.yaml file:**

Get the private and public network IDs as well as the private subnet ID out of the first column of the output of the below commands.  Place those parameters in the following file in the following fields: private_net_id: public_net_id: private_subnet_id: to replace FIXME.

    neutron net-list
    neutron subnet-list

Create the */root/openshift-environment.yaml* file and copy the following contents into it. For the IP address of the repo locations, please replace with the IP address of the host you are on.

    parameters:
      key_name: rootkp
      prefix: novalocal
      broker_hostname: openshift.brokerinstance.novalocal
      node_hostname: openshift.nodeinstance.novalocal
      conf_install_method: yum
      # conf_rhel_repo_base: http://IP_OF_HOST/rhel6.5
      conf_rhel_repo_base: http://172.10.0.1/rhel6.5
      # conf_jboss_repo_base: http://IP_OF_HOST
      conf_jboss_repo_base: http://172.10.0.1
      # conf_ose_repo_base: http://IP_OF_HOST/ose-latest
      conf_ose_repo_base: http://172.10.0.1/ose-latest
      # conf_rhscl_repo_base: http://IP_OF_HOST
      conf_rhscl_repo_base: http://172.10.0.1
      private_net_id: FIXME
      public_net_id: FIXME
      private_subnet_id: FIXME
      yum_validator_version: "2.0"
      ose_version: "2.0"

##**6.4 Open the port for Return Signals**

The *broker* and *node* VMs need to be able to deliver a completed signal to the metadata service.

    iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
    service iptables save


##**6.5 Launch the stack**

Now run the *heat* command and launch the stack. The -f option tells *heat* where the template file resides.  The -e option points *heat* to the environment file that was created in the previous section.

**Note: it can take up to 10 minutes for this to complete**

    source /root/keystonerc_admin    

    cd /root/

    heat create openshift \
    -f heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml \
    -e /root/openshift-environment.yaml


##**6.6 Monitor the stack**

List the *heat* stack

    heat stack-list

Watch the heat events.

    heat event-list openshift

    heat resource-list openshift

    nova list

Get a VNC console address and open it in the browser.  Firefox must be launched from the hypervisor host, the host that is running the VM's.

    nova get-vnc-console broker_instance novnc
    
    nova get-vnc-console node_instance novnc

##**6.7 Confirm Connectivity**

Ping the public IP of the instance.  Get the public IP by running *nova list* on the controller.

    ping x.x.x.x 
    
SSH into the broker instance.  This may take a minute or two while they are spawning.  This will use the key that was created with *nova keypair* earlier.

Confirm which IP address belongs to the broker and to the node.

    nova list

SSH into the broker

    ssh -i ~/adminkp.pem ec2-user@IP.OF.BROKER

Once logged in, gain root access and explore the environment.

    sudo su -

Check the OpenShift install output.

    cat /tmp/openshift.out

Check mcollective traffic.  You should get a response from the node that was deployed as part of the stack.

    oo-mco ping
    
    oo-diagnostics -v
    
    oo-accept-broker -v

SSH into the node, using the IP that was obtained above.

    ssh -i ~/rootkp.pem ec2-user@IP.OF.NODE
    
Check node configuration

    oo-accept-node

Confirm Console Access by opening a browser and putting in the IP address of the broker.

http://IP.OF.BROKER/console

**FILL OUT THIS**

FILL OUT THIS

**Lab 6 Complete!**

<!--BREAK-->

