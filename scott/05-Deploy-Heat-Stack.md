#**Lab 5: Deploy Heat Stack**

##**5.1 Import the Images into Glance**


All actions in this lab will performed by the *admin* tenant in this lab.  In a production enviroinment there will likely be many tenants.

    source ~/keystonerc_admin


The names of these images are hard coded in the heat template.  Do not change the name here.  These images were created via disk image-builder (DIB) prior to the lab to save time.  For more information on how to create these images, please check the upstream README.

https://github.com/openstack/heat-templates/blob/master/openshift-enterprise/README.rst

    glance image-create --name RHEL65-x86_64-broker --is-public true --disk-format qcow2 \
        --container-format bare --file /home/images/RHEL65-x86_64-broker-v2.qcow2
    glance image-create --name RHEL65-x86_64-node --is-public true --disk-format qcow2 \
        --container-format bare --file /home/images/RHEL65-x86_64-node-v2.qcow2
    glance image-list



##**5.2 Modify the openshift-environment file**

There are two ways to pass parameters to the *heat* command.  The first is via the *heat* CLI.  The second is to via an environment file.  This lab uses the environment file method because it makes it easier to organize the parameters. 

Review the provided environment file with placeholder text:

    parameters:
      key_name: adminkp
      prefix: summit2014.lab
      broker_hostname: broker.summit2014.lab
      node_hostname: node1.summit2014.lab
      conf_install_method: yum
      conf_rhel_repo_base: http://172.16.0.1/rhel6.5
      conf_jboss_repo_base: http://172.16.0.1
      conf_ose_repo_base: http://172.16.0.1/ose-latest
      conf_rhscl_repo_base: http://172.16.0.1
      private_net_id: PRIVATE_NET_ID_HERE
      public_net_id: PUBLIC_NET_ID_HERE
      private_subnet_id: PRIVATE_SUBNET_ID_HERE
      yum_validator_version: "2.0"
      ose_version: "2.0"
    
Run the following three commands to replace the placeholder text in the file with the correct IDs. For a full explanation and detailed manual steps see the next section:

    sed -i "s/PRIVATE_NET_ID_HERE/$(neutron net-list | awk '/private/ {print $2}')/"  ~/openshift-environment.yaml
    sed -i "s/PUBLIC_NET_ID_HERE/$(neutron net-list | awk '/public/ {print $2}')/"  ~/openshift-environment.yaml
    sed -i "s/PRIVATE_SUBNET_ID_HERE/$(neutron subnet-list | awk '/private/ {print $2}')/"  ~/openshift-environment.yaml

The scripts in the previous section should have added the correct network IDs to the yaml file. Run the following two commands to list the configured networks and subnets. 

    neutron net-list
    neutron subnet-list

Inspect the *~/openshift-environment.yaml* file and verify the placeholder text PUBLC_NET_ID_HERE, PRIVATE_NET_ID_HERE, and PRIVATE_SUBNET_ID_HERE were replaced with the actual UUID from the output of the previous commands.

    cat ~/openshift-environment.yaml

Contents should resemble the following (the IDs will be different):

    parameters:
      key_name: adminkp
      prefix: summit2014.lab
      broker_hostname: broker.summit2014.lab
      node_hostname: node1.summit2014.lab
      conf_install_method: yum
      conf_rhel_repo_base: http://172.16.0.1/rhel6.5
      conf_jboss_repo_base: http://172.16.0.1
      conf_ose_repo_base: http://172.16.0.1/ose-latest
      conf_rhscl_repo_base: http://172.16.0.1
      private_net_id: 9eb390d1-a1ad-4545-82db-a16f18fac959
      public_net_id: 84078660-baf4-4b51-a790-759fb897a5f5
      private_subnet_id: bbd59b2e-0eee-4e3d-8bae-85cc91201ecd
      yum_validator_version: "2.0"
      ose_version: "2.0"

##**5.3 Open the port for Return Signals**

Once the *heat* stack launches, several steps are performed, such as:
* Configuring security groups for the broker and the node
* Setting up the *broker* and *node* ports
* Setting up the floating IPs
* Installing any neccessary packages
* Configuring OpenShift


When these tasks are finished, the *broker* and *node* VMs need to be able to deliver a completed signal to the metadata service.

Open the correct port to allow the signal to pass.

**WARNING**: Do NOT use *lokkit* as it will overwrite the custom iptables rules created by packstack

    sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT

Save the new rule:

    sudo service iptables save


##**5.4 Launch the stack**

Get a feel for the options that *heat* supports.

    heat --help
    which heat
    sudo rpm -qa | grep heat
    sudo rpm -qc openstack-heat-common
    sudo rpm -qf $(which heat)

Now run the *heat* command and launch the stack. The -f option tells *heat* where the template file resides.  The -e option points *heat* to the environment file that was created in the previous section.

    . ~/keystone_admin

**Note: it can take up to 10 minutes for this to complete**

    heat create openshift \
    -f ~/heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml \
    -e ~/openshift-environment.yaml


##**5.5 Monitor the stack**

There are several ways to monitor the status of the deployment.  

Get a VNC console address and open it in the browser.  Firefox must be launched from the hypervisor host, the host that is running the VM's.

    nova get-vnc-console broker_instance novnc
    
    nova get-vnc-console node_instance novnc

Alternatively, in Horizon:

* Under *Project* select *Instances*
* On the right pane select either *broker_instance* or *node_instance*
* Select *Console*


Open another terminal and tail the heat log:

    sudo tail -f /var/log/heat/heat-engine.log &


List the *heat* stack

    heat stack-list

Watch the heat events with the following command:

    heat event-list openshift

Each resouce can also be monitored with:

    heat resource-list openshift

Once the instances are launched they can be view with:

    nova list


Once the stack is successfully built the wait_condition states for both broker and node will change to CREATE_COMPLETE

    | broker_wait_condition               | 65 | state changed          | CREATE_COMPLETE    | 2014-03-19T21:51:30Z |
    | node_wait_condition                 | 66 | state changed          | CREATE_COMPLETE    | 2014-03-19T21:52:01Z |

Alternatively open Firefox and login to the Horizon dashboard to watch the heat stack status:

* Open Firefox and browse to http://localhost
* Login with *admin*:*password*
* Select *Project* on the left
* Under *Orchestration* select *Stacks*
* Select *OpenShift* on the right pane
* Enjoy the eye candy


**Lab 5 Complete!**

<!--BREAK-->

