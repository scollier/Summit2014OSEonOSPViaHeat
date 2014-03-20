#**Lab 6: Deploy Heat Stack**

##**6.1 Import the Images into Glance**


All actions in this lab will performed by the *admin* tenant in this lab.  In a production enviroinment there will likely be many tenants.

    source ~/keystonerc_admin


The names of these images are hard coded in the heat template.  Do not change the name here.

    glance image-create --name RHEL65-x86_64-broker --is-public true --disk-format qcow2 \
        --container-format bare --file /home/images/RHEL65-x86_64-broker-v2.qcow2
    
    glance image-create --name RHEL65-x86_64-node --is-public true --disk-format qcow2 \
        --container-format bare --file /home/images/RHEL65-x86_64-node-v2.qcow2
    
    glance image-list


##**6.2 Ensure the heat.conf file is confirgured correctly**

Ensure the following variables are set in the **/etc/heat/heat.conf** file:

    sed -i '/^heat_/s/127.0.0.1/172.16.0.1/g' /etc/heat/heat.conf

This command will change these specific parameters in **/etc/heat/heat.conf**

    # heat_metadata_server_url=http://IP of Controller:8000
    heat_metadata_server_url=http://172.16.0.1:8000
    # heat_waitcondition_server_url=http://IP of Controller:8000/v1/waitcondition
    heat_waitcondition_server_url=http://172.16.0.1:8000/v1/waitcondition
    # heat_watch_server_url=http://IP of Controller:8003
    heat_watch_server_url=http://172.16.0.1:8003

Restart heat services

    for i in openstack-heat-api openstack-heat-api-cfn openstack-heat-engine; do service $i restart; done


##**6.3 Modify the openshift-environment file**


**Modify the openshift-environment.yaml file:**


###**Scripted Steps**
Run the following three commands to replace the placeholder text in the file with the correct IDs. For a full explanation and details manual steps see the next section:

    sed -i "s/PRIVATE_NET_ID_HERE/$(neutron net-list | awk '/private/ {print $2}')/"  ~/openshift-environment.yaml
    sed -i "s/PUBLIC_NET_ID_HERE/$(neutron net-list | awk '/public/ {print $2}')/"  ~/openshift-environment.yaml
    sed -i "s/PRIVATE_SUBNET_ID_HERE/$(neutron subnet-list | awk '/priv-sub/ {print $2}')/"  ~/openshift-environment.yaml

###**Manual Steps**
Run the following two commands to list the configured networks and subnets. Copy and paste each corresponding ID with the parameter in the next section. The IDs are as follows: private_net_id: PUBLICH_NET_ID_HERE, public_net_id: PRIVATE_NET_ID_HERE, and private_subnet_id: PRIVATE_SUBNET_ID_HERE.

    neutron net-list
    neutron subnet-list

Edit the */root/openshift-environment.yaml* file and replace the placeholder text PUBLC_NET_ID_HERE, PRIVATE_NET_ID_HERE, and PRIVATE_SUBNET_ID_HERE with the actual UUID from the output of the previous commands.

    parameters:
      key_name: adminkp
      prefix: novalocal
      broker_hostname: openshift.brokerinstance.novalocal
      node_hostname: openshift.nodeinstance.novalocal
      conf_install_method: yum
      conf_rhel_repo_base: http://172.16.0.1/rhel6.5
      conf_jboss_repo_base: http://172.16.0.1
      conf_ose_repo_base: http://172.16.0.1/ose-latest
      # conf_rhscl_repo_base: http://IP_OF_HOST
      conf_rhscl_repo_base: http://172.16.0.1
      private_net_id: PRIVATE_NET_ID_HERE
      public_net_id: PUBLIC_NET_ID_HERE
      private_subnet_id: PRIVATE_SUBNET_ID_HERE
      yum_validator_version: "2.0"
      ose_version: "2.0"

##**6.4 Open the port for Return Signals**

The *broker* and *node* VMs need to be able to deliver a completed signal to the metadata service.

**WARNING**: Do NOT use lokkit as it will overwrite the custom iptables rules created by packstack

    sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
    sudo service iptables save


##**6.5 Launch the stack**

Now run the *heat* command and launch the stack. The -f option tells *heat* where the template file resides.  The -e option points *heat* to the environment file that was created in the previous section.

**Note: it can take up to 10 minutes for this to complete**

    source ~/keystonerc_admin    

    cd ~

    heat create openshift \
    -f heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml \
    -e /root/openshift-environment.yaml


##**6.6 Monitor the stack**

List the *heat* stack

    heat stack-list

Watch the heat events.

    sudo tail -f /var/log/heat/heat-engine.log &

    heat event-list openshift

    heat resource-list openshift

    nova list

Once the stack is successfully built the wait_condition states for both broker and node will change to CREATE_COMPLETE

    | broker_wait_condition               | 65 | state changed          | CREATE_COMPLETE    | 2014-03-19T21:51:30Z |
    | node_wait_condition                 | 66 | state changed          | CREATE_COMPLETE    | 2014-03-19T21:52:01Z |


Get a VNC console address and open it in the browser.  Firefox must be launched from the hypervisor host, the host that is running the VM's.

    nova get-vnc-console broker_instance novnc
    
    nova get-vnc-console node_instance novnc

##**6.7 Confirm Connectivity**

Confirm which IP address belongs to the broker and to the node.

    nova list

Ping the public IP of the instance.  Get the public IP by running *nova list* on the controller.

    ping 172.16.1.X
    
SSH into the broker instance.  This may take a minute or two while they are spawning.  Use the key that was created with *nova keypair* earlier and the username of *ec2-user*:

    ssh -i ~/adminkp.pem ec2-user@172.16.1.BROKER_IP

Once logged in, gain root access and explore the environment.

    sudo su -

Check the OpenShift install output.

    cat /tmp/openshift.out

Check mcollective traffic.  You should get a response from the node that was deployed as part of the stack.

    oo-mco ping
    
    oo-diagnostics -v
    
    oo-accept-broker -v

SSH into the node, using the IP that was obtained above.

    ssh -i ~/adminkp.pem ec2-user@172.16.1.NODE_IP
    
Check node configuration

    oo-accept-node

Confirm Console Access by opening a browser and putting in the IP address of the broker.

http://172.16.1.BROKER_IP/console

username: demo
password: changeme

**FILL OUT THIS**

FILL OUT THIS

**Lab 6 Complete!**

<!--BREAK-->

