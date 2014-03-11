#**Lab 12: Managing an application**

**Server used:**

* localhost
* node host

**Tools used:**

* rhc

## **Start/Stop/Restart OpenShift Enterprise application**

OpenShift Enterprise provides commands to start, stop, and restart an application. If at any point in the future you decide that an application should be stopped for some maintenance, you can stop the application using the *rhc app stop* command. After making necessary maintenance tasks, you can start the application again using the *rhc app start* command. 

To stop an application, execute the following command:

	$ rhc app stop firstphp
	
	RESULT:
	firstphp stopped

Verify that your application has been stopped with the following *curl* command:

	$ curl http://firstphp-ose.apps.example.com/health_check.php
	
	<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
	<html><head>
	<title>503 Service Temporarily Unavailable</title>
	</head><body>
	<h1>Service Temporarily Unavailable</h1>
	<p>The server is temporarily unable to service your
	request due to maintenance downtime or capacity
	problems. Please try again later.</p>
	<hr>
	<address>Apache/2.2.15 (Red Hat) Server at myfirstapp-ose.example.com Port 80</address>
	</body></html>


To start the application back up, execute the following command:

	$ rhc app start firstphp

	RESULT:
	firstphp started

Verify that your application has been started with the following *curl* command:

	$ curl http://firstphp-ose.apps.example.com/health
	
	1
	

You can also stop and start the application in one command as shown below.

	$ rhc app restart firstphp

	RESULT:
	firstphp restarted


##**Viewing application details**

All of the details about an application can be viewed by the *rhc app show* command. This command will list when the application was created, the unique identifier of the application, Git URL, SSH URL, and other details as shown below:


	$ rhc app show firstphp
	Password: ****
	
	
	firstphp @ http://firstphp-ose.apps.example.com/ (uuid: 52afd7bc3a0fb277cf000070)
	---------------------------------------------------------------------------------
	  Domain:     ose
	  Created:    Dec 16  9:49 PM
	  Gears:      1 (defaults to small)
	  Git URL:    ssh://52afd7bc3a0fb277cf000070@firstphp-ose.apps.example.com/~/git/firstphp.git/
	  SSH:        52afd7bc3a0fb277cf000070@firstphp-ose.apps.example.com
	  Deployment: auto (on git push)

	  php-5.3 (PHP 5.3)
	  -----------------
    Gears: 1 small
    


##**Viewing application status**

The state of application gears can be viewed by passing the *state* switch to the *rhc app show* command, as shown below:

	rhc app show --state firstphp
	Password: ****
	
	
	RESULT:
	Cartridge php-5.3 is started


##**Cleaning up an application**

As a user starts developing an application and deploying changes to OpenShift Enterprise, the application will start consuming some of the available disk space that is part of their quota. This space is consumed by the Git repository, log files, temporary files, and unused application libraries. OpenShift Enterprise provides a disk-space cleanup tool to help users manage the application disk space. This command is also available under *rhc app* and performs the following functions:

* Runs the *git gc* command on the application's remote Git repository.
* Clears the application's /tmp and log file directories. These are specified by the application's *OPENSHIFT_LOG_DIR* and *OPENSHIFT_TMP_DIR* environment variables.
* Clears unused application libraries. This means that any library files previously installed by a *git push* command are removed.

To clean up the disk space on your application gear, run the following command:

	$ rhc app tidy firstphp

After running this command you should see the following output:

	RESULT:
	firstphp cleaned up

##**SSH to application gear**

OpenShift allows remote access to the application gear by using the Secure Shell protocol (SSH). [Secure Shell (SSH)](http://en.wikipedia.org/wiki/Secure_Shell) is a network protocol for securely getting access to a remote computer.  SSH uses RSA public key cryptography for both the connection and authentication. SSH provides direct access to the command line of your application gear on the remote server. After you are logged in on the remote server, you can use the command line to directly manage the server, check logs, and test quick changes. OpenShift Enterprise uses SSH for:

* Performing Git operations
* Remote access your application gear

The SSH keys were generated and uploaded to OpenShift Enterprise by rhc setup command we executed in a previous lab. You can verify that SSH keys are uploaded by logging into the OpenShift Enterprise management console and clicking on the "Settings" tab, as shown below.

![](http://training.runcloudrun.com/ose2/sshKeys-webconsole.png)

**Note:** If you don't see an entry under "Public Keys" then you can either upload the SSH key by clicking on "Add a new key" or run the *rhc setup* command again. This will create a SSH key pair in <User.Home>/.ssh folder and upload the public key to the OpenShift Enterprise server.

After the SSH keys are uploaded, you can SSH into the application gear as shown below.  SSH is installed by default on most UNIX-like platforms, such as Mac OSX and Linux.  For Windows, you can use [PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/).  Instructions for installing PuTTY can be found [on the OpenShift website](https://openshift.redhat.com/community/page/install-and-setup-putty-ssh-client-for-windows). 

Although you can SSH in by using the standard ssh command line utility, the OpenShift client tools includes a ssh utility that makes the process of logging in to your application even easier.  To SSH to your gear, execute the following command:

	$ rhc app ssh firstphp


If you want to use the ssh command line utility, execute the following command:


	$ ssh UUID@appname-namespace.apps.example.com

You can get the SSH URL by running *rhc app show* command as shown below:

	$ rhc app show firstphp
	Password: ****
	
	
	firstphp @ http://firstphp-ose.apps.example.com/
	===========================================
	  Application Info
	  ================
	    Created   = 1:47 PM
	    UUID      = e9e92282a16b49e7b78d69822ac53e1d
	    SSH URL   = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.apps.example.com
	    Gear Size = small
	    Git URL   = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.apps.example.com/~/git/firstphp.git/
	  Cartridges
	  ==========
	    php-5.3

Now you can ssh into the application gear using the SSH URL shown above:

	$ ssh e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.apps.example.com
	
	    *********************************************************************
	
	    You are accessing a service that is for use only by authorized users.  
	    If you do not have authorization, discontinue use at once. 
	    Any use of the services is subject to the applicable terms of the 
	    agreement which can be found at: 
	    https://openshift.redhat.com/app/legal
	
	    *********************************************************************
	
	    Welcome to OpenShift shell
	
	    This shell will assist you in managing OpenShift applications.
	
	    !!! IMPORTANT !!! IMPORTANT !!! IMPORTANT !!!
	    Shell access is quite powerful and it is possible for you to
	    accidentally damage your application.  Proceed with care!
	    If worse comes to worst, destroy your application with 'rhc app destroy'
	    and recreate it
	    !!! IMPORTANT !!! IMPORTANT !!! IMPORTANT !!!
	
	    Type "help" for more info.
	


You can also view all of the commands available on the application gear shell by running the help command as shown below:

	[firstphp-ose.apps.example.com ~]\> help
	Help menu: The following commands are available to help control your openshift
	application and environment.
	
	ctl_app         control your application (start, stop, restart, etc)
	ctl_all         control application and deps like mysql in one command
	tail_all        tail all log files
	export          list available environment variables
	rm              remove files / directories
	ls              list files / directories
	ps              list running applications
	kill            kill running applications
	mysql           interactive MySQL shell
	mongo           interactive MongoDB shell
	psql            interactive PostgreSQL shell
	quota           list disk usage
	
##**Viewing log files for an application**

Logs are very important when you want to find out why an error is happening or if you want to check the health of your application. OpenShift Enterprise provides the *rhc tail* command to display the contents of your log files. To view all the options available for the *rhc tail* command, issue the following:

	Usage: rhc tail <application>

	Tail the logs of an application


	Options
	  -n, --namespace NAME      Name of a domain
	  -o, --opts options        Options to pass to the server-side (linux based) tail command (applicable to tail command only) (-f is implicit.  See the linux tail man page full list of options.) (Ex: --opts '-n
	                            100')
	  -f, --files files         File glob relative to app (default <application_name>/logs/*) (optional)
	  -g, --gear ID             Tail only a specific gear
	  -a, --app NAME            Name of an application

	Global Options
	  -l, --rhlogin LOGIN       OpenShift login
	  -p, --password PASSWORD   OpenShift password
	  --token TOKEN             An authorization token for accessing your account.
	  --server NAME             An OpenShift server hostname (default: openshift.redhat.com)
	  --timeout SECONDS         The timeout for operations

	  See 'rhc help options' for a full list of global options.


The rhc tail command requires that you provide the application name of the logs you would like to view.  To view the log files of our *firstphp* application, use the following command:

	$ rhc tail firstphp
	
You should see information for both the access and error logs.  While you have the *rhc tail* command open, issue a HTTP get request by pointing your web browser to *http://firstphp-ose.apps.example.com*.  You should see a new entry in the log files that looks similar to this:

	10.10.56.204 - - [22/Jan/2013:18:39:27 -0500] "GET / HTTP/1.1" 200 5242 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:19.0) Gecko/20100101 Firefox/19.0"

The log files are also available on the gear node host in the *php-5.3/logs* directory.

Now that you know how to view log files by using the *rhc tail* command it is also important to know how to view logs during an SSH session on the gear.  SSH into the gear and use the knowledge you have learned in the lab to tail the logs files on the gear.

##**Viewing disk quota for an application**

In a previous lab, we configured the application gears to have a disk-usage quota.  You can view the quota of your currently running gear by connecting to the gear node host via SSH as discussed previously in this lab.  Once you are connected to your application gear, enter the following command:

	$ quota -s
	
If the quota information that we configured earlier is correct, you should see the following information:

	Disk quotas for user e9e92282a16b49e7b78d69822ac53e1d (uid 1000): 
	     Filesystem  blocks   quota   limit   grace   files   quota   limit   grace
	/dev/mapper/VolGroup-lv_root
	                  22540       0   1024M             338       0   40000        

To view how much disk space your gear is actually using, you can also enter in the following:

	$ du -h

##**Adding a custom domain to an application using the command line**

OpenShift Enterprise supports the use of custom domain names for an application.  For example, suppose we want to use http://www.somesupercooldomain.com for the application *firstphp* that we created in a previous lab. The first thing you need to do before setting up a custom domain name is to buy the domain name from domain registration provider.

After buying the domain name, you have to add a [CNAME record](http://en.wikipedia.org/wiki/CNAME_record) for the custom domain name.  Once you have created the CNAME record, you can let OpenShift Enterprise know about the CNAME by using the *rhc alias* command.

	$ rhc alias add firstphp www.mycustomdomainname.com
	
Technically, what OpenShift Enterprise has done under the hood is set up a Vhost in Apache to handle the custom URL.

##**Adding a custom domain to an application using the management console**

The OpenShift management console now allows you to customize your application's domain host URL without having to use the command line tools.  Point your browser to *broker.hosts.example.com* and authenticate.  After you have authenticated to the management console, click on the *Applications* tab at the top of the screen.

You should see the firstphp application listed:

![](http://training.runcloudrun.com/ose2/domainName.png)

Click on the *change* link next to your application name.  On the following page, you can specify the custom domain name for your application.  Go ahead and add a custom domain name of *www.openshiftrocks.com* and click the save button.

![](http://training.runcloudrun.com/ose2/customDomainName.png)

You should now see the new domain name listed in the console.  You can also verify the alias was added by running the following command at your terminal prompt:

	$ rhc app show firstphp

If the alias was added correctly, you should see the following output:

	firstphp @ http://firstphp-ose.apps.example.com/ (uuid: 52afd7bc3a0fb277cf000070)
	---------------------------------------------------------------------------------
	  Domain:     ose
	  Created:    Dec 16  9:49 PM
	  Gears:      1 (defaults to small)
	  Git URL:    ssh://52afd7bc3a0fb277cf000070@firstphp-ose.apps.example.com/~/git/firstphp.git/
	  SSH:        52afd7bc3a0fb277cf000070@firstphp-ose.apps.example.com
	  Deployment: auto (on git push)
	  Aliases:    www.openshiftrocks.com

	  php-5.3 (PHP 5.3)
	  -----------------
	    Gears: 1 small


If you point your web browser to www.openshiftrocks.com, you will notice that it does not work.  This is because the domain name has not been setup with a DNS registry.  In order to verify that the vhost was added, add an entry in your */etc/hosts* file on your local machine.

	$ sudo vi /etc/hosts

Add the following entry, replacing the IP address with the address of your node host.

	209.132.178.87  www.openshiftrocks.com

Once you have edited and saved the file, open your browser and go to your custom domain name.  You should see the application.

Once you have verified that the vhost was added correctly by viewing the site in your web browser, delete the line from the */etc/hosts* file.

##**Backing up an application**

Use the *rhc snapshot save* command to create backups of your OpenShift Enterprise application. This command creates a gzipped tar file of your application and of any locally-created log and data files.  This snapshot is downloaded to your local machine.  The directory structure that exists on the server is maintained in the downloaded archive.

	$ rhc snapshot save firstphp
	Password: ****
	
	Pulling down a snapshot to firstphp.tar.gz...
	Waiting for stop to finish
	Done
	Creating and sending tar.gz
	Done
	
	RESULT:
	Success

After the command successfully finishes, you will see a file named firstphp.tar.gz in the directory where you executed the command. The default filename for the snapshot is $Application_Name.tar.gz. You can override this path and filename with the -f or --filepath option.

**NOTE**: This command will stop your application for the duration of the backup process.

Now that we have our application snapshot saved, edit the *index.php* file in your firstphp application and change the *Welcome to OpenShift Enterprise* \<h1> tag to say *Welcome to OpenShift Enterprise before restore*.

Once you have made this change, perform the following command to push your changes to your application gear:

	$ git commit -am "Added message"
	$ git push

Verify that changes are reflected in your web browser.

##**Restoring a backup**

Not only you can take a backup of an application, but you can also restore a previously saved snapshot.  This form of the *rhc* command restores the Git repository, as well as the application data directories and the log files found in the specified archive. When the restoration is complete, OpenShift Enterprise runs the deployment script on the newly restored repository.  To restore an application snapshot, run the following command:

	$ rhc snapshot restore firstphp -f firstphp.tar.gz

You will see the following confirmation message:

	Restoring from snapshot firstphp.tar.gz...
	Removing old data dir: ~/app-root/data/*
	Restoring ~/app-root/data

	RESULT:
	Success


**NOTE**: This command will stop your application for the duration of the restore process.

##**Verify application has been restored**

Open up a web browser and point to the following URL:

	http://firstphp-ose.apps.example.com
	
If the restore process worked correctly, you should see the restored application running just as it was before.


##**Deleting an application**

You can delete an OpenShift Enterprise application by executing the *rhc app delete* command. This command deletes your application and all of its data on the OpenShift Enterprise server but leaves your local directory intact. This operation can not be undone, so use it with caution. 

	$ rhc app delete someAppToDelete
	
	Are you sure you wish to delete the ‘someAppToDelete’ application? (yes/no)
	yes 
	
	Deleting application ‘someAppToDelete’
	
	RESULT:
	Application ‘someAppToDelete’ successfully deleted

There is another variant of this command which does not require the user to confirm the delete opeartion.  To use this variant, pass the *--confirm* flag.

	$ rhc app delete --confirm someAppToDelete
	
	Deleting application 'someAppToDelete'
	
	RESULT:
	Application 'someAppToDelete' successfully deleted


##**Viewing a thread dump of an application**

**Note:** The following sections requires a Ruby or JBoss application type.  Since we have not created one yet in this class, read through the material below but don't actually perform the commands at this time.

You can trigger a thread dump for Ruby and JBoss applications using the *rhc threaddump* command. A thread dump is a snapshot of the state of all threads that are part of the runtime process.  If an application appears to have stalled or is running out of resources, a thread dump can help reveal the state of the runtime, identify what might be causing any issues, and ultimately help resolve the problem. To trigger a thread dump, execute the following command:

	$ rhc threaddump ApplicationName
	
After running this command for a JBoss or Ruby application, you will be given a log file that you can view in order to see the details of the thread dump.  Issue the following command, substituting the correct log file:

	$ rhc tail ApplicationName -f ruby-1.9/logs/error_log-20130104-000000-EST -o '-n 250'

**Lab 12 Complete!**
<!--BREAK-->
