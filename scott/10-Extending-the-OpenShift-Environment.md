#**Lab 10: Extending the OpenShift Environment**

As applications are added additional node hosts may be added to extend the capacity of the OpenShift Enterprise environment.

## 10.1 Create the node environment file
A separate heat template to launch a single node host is provided. A heat environment file will be used to simplify the heat deployment.

Create the _/root/node-environment.yaml_ file and copy the following contents into it.


    parameters:
      key_name: rootkp
      domain: novalocal
      broker1_floating_ip: 10.16.138.100
      load_bal_hostname: openshift.brokerinstance.novalocal
      node_hostname: openshift.nodeinstance2.novalocal
      node_image: RHEL65-x86_64-node
      install_method: yum
      rhel_repo_base: http://10.16.138.52/rhel6.5
      jboss_repo_base: http://10.16.138.52
      openshift_repo_base: http://10.16.138.52/ose-latest
      rhscl_repo_base: http://10.16.138.52
      private_net_id: FIXME
      public_net_id: FIXME
      private_subnet_id: FIXME

## 10.2 Launch the node heat stack
Now run the _heat_ command and launch the stack. The -f option tells _heat_ where the template file resides. The -e option points _heat_ to the environment file that was created in the previous section.

    cd /root/

    heat stack-create ose_node \
    -f  heat-templates/openshift-enterprise/heat/neutron/highly-available/ose_node_stack.yaml \
    -e /root/node-environment.yaml


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

SSH into the node2 instance.  This may take a minute or two while they are spawning.  This will use the key that was created with *nova keypair* earlier.

SSH into the node

    ssh -i ~/rootkp.pem ec2-user@IP.OF.NODE2

Once logged in, gain root access and explore the environment.

    sudo su -

Check the OpenShift install output.

    cat /tmp/openshift.out

Check node configuration

    oo-accept-node

SSH into the broker instance to update the DNS zone file.

    ssh -i ~/rootkp.pem ec2-user@IP.OF.BROKER

Once logged in, gain root access.

    sudo su -

Append the node 2 instance _A_ record to the zone file so node 2 hostname resolves.

    echo "openshift.nodeinstance2    A   IP.OF.NODE2" >> /var/named/dynamic/novalocal.db

Check mcollective traffic.  You should get a response from node 2 that was deployed as part of the stack.

    oo-mco ping

**Lab 10 Complete!**

<!--BREAK-->
