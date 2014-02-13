#**Lab 17: The DIY application type**

**Server used:**

* localhost

**Tools used:**

* rhc
* git

In addition to supporting Ruby, PHP, Perl, Python, and Java EE6, the OpenShift Enterprise environment supports the "Do it Yourself" or "DIY" application type. Using this application type, users can run just about any program that speaks HTTP.

How this works is remarkably straightforward. The OpenShift Enterprise execution environment is a carefully secured Red Hat Enterprise Linux operating system on x86_64 systems. Thus, OpenShift Enterprise can run any binary that will run on RHEL 6.3 x86_64.

The way that the OpenShift Enterprise DIY runtime interfaces your application to the outside world is by creating an HTTP proxy specified by the environment variables *OPENSHIFT_DIY_IP* and *OPENSHIFT_DIY_PORT*.  All your application has to do is bind and listen on that address and port. HTTP requests will come into the OpenShift Enterprise environment, which will proxy those requests to your application. Your application will reply with HTTP responses, and the OpenShift Enterprise environment will relay those responses back to your users.

Your application will be executed by the .openshift/action_hooks/start script, and will be stopped by the .openshift/action_hooks/stop script.

**Note:** DIY applications are unsupported but are a great way for developers to try out unsupported languages, frameworks, or middleware that don't ship as official OpenShift Enterprise cartridges.

##**Creating a DIY application type**

To create an application gear that will use the DIY application type, use the *rhc app create* command:

	$ rhc app create myjavademo diy

After executing this command, you should see the following output:

	Using diy-0.1 (Do-It-Yourself 0.1) for 'diy'

	Application Options
	-------------------
	  Domain:     ose
	  Cartridges: diy-0.1
	  Gear Size:  default
	  Scaling:    no

	Creating application 'myjavademo' ... done

	  Disclaimer: This is an experimental cartridge that provides a way to try unsupported languages, frameworks, and middleware on OpenShift.

	Waiting for your DNS name to be available ... done

	Cloning into 'myjavademo'...
	The authenticity of host 'myjavademo-ose.apps.example.com (209.132.178.87)' can't be established.
	RSA key fingerprint is e8:e2:6b:9d:77:e2:ed:a2:94:54:17:72:af:71:28:04.
	Are you sure you want to continue connecting (yes/no)? yes
	Warning: Permanently added 'myjavademo-ose.apps.example.com' (RSA) to the list of known hosts.
	Checking connectivity... done

	Your application 'myjavademo' is now available.

	  URL:        http://myjavademo-ose.apps.example.com/
	  SSH to:     52b21e0c3a0fb277cf0000c8@myjavademo-ose.apps.example.com
	  Git remote: ssh://52b21e0c3a0fb277cf0000c8@myjavademo-ose.apps.example.com/~/git/myjavademo.git/
	  Cloned to:  /Users/gshipley/code/ose/scaledapp/myjavademo

	Run 'rhc show-app myjavademo' for more details about your app.

Now that we have our application created, we can begin the deployment of our custom runtime.  Let's start by changing to the application directory:

	$ cd myjavademo
	
##**Deploying application code**

Instead of spending time in this lab with writing a server runtime, we are going to use an existing one that is available on the OpenShift Github page.  This application code is written in Java and consists of a single MyHttpServer main class.  Since this source code lives on the Github OpenShift project page, we need to add the remote Github repository and then pull the remote source code while at the same time overwriting the existing source code we have in our DIY application directory.

	$ git remote add upstream git://github.com/openshift/openshift-diy-java-demo.git
	$ git pull -s recursive -X theirs upstream master
	$ git push
	
##**Verify the DIY application is working**

Once the Java example has been pushed to your OpenShift Enterprise gear, open up a web browser and point to the following URL:

	http://myjavademo-ose.apps.example.com/index.html
	
**Note:** Make sure to include the index.html file at the end of the URL.

If the application was deployed correctly, you should see a *Hello DIY World!* message.  This little HTTP Java server will serve any files found in your application's html directory, so you can add files or make changes to them, push the contents, and see those reflected in your browser.

##**Under the covers**

The DIY cartridge provides a number of hooks that are called during the lifecycle actions of the application. The hooks available to you for customization are found in the .openshift/action_hooks directory of your application repository. 

For this application, all that has been customized are the start and stop scripts. They simply launch the MyHttpServer class using Java and perform a *wget* call to have the MyHttpServer stop itself:

	$ cat .openshift/action_hooks/start 
	#!/bin/bash
	# The logic to start up your application should be put in this
	# script. The application will work only if it binds to
	# $OPENSHIFT_INTERNAL_IP:8080
	
	cd $OPENSHIFT_REPO_DIR
	nohup java -cp bin test.MyHttpServer >${OPENSHIFT_DIY_LOG_DIR}/MyHttpServer.log 2>&1 &
	
	$ cat .openshift/action_hooks/stop
	#!/bin/bash
	# The logic to stop your application should be put in this script.
	wget http://${OPENSHIFT_INTERNAL_IP}:${OPENSHIFT_INTERNAL_PORT}?action=stop
	
See the *src/test/MyHttpServer.java* source to understand how the Java application is making use of the OpenShift Enterprise environment variables to interact with the server environment.

Add another source file to your application and verify that it works.  From inside of your *myjavademo* directory, create a new file called *test.html*.

	$ cd html
	$ echo "Hello from DIY on Enterprise" > test.html
	$ git add .
	$ git commit -am "Adding new HTML file"
	$ push

Verify that you can view this file by going to the following URL:

	http://myjavademo-ose.apps.example.com/test.html



**Lab 17 Complete!**
<!--BREAK-->
