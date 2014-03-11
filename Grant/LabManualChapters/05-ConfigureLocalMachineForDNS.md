#**Lab 5: Configuring local machine for DNS resolution**

**Server used:**

* local machine

**Tools used:**

* text editor
* networking tools

At this point, we should have a complete OpenShift Enterprise installation working correctly on the lab machines that were provided to you by the instructor.  During the next portion of the training, we will be focussing on administration and usage of the OpenShift Enterprise PaaS.  To make performing these tasks easier, it is suggested that you add the DNS server that we created in a previous lab to be the first nameserver that your local machine uses to resolve hostnames.  The process for this varies depending on the operating system.  This lab manual will cover the configuration for both the Linux and Mac operating systems.  If you are using a Microsoft Windows operating system, consult the instructor for instructions on how to perform this lab.

##**Configuring example.com resolution for Linux**

If you are using Linux, the process for updating your name server is straightforward.  Simply edit the */etc/resolv.conf* configuration file and add the IP address of your broker node as the first entry.  For example, add the following at the top of the file, replacing the 209.x.x.x IP address with the correct address of your broker node.

	nameserver 209.x.x.x
	
Once you have added the above nameserver, you should be able to communicate with your OpenShift Enterprise PaaS by using the server hostname.  To test this out, ping the broker and node hosts from your local machine:

	$ ping broker.hosts.example.com
	$ ping node.hosts.example.com
	
##**Configuring example.com resolution for OS X version 10.6 and below**
	
If you are using OS X, you will notice that the operating has a */etc/resolv.conf* configuration file.  However, the operating system does not respect this file and requires users to edit the DNS servers via the *System Preferences* tool.

Open up the *System Preferences* tool and select the *Network* utility:

![](http://training.runcloudrun.com/images/network.png)

On the bottom left hand corner of the *Network* utility, ensure that the lock button is unlocked to enable user modifications to the DNS configuration.  Once you have unlocked the system for changes, locate the Ethernet device that is providing connectivity for your machine and click the advanced button:

![](http://training.runcloudrun.com/images/network2.png)

Select the DNS tab at the top of the window:

![](http://training.runcloudrun.com/images/network3.png)

**Note:** Make a list of the current DNS servers that you have configured for your operating system.  When you add a new one, OSX removes the existing servers forcing you to add them back.

Click the *+* button to add a new DNS server and enter the 209.x.x.x IP address of your broker host.

![](http://training.runcloudrun.com/images/network4.png)

**Note:** Add your existing nameservers back that you made a note of above.

**Note:** After this training class, remember to remove the DNS server for your broker host.

After you have applied the changes, we can now test that name resolution is working correctly.  To test this out, ping the broker and node hosts from your local machine:

	$ ping broker.hosts.example.com
	$ ping node.hosts.example.com
	
##**Configuring example.com resolution for OS X version 10.7 and above**

With newer versions of OS X, the operating system will remove a DNS server from the resolution system if the server fails to return a proper address and the next server resolves it.  During the OpenShift Enterprise 2.0 installation, the *openshift.sh* installation script does not enable forwarding on the BIND instance, which will result in domain names other than **.example.com* not resolving.  Fortunately we can solve this using the */etc/resolver/* system in place for OS X.

In order to enable this functionality, we need to create the */etc/resolver* directory if it doesn't exist.  Open up a terminal on your OS X machine and enter in the following commands:

	$ sudo mkdir /etc/resolver
	$ sudo vi /etc/resolver/example.com
	
Once the file has been created, edit the contents to include the following:

	domain example.com
	nameserver 209.x.x.x
	
Be sure to replace the *209.x.x.x* IP address with the correct one of your broker host.

After you have applied the changes, we can now test that name resolution is working correctly.  To test this out, ping the broker and node hosts from your local machine:

	$ ping broker.hosts.example.com
	$ ping node.hosts.example.com


**Lab 5 Complete!**
<!--BREAK-->