#**Lab 6: Explore the OpenShift Environment**

##**6.1 List the Instances and Connect**

Confirm which IP address belongs to the broker and to the node.

    nova list

###**6.2 Explore the OpenShift Broker**

Ping the public IP of the instance.  Get the public IP by running *nova list* on the controller.  The public IP will start with 172.

    ping 172.16.1.BROKER_IP
    
SSH into the broker instance.  This may take a minute or two while they are spawning.  Use the key that was created with *nova keypair* earlier and the username of *ec2-user*:

    ssh -i ~/adminkp.pem ec2-user@172.16.1.BROKER_IP

Once logged in, gain root access and explore the environment.

    sudo -i

Check the OpenShift install output.  At the end of hte file, you shuold see "Installation and configuration is complete".  This ensures that everything worked as planned.  Spend some time in here to look at all the configuration steps that were performed.  Also explore the cloud-init output files. Ignore any notices about NTP, it is because the lab does not have network connectivity.

    view /tmp/openshift.out
    
    view /var/log/cfn-signal.log
    
    view /var/log/cloud-init.log
    
    view /var/log/cloud-init-output.log

Now confirm OpenShift functionality. See what tools are available by tabbing out the oo-    command.

    oo-<tab><tab>

Check mcollective traffic.  You should get a response from the node that was deployed as part of the stack.

    oo-mco ping
    
Run some diagnostics to confirm functionality.  You should get a PASS and NO ERRORS on each of these.
    
    oo-diagnostics -v

Look for the output: **NO ERRORS**
    
    oo-accept-broker -v

Look for the output: **PASS**

###**6.2 Explore the OpenShift Node**

SSH into the node, using the IP that was obtained above.

    ssh -i ~/adminkp.pem ec2-user@172.16.1.NODE_IP
    sudo -i

Once logged in, gain root access and explore the environment.
    
    view /tmp/openshift.out
    
    view /var/log/cfn-signal.log
    
    view /var/log/cloud-init.log
    
    view /var/log/cloud-init-output.log

Check node configuration

    oo-accept-node

Look for the output: **PASS**

##**6.3 Connect to OpenShift Console**
Confirm Console Access by opening a browser and putting in the IP address of the broker.

http://172.16.1.BROKER_IP/console

username: demo
password: changeme

**Lab 6 Complete!**

<!--BREAK-->


