#**Lab 6: Deploy Heat Stack**

##**6.1 Deploy Heat Stack**

**Create the openshift-environment.yaml file:**

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

**Launch the stack:**

    heat create openshift -f /usr/share/openshift-heat-templates/openshift-enterprise/heat/neutron/OpenShift-1B1N-neutron.yaml -e /root/openshift-environment.yaml








**FILL OUT THIS**

FILL OUT THIS

**Lab 6 Complete!**

<!--BREAK-->
