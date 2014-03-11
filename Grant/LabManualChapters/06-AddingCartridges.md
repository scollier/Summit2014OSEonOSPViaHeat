
#**Lab 6: Adding cartridges**

**Server used:**

* node host
* broker host

**Tools used:**

* yum
* bundle

By default, OpenShift Enterprise caches certain values for faster retrieval. Clearing this cache allows the retrieval of updated settings.

For example, the first time MCollective retrieves the list of cartridges available on your nodes, the list is cached so that subsequent requests for this information are processed more quickly. If you install a new cartridge, it is unavailable to users until the cache is cleared and MCollective retrieves a new list of cartridges. 

This lab will focus on installing cartridges to allow OpenShift Enterprise to create JBoss gears.

##**Listing available cartridges for your subscription**

For a complete list of all cartridges that you are entitled to install,  you can perform a search using the *yum* command that will output all OpenShift Enterprise cartridges.

**Note:  Run the following command on the node host.**

	# yum search origin-cartridge

During this lab, you should see the following cartridges available to install:

openshift-origin-cartridge-cron.noarch : Embedded cron support for OpenShift
openshift-origin-cartridge-diy.noarch : DIY cartridge
openshift-origin-cartridge-haproxy.noarch : Provides HA Proxy
openshift-origin-cartridge-jbosseap.noarch : Provides JBossEAP6.0 support
openshift-origin-cartridge-jbossews.noarch : Provides JBossEWS2.0 support
openshift-origin-cartridge-jenkins.noarch : Provides jenkins-1.x support
openshift-origin-cartridge-jenkins-client.noarch : Embedded jenkins client support for OpenShift
openshift-origin-cartridge-mysql.noarch : Provides embedded mysql support
openshift-origin-cartridge-nodejs.noarch : Provides Node.js support
openshift-origin-cartridge-perl.noarch : Perl cartridge
openshift-origin-cartridge-php.noarch : Php cartridge
openshift-origin-cartridge-postgresql.noarch : Provides embedded PostgreSQL support
openshift-origin-cartridge-python.noarch : Python cartridge
openshift-origin-cartridge-ruby.noarch : Ruby cartridge

##**Installing JBoss support**

In order to enable consumers of the PaaS to create JBoss gears, we will need to install all of the necessary cartridges for the application server and supporting build systems.  Perform the following command to install the required cartridges:

**Note:  Execute the following on the node host.**

	# yum install openshift-origin-cartridge-jbosseap openshift-origin-cartridge-jbossews openshift-origin-cartridge-postgresql
	
The above command will allow users to create JBoss EAP and JBoss EWS gears.  We also installed support for the Jenkins continuous integration environment which we will cover in a later lab.  At the time of this writing, the above command will download and install an additional 285 packages on your node host.

**Note:** Depending on your connection and speed of your node host, this installation make take several minutes.  

##**Clearing the broker application cache**

At this point, you will notice that if you try to create a JBoss based application via the management console, the application type is not available.  This is because the broker host creates a cache of available cartridges to increase performance.  After adding a new cartridge, you need to clear this cache in order for the new cartridge to be available to users.

Caching is performed in multiple components:

* Each node maintains a database of facts about itself, including a list of installed cartridges.
* Using MCollective, a broker queries a node's facts database for the list of cartridges and caches the node's response.
* Using the broker's REST API, the management console queries the broker for the list of cartridges and caches the broker's response.

The cartridge lists are updated automatically at the following intervals:

* The node's database is refreshed every minute.
* The broker's cache is refreshed every six hours.
* The console's cache is refreshed every five minutes.

In order to clear the cache for both the broker and management console at the same time, enter in the following command:

**Note:** Execute the following on the broker host.

	# oo-admin-broker-cache --clear --console
	
You should see the following confirmation message:

	Clearing broker cache.
	Clearing console cache.
	
It may take several minutes before you see the new cartridges available on the management console as it takes a few minutes for the cache to completely clear.

##**Testing new cartridges**

Given the steps in Lab 5 of this training, you should be able to access the management console from a web browser using your local machine.  Open up your preferred browser and enter the following URL:

	http://broker.hosts.example.com
	
You will be prompted to authenticate and then be presented with an application creation screen.  After the cache has been cleared, and assuming you have added the new cartridges correctly, you should see a screen similar to the following:

![](http://training-onpaas.rhcloud.com/ose2/addCartridgeWebConsole.png)

If you do not see the new cartridges available on the management console, check that the new cartridges are available by viewing the contents of the */usr/libexec/openshift/cartridges* directory:

	# cd /usr/libexec/openshift/cartridges
	# ls
	
##**Installing the PostgreSQL and DIY cartridges**

Using the knowledge that you have gained during in this lab, perform the necessary commands to install both the PostgreSQL and DIY cartridges on your node host.  Verify the success of the installation by ensuring that the DIY application type is available on the management console:

![](http://training.runcloudrun.com/images/console-diy.png)


**Lab 6 Complete!**
<!--BREAK-->
