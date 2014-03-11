#**Lab 2: Using the OpenShift Enterprise Subscription**

**Servers used:**

* broker host
* node host

**Tools used:**

* SSH
* rhn-channel
* yum
* ssh-keygen
* ssh-copy-id
* sh

##**Verifying Red Hat Network Channels**

In order to be able to update to newer packages, and to download the OpenShift Enterprise software, your system will need to be registered with Red Hat to grant your system access to appropriate software channels.  The machines provided to you in this lab have already been registered with the production Red Hat Network, and the channels you will need have already been added.

Please verify now that your machines have the required channels enabled:

**Note:** Execute the following on both of the hosts that have been provided to you

	# rhn-channel --list
	
You should see the following list of channels:

	jb-ews-2-x86_64-server-6-rpm
	jbappplatform-6-x86_64-server-6-rpm
	rhel-x86_64-server-6
	rhel-x86_64-server-6-ose-2.0-infrastructure
	rhel-x86_64-server-6-ose-2.0-jbosseap
	rhel-x86_64-server-6-ose-2.0-node
	rhel-x86_64-server-6-ose-2.0-rhc
	rhel-x86_64-server-6-rhscl-1

You can also see the list of available channels using Yum:

	# yum repolist
	
You should see the same channels listed.  If you do not see the expected output, ask the instructor for assistance.

Note that if you were registered using Red Hat Subscription Manager, the channels would be named using a different format.
	
**Lab 2 Complete!**

<!--BREAK-->
