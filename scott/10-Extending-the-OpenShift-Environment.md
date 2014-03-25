#**Lab 10: Extending the OpenShift Environment**

As applications are added additional node hosts may be added to extend the capacity of the OpenShift Enterprise environment.

## 10.1 Create the node environment file
A separate heat template to launch a single node host is provided. A heat environment file will be used to simplify the heat deployment.

Create the _~/node-environment.yaml_ file and copy the following contents into it. This environment file instructs *heat* on which SSH key to use, domain, floating IP, and several other items.  Please take a minute to read through this and get a good handle on what we are passing to *heat*.

    parameters:
      key_name: adminkp
      domain: summit2014.lab
      broker1_floating_ip: 172.16.1.3
      load_bal_hostname: broker.summit2014.lab
      node_hostname: openshift.nodeinstance2.summit2014.lab
      node_image: RHEL65-x86_64-node
      hosts_domain: summit2014.lab
      replicants: broker.summit2014.lab
      install_method: yum
      rhel_repo_base: http://172.16.0.1/rhel6.5
      jboss_repo_base: http://172.16.0.1
      openshift_repo_base: http://172.16.0.1/ose-latest
      rhscl_repo_base: http://172.16.0.1
      activemq_admin_pass: password
      activemq_user_pass: password
      mcollective_pass: marionette
      private_net_id: PRIVATE_NET_ID_HERE
      public_net_id: PUBLIC_NET_ID_HERE
      private_subnet_id: PRIVATE_SUBNET_ID_HERE
      broker_floating_ip: OUTPUT_OF_NOVA_LIST

Run the following three commands to replace the placeholder text in the file with the correct IDs.

    sed -i "s/PRIVATE_NET_ID_HERE/$(neutron net-list | awk '/private/ {print $2}')/"  ~/node-environment.yaml
    sed -i "s/PUBLIC_NET_ID_HERE/$(neutron net-list | awk '/public/ {print $2}')/"  ~/node-environment.yaml
    sed -i "s/PRIVATE_SUBNET_ID_HERE/$(neutron subnet-list | awk '/private/ {print $2}')/"  ~/node-environment.yaml
    
Confirm the changes.

    cat ~/node-environment.yaml

## 10.2 Launch the node heat stack
Now run the _heat_ command and launch the stack. The -f option tells _heat_ where the template file resides. The -e option points _heat_ to the environment file that was created in the previous section.

    cd ~/

    heat stack-create ose_node \
    -f  heat-templates/openshift-enterprise/heat/neutron/highly-available/ose_node_stack.yaml \
    -e ~/node-environment.yaml


##**10.3 Monitor the stack**

List the *heat* stack

    heat stack-list

Watch the heat events.

    heat event-list openshift

    heat resource-list openshift

    nova list

##**10.4 Confirm Connectivity**

Ping the public IP of node 2

    ping x.x.x.x 

*Note the IP address of node 2. The address will be needed later in this lab.*

SSH into the node2 instance.  This may take a minute or two while they are spawning.  This will use the key that was created with *nova keypair* earlier.

SSH into the node

    ssh -i ~/adminkp.pem ec2-user@IP.OF.NODE2

Once logged in, gain root access and explore the environment.

    sudo su -

Check the OpenShift install output.

    cat /tmp/openshift.out

Check node configuration

    oo-accept-node

SSH into the broker instance to update the DNS zone file.

    ssh -i ~/adminkp.pem ec2-user@IP.OF.BROKER

Once logged in, gain root access.

    sudo su -

Add node 2 instance _A_ record to the zone file so node 2 hostname resolves.

    oo-register-dns \
    --with-node-hostname openshift.nodeinstance2 \
    --with-node-ip 172.16.1.4 \
    --domain summit2014.lab \
    --dns-server broker.summit2014.lab
    service named restart

Check hostname resolution

    host openshift.nodeinstance2.summit2014.lab

Check mcollective traffic.  You should get a response from node 2 that was deployed as part of the stack.

    oo-mco ping

**Lab 10 Complete!**

<!--BREAK-->

