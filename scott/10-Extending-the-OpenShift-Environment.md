#**Lab 10: Extending the OpenShift Environment**

As applications are added additional node hosts may be added to extend the capacity of the OpenShift Enterprise environment.

## 10.1 Create the node environment file
A separate heat template to launch a single node host is provided. A heat environment file will be used to simplify the heat deployment.

Create the _~/node-environment.yaml_ file and copy the following contents into it. This environment file instructs *heat* on which SSH key to use, domain, floating IP, and several other items.  Please take a minute to read through this and get a good handle on what we are passing to *heat*.

Create the file:

    vim ~/node-environment.yaml

With contents:

    parameters:
      key_name: adminkp
      domain: novalocal
      broker1_floating_ip: BROKER_IP
      load_bal_hostname: broker.novalocal
      node_hostname: node2.novalocal
      node_image: RHEL65-x86_64-node
      hosts_domain: novalocal
      replicants: broker.novalocal
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

Run the following four commands to replace the placeholder text in the file with the correct IDs.

    sed -i "s/BROKER_IP/$(nova list | awk '/broker_instance/ {print $13 }')/" node-environment.yaml
    sed -i "s/PRIVATE_NET_ID_HERE/$(neutron net-list | awk '/private/ {print $2}')/"  ~/node-environment.yaml
    sed -i "s/PUBLIC_NET_ID_HERE/$(neutron net-list | awk '/public/ {print $2}')/"  ~/node-environment.yaml
    sed -i "s/PRIVATE_SUBNET_ID_HERE/$(neutron subnet-list | awk '/private/ {print $2}')/"  ~/node-environment.yaml

Confirm the changes.

    cat ~/node-environment.yaml

Verify the network and subnet IDs match the output from **neutron net-list** and **neutron subnet-list**

Verify the value of BROKER_IP matches the Broker's ip from **nova list**


## 10.2 Launch the node heat stack
Now run the _heat_ command and launch the stack. The -f option tells _heat_ where the template file resides. The -e option points _heat_ to the environment file that was created in the previous section.

    heat stack-create add_node2 \
    -f  ~/heat-templates/openshift-enterprise/heat/neutron/highly-available/ose_node_stack.yaml \
    -e ~/node-environment.yaml


##**10.3 Monitor the stack**

List the *heat* stack

    heat stack-list

Watch the heat events.

    heat event-list add_node2

    heat resource-list add_node2

    nova list

##**10.4 Confirm Node2 Connectivity**

Ping the public IP of node 2

    ping 172.16.1.NODE2_IP

*Note the IP address of node 2. The address will be needed later in this lab.*

SSH into the node2 instance.  This may take a minute or two while they are spawning.  This will use the key that was created with *nova keypair* earlier.

SSH into the node

    ssh -i ~/adminkp.pem ec2-user@172.16.1.NODE2_IP

Once logged in, gain root access and explore the environment.

    sudo -i

Check the OpenShift install output.

    view /tmp/openshift.out

Check node configuration

    oo-accept-node -v

Note that this will fail because node2 does not have a fully qualified domain name. 

##**Add Node2 To Broker DNS**

SSH into the broker instance to update the DNS zone file.

    ssh -i ~/adminkp.pem ec2-user@172.16.1.BROKER_IP

Once logged in, gain root access.

    sudo -i

Add node 2 instance _A_ record to the zone file so node 2 hostname resolves. Verify the IP address matches the IP from **nova list**.

    oo-register-dns \
    --with-node-hostname node2 \
    --with-node-ip 172.16.1.4 \
    --domain novalocal \
    --dns-server broker.novalocal
    service named reload

Check hostname resolution

    host node2.novalocal

Check mcollective traffic.  You should get a response from node 2 that was deployed as part of the stack.

    oo-mco ping

##**Verify Node2**

SSH into the node

    ssh -i ~/adminkp.pem ec2-user@172.16.1.NODE2_IP

Once logged in, gain root access and explore the environment.

    sudo -i

Check the OpenShift install output.

    view /tmp/openshift.out

Check node configuration

    oo-accept-node -v

This time it should succeed.

    PASS

**Lab 10 Complete!**

<!--BREAK-->

