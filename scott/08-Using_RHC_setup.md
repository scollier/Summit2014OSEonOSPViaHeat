#**Lab 8: Using *rhc setup***

**Server used:**

* localhost

**Tools used:**

* rhc

##**Configure DNS**

The broker instance is running a Bind DNS server to serve dynamic DNS for OpenShift. Add the broker's public IP to the system's */etc/resolv.conf*. First determine the Broker's IP.

Collect the Broker's IP from *nova list*

    nova list

Once the IP is determined add it to */etc/resolv.conf*:

    sudo vim /etc/resolv.conf

Add it as the first nameserver

    nameserver 172.16.1.BROKER_IP

Test hostname resolution

    host broker.summit2014.lab

##**Configuring RHC setup**

By default, the RHC command line tool will default to use the publicly hosted OpenShift environment.  Since we are using our own enterprise environment, we need to tell *rhc* to use our broker.summit2014.lab server instead of openshift.com.  In order to accomplish this, the first thing we need to do is run the *rhc setup* command using the optional *--server* parameter.

	rhc setup --server broker.summit2014.lab
	
Once you enter in that command, you will be prompted for the username that you would like to authenticate with.  For this training class, use the *demo* user account.  

The first thing that you will be prompted with will look like the following:

	The server's certificate is self-signed, which means that a secure connection can't be established to
	'broker.summit2014.lab'.
	
	You may bypass this check, but any data you send to the server could be intercepted by others.
	Connect without checking the certificate? (yes|no):
	
Since we are using a self signed certificate, go ahead and select *yes* here and press the enter key. 

At this point, you will be prompted for the username.  Enter in **demo** and specify the password **changeme**.

After authenticating, OpenShift Enterprise will prompt if you want to create a authentication token for your system.  This will allow you to execute command on the PaaS as a developer without having to authenticate.  It is suggested that you generate a token to speed up the other labs in this training class.

The next step in the setup process is to create and upload our SSH key to the broker server.  This is required for pushing your source code, via Git, up to the OpenShift Enterprise server.

Finally, you will be asked to create a namespace for the provided user account.  The namespace is a unique name which becomes part of your application URL. It is also commonly referred to as the user's domain. The namespace can be at most 16 characters long and can only contain alphanumeric characters. There is currently a 1:1 relationship between usernames and namespaces.  For this lab, create the following namespace:

	ose

##**Under the covers**

The *rhc setup* tool is a convenient command line utility to ensure that the user's operating system is configured properly to create and manage applications from the command line.  After this command has been executed, a *.openshift* directory will have been created in the user's home directory with some basic configuration items specified in the *express.conf* file.  

    cat ~/.openshift/express.conf

The contents of that file are as follows:

    # Default user login
    default_rhlogin=‘demo’

	# Server API
	libra_server = 'broker.summit2014.lab'
	
This information will be read by the *rhc* command line tool for every future command that is issued.  If you want to run commands as a different user than the one listed above, you can either change the default login in this file or provide the *-l* switch to the *rhc* command.


**Lab 8 Complete!**

<!--BREAK-->

