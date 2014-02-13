#**Lab 11: Creating a PHP application**

**Server used:**

* localhost
* node host

**Tools used:**

* rhc

In this lab, we are ready to start using OpenShift Enterprise to create our first application.  To create an application, we will be using the *rhc app* command.  In order to view all of the switches available for the *rhc app* command, enter the following command:

	$ rhc app -h
	
This will provide you with the following output:
	
	List of Actions
	  configure     Configure several properties that apply to an application
	  create        Create an application
	  delete        Delete an application from the server
	  deploy        Deploy a git reference or binary file of an application
	  force-stop    Stops all application processes
	  reload        Reload the application's configuration
	  restart       Restart the application
	  show          Show information about an application
	  start         Start the application
	  stop          Stop the application
	  tidy          Clean out the application's logs and tmp directories and tidy up the git repo on the
	                server


##**Create a new application**

It is very easy to create an OpenShift Enterprise application using *rhc*. The command to create an application is *rhc app create*, and it requires two mandatory arguments:

* **Application Name** : The name of the application. The application name can only contain alpha-numeric characters and at max contain only 32 characters.

* **Type**: The type is used to specify which language runtime to use.  

Create a directory to hold your OpenShift Enterprise code projects:

	$ cd ~
	$ mkdir ose
	$ cd ose
	
To create an application that uses the *php* runtime, issue the following command:

	$ rhc app create firstphp php-5.3
	
After entering that command, you should see the following output:

	Application Options
	-------------------
	  Domain:     gshipley
	  Cartridges: php-5.3
	  Gear Size:  default
	  Scaling:    no
	
	Creating application 'firstphp' ... done
	
	
	Waiting for your DNS name to be available ... done
	
	Cloning into 'firstphp'...
	The authenticity of host 'firstphp-ose.apps.example.com (209.132.178.87)' can't be established.
	RSA key fingerprint is e8:e2:6b:9d:77:e2:ed:a2:94:54:17:72:af:71:28:04.
	Are you sure you want to continue connecting (yes/no)? yes
	Warning: Permanently added 'firstphp-ose.apps.example.com' (RSA) to the list of known hosts.
	Checking connectivity... done
	
	Your application 'firstphp' is now available.
	
	  URL:        http://firstphp-ose.apps.example.com/
	  SSH to:     52afd7043a0fb277cf000036@firstphp-ose.apps.example.com
	  Git remote: ssh://52afd7043a0fb277cf000036@firstphp-ose.apps.example.com/~/git/firstphp.git/
	  Cloned to:  /Users/gshipley/code/ose/firstphp
	
	Run 'rhc show-app firstphp' for more details about your app.

If you completed all of the steps in the DNS setup lab correctly, you should be able to verify that your application was created correctly by opening up a web browser and entering the following URL:

	http://firstphp-ose.apps.example.com
	
You should see the default template that OpenShift Enterprise uses for a new application.

![](http://training.runcloudrun.com/images/firstphp.png)

##**What just happened?**

After you entered the command to create a new PHP application, a lot of things happened under the covers:

* A request was made to the broker application host to create a new php application.
* A message was broadcast using MCollective and ActiveMQ to find a node host to handle the application creation request.
* A node host responded to the request and created an application / gear for you.
* SELinux and cgroup policies were enabled for your application gear.
* A userid was created for your application gear.
* A private Git repository was created for your gear on the node host.
* The Git repository was cloned onto your local machine.
* BIND was updated on the broker host to include an entry for your application.

##**Understanding the directory structure on the node host**
	
It is important to understand the directory structure of each OpenShift Enterprise application gear.  For the PHP application that we just created, we can verify and examine the layout of the gear on the node host.  SSH to your node host and execute the following commands:

	# cd /var/lib/openshift
	# ls
	
You will see output similar to the following:

	e9e92282a16b49e7b78d69822ac53e1d
	
The above is the unique user id that was created for your application gear.  Lets examine the contents of this gear by using the following commands:

	# cd e9e92282a16b49e7b78d69822ac53e1d
	# ls -al
	
You should see the following directories:

	total 44
	drwxr-x---.  9 root e9e92282a16b49e7b78d69822ac53e1d 4096 Jan 21 13:47 .
	drwxr-xr-x.  5 root root                             4096 Jan 21 13:47 ..
	drwxr-xr-x.  4 root e9e92282a16b49e7b78d69822ac53e1d 4096 Jan 21 13:47 app-root
	drwxr-x---.  3 root e9e92282a16b49e7b78d69822ac53e1d 4096 Jan 21 13:47 .env
	drwxr-xr-x.  3 root root                             4096 Jan 21 13:47 git
	-rw-r--r--.  1 root root                               56 Jan 21 13:47 .gitconfig
	-rw-r--r--.  1 root root                             1352 Jan 21 13:47 .pearrc
	drwxr-xr-x. 10 root root                             4096 Jan 21 13:47 php
	d---------.  3 root root                             4096 Jan 21 13:47 .sandbox
	drwxr-x---.  2 root e9e92282a16b49e7b78d69822ac53e1d 4096 Jan 21 13:47 .ssh
	d---------.  3 root root                             4096 Jan 21 13:47 .tmp
	[root@node e9e92282a16b49e7b78d69822ac53e1d]# 


During a previous lab, where we setup the *rhc* tools, our SSH key was uploaded to the server to enable us to authenticate to the system without having to provide a password.  The SSH key we provided was actually appended to the *authorized_keys* file.  To verify this, use the following command to view the contents of the file:

	# cat .ssh/authorized_keys
	
You will also notice the following three directories:

* app-root - Contains your core application code as well as your data directory where persistent data is stored.
* git - Your private Git repository that was created upon gear creation.
* php-5.3 - The core PHP runtime and associated configuration files.  Your application is served from this directory.

Let's close our SSH session and return to your local machine:

	# exit


##**Understanding directory structure on the localhost**

When you created the PHP application using the *rhc app create* command, the private git repository that was created on your node host was cloned to your local machine.

	$ cd firstphp
	$ ls -al
	
You should see the following information:


	total 8
	drwxr-xr-x   9 gshipley  staff   306 Jan 21 13:48 .
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 ..
	drwxr-xr-x  13 gshipley  staff   442 Jan 21 13:48 .git
	drwxr-xr-x   5 gshipley  staff   170 Jan 21 13:48 .openshift
	-rw-r--r--   1 gshipley  staff  2715 Jan 21 13:48 README
	-rw-r--r--   1 gshipley  staff     0 Jan 21 13:48 deplist.txt
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 libs
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 misc
	drwxr-xr-x   4 gshipley  staff   136 Jan 21 13:48 php


###**.git directory**

If you are not familiar with the Git revision control system, this is where information about the git repositories that you will be interacting with is stored.  For instance, to list all of the repositories that you are currently setup to use for this project, issue the following command:

	$ cat .git/config
	
You should see the following information, which specifies the URL for our repository that is hosted on the OpenShift Enterprise node host:

	[core]
		repositoryformatversion = 0
		filemode = true
		bare = false
		logallrefupdates = true
		ignorecase = true
	[remote "origin"]
		fetch = +refs/heads/*:refs/remotes/origin/*
		url = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.apps.example.com/~/git/firstphp.git/
	[branch "master"]
		remote = origin
		merge = refs/heads/master
	[rhc]
		app-uuid = e9e92282a16b49e7b78d69822ac53e1d


**Note:** You are also able to add other remote repositories.  This is useful for developers who also use Github or have private git repositories for an existing code base.

###**.openshift directory**

The .openshift directory is a hidden directory where a user can create action hooks, set markers, and create cron jobs.  

Action hooks are scripts that are executed directly, so they can be written in Python, PHP, Ruby, shell, etc.  OpenShift Enterprise supports the following action hooks:

| Action Hook | Description|
| :---------------  | :------------ |
| build | Executed on your CI system if available.  Otherwise, executed before the deploy step | 
| deploy | Executed after dependencies are resolved but before application has started | 
| post_deploy | Executed after application has been deployed and started| 
| pre_build | Executed on your CI system if available.  Otherwise, executed before the build step | 
[Action Hooks][section-mmd-tables-table1] 

OpenShift Enterprise also supports the ability for a user to schedule jobs to be ran based upon the familiar cron functionality of Linux.  To enable this functionality, you need to add the cron cartridge to your application.  Once you have done so, any scripts or jobs added to the minutely, hourly, daily, weekly or monthly directories will be run on a scheduled basis (frequency is as indicated by the name of the directory) using run-parts.  OpenShift supports the following schedule for cron jobs:

* daily
* hourly
* minutely
* monthly
* weekly

The markers directory will allow the user to specify settings such as enabling hot deployments or which version of Java to use.

###**libs directory**

The libs directory is a location where the developer can provide any dependencies that are not able to be deployed using the standard dependency resolution system for the selected runtime.  In the case of PHP, the standard convention that OpenShift Enterprise uses is providing *PEAR* modules in the deplist.txt file.

###**misc directory**

The misc directory is a location provided to the developer to store any application code that they do not want exposed publicly.

###**php directory**

The php directory is where all of the application code that the developer writes should be created.  By default, two files are created in this directory:

* health_check.php - A simple file to determine if the application is responding to requests
* index.php - The OpenShift template that we saw after application creation in the web browser.

##**Make a change to the PHP application and deploy updated code**

To get a good understanding of the development workflow for a user, let's change the contents of the *index.php* template that is provided on the newly created gear.  Edit the file and look for the following code block:

	<h1>
	    Welcome to OpenShift
	</h1>

Update this code block to the following and then save your changes:

	<h1>
	    Welcome to OpenShift Enterprise
	</h1>

**Note:** Make sure you are updating the \<h1> tag and not the \<title> tag.

Once the code has been changed, we need to commit our change to the local Git repository.  This is accomplished with the *git commit* command:

	$ git commit -am "Changed welcome message."
	
Now that our code has been committed to our local repository, we need to push those changes up to our repository that is located on the node host.  

	$ git push
	
You should see the following output:

	Counting objects: 7, done.
	Delta compression using up to 8 threads.
	Compressing objects: 100% (4/4), done.
	Writing objects: 100% (4/4), 395 bytes, done.
	Total 4 (delta 2), reused 0 (delta 0)
	remote: restart_on_add=false
	remote: httpd: Could not reliably determine the server's fully qualified domain name, using node.example.com for ServerName
	remote: Waiting for stop to finish
	remote: Done
	remote: restart_on_add=false
	remote: ~/git/firstphp.git ~/git/firstphp.git
	remote: ~/git/firstphp.git
	remote: Running .openshift/action_hooks/pre_build
	remote: Running .openshift/action_hooks/build
	remote: Running .openshift/action_hooks/deploy
	remote: hot_deploy_added=false
	remote: httpd: Could not reliably determine the server's fully qualified domain name, using node.example.com for ServerName
	remote: Done
	remote: Running .openshift/action_hooks/post_deploy
	To ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com/~/git/firstphp.git/
	   3edf63b..edc0805  master -> master


Notice that we stop the application runtime (Apache), deploy the code, and then run any action hooks that may have been specified in the .openshift directory.  


##**Verify code change**

If you completed all of the steps in Lab 16 correctly, you should be able to verify that your application was deployed correctly by opening up a web browser and entering the following URL:

	http://firstphp-ose.apps.example.com
	
You should see the updated code for the application.

![](http://training.runcloudrun.com/images/firstphpOSE.png)

##**Adding a new PHP file**

Adding a new source code file to your OpenShift Enterprise application is an easy and straightforward process.  For instance, to create a PHP source code file that displays the server date and time, create a new file located in *php* directory and name it *time.php*.  After creating this file, add the following contents:

	<?php
	// Print the date and time
	echo date('l jS \of F Y h:i:s A');
	?>

Once you have saved this file, the process for pushing the changes involves adding the new file to your git repository, committing the change, and then pushing the code to your OpenShift Enterprise gear:

	$ git add .
	$ git commit -am "Adding time.php"
	$ git push
	
##**Verify code change**

To verify that we have created and deployed the new PHP source file correctly, open up a web browser and enter the following URL:

	http://firstphp-ose.example.com/time.php
	
You should see the updated code for the application.

![](http://training.runcloudrun.com/images/firstphpTime.png)
	
**Lab 11 Complete!**
<!--BREAK-->
