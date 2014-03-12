#**Lab 6: Deploy Heat Stack**

##**6.1 Import the Images into Glance**


The names of these images are hard coded in the heat template.  Do not change the name here.

    glance add name=RHEL65-x86_64-broker is_public=true disk_format=qcow2 \
container_format=bare < /home/images/RHEL65-x86_64-broker-v2.qcow2
    
    glance add name=RHEL65-x86_64-node is_public=true disk_format=qcow2 \
container_format=bare < /home/images/RHEL65-x86_64-node-v2.qcow2
    
    glance index
    

##**6.2 Create the openshift-environment file**


**Create the openshift-environment.yaml file:**

Get the private and public network IDs as well as the private subnet ID.  Place those parameters in the following file in the following fields: private_net_id: public_net_id: private_subnet_id: to replace FIXME.







Create the */root/openshift-environment.yaml* file and copy the following contents into it.

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

##**6.3 Launch the stack**

Now run the *heat* command and launch the stack. The -f option tells *heat* where the template file resides.  The -e option points *heat* to the environment file that was created in the previous section.


    heat create openshift -f /usr/share/openshift-heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml \
-e /root/openshift-environment.yaml


##**6.4 Monitor the stack**

List the *heat* stack

    heat stack-list

Watch the heat events.

    heat event-list openshift

    heat resource-list openshift

    nova list

##**6.5 Confirm Connectivity**

Ping the public IP

    ping x.x.x.x 

    ssh -i ~/rootkp.pem ec2-user@x.x.x.x
    ssh -i ~/rootkp.pem ec2-user@x.x.x.x


**FILL OUT THIS**

FILL OUT THIS

**Lab 6 Complete!**

<!--BREAK-->
