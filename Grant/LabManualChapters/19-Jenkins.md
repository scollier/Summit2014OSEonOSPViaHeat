#**Lab 19:  Using Jenkins continuous integration**

**Server used:**

* localhost
* node host

**Tools used:**

* rhc
* git
* yum

Jenkins (https://wiki.jenkins-ci.org) is a full featured continuous integration (CI) server that can run builds, tests, and other scheduled tasks.  OpenShift Enterprise allows you to integrate Jenkins with your OpenShift Enterprise applications.

With Jenkins, you have access to a full library of plugins (https://wiki.jenkins-ci.org/display/JENKINS/Plugins) and a vibrant, thriving community of users who have discovered a new way to do development.

There are many reasons why you would want to leverage Jenkins as a continuous integration server.  In the context of OpenShift Enterprise, some of the benefits include the following:

* Archived build information.
* No application downtime during the build process.
* Failed builds do not get deployed (leaving the previous working version in place).
* More resources to build your application, as each Jenkins build spins up a new gear for short-lived period of time.

Jenkins includes a feature-rich web user interface that provides the ability to trigger builds, customize builds, manage resources, manage plugins, and many other features. 

##**Verify Jenkins cartridges are installed**

SSH to your node host and verify that you have the Jenkins cartridges installed:

**Note:** Execute the following on the node host

	# rpm -qa |grep jenkins
	
You should see the following four packages installed:

* jenkins-1.509.1-1.el6op.noarch
* openshift-origin-cartridge-jenkins-1.16.1-2.el6op.noarch
* jenkins-plugin-openshift-0.6.25-1.el6op.x86_64
* openshift-origin-cartridge-jenkins-client-1.17.1-2.el6op.noarch

If you do now have the above RPM packages installed on your node host, follow the directions in a previous lab to install the Jenkins packages.  Make sure to clear the cache on the broker host after installing the new packages.

##**Create a Jenkins gear**

In order to use Jenkins on OpenShift Enterprise, you will need to create an application gear that contains the Jenkins application.  This is done using the *rhc app create* command line tool, or you can use the management console to create the application.  The syntax for using the command line tool is as follows:

	$ rhc app create jenkins jenkins
	
You should see the following output from this command:

	Using jenkins-1 (Jenkins Server) for 'jenkins'

	Application Options
	-------------------
	  Domain:     ose
	  Cartridges: jenkins-1
	  Gear Size:  default
	  Scaling:    no

	Creating application 'jenkins' ... done

	  Jenkins created successfully.  Please make note of these credentials:

	   User: admin
	   Password: H8j5TBjglT8x

	Note:  You can change your password at: https://jenkins-ose.apps.example.com/me/configure

	Waiting for your DNS name to be available ... done

	Cloning into 'jenkins'...
	The authenticity of host 'jenkins-ose.apps.example.com (209.132.178.87)' can't be established.
	RSA key fingerprint is e8:e2:6b:9d:77:e2:ed:a2:94:54:17:72:af:71:28:04.
	Are you sure you want to continue connecting (yes/no)? yes
	Warning: Permanently added 'jenkins-ose.apps.example.com' (RSA) to the list of known hosts.
	Checking connectivity... done

	Your application 'jenkins' is now available.

	  URL:        http://jenkins-ose.apps.example.com/
	  SSH to:     52b22a9f3a0fb277cf0001bd@jenkins-ose.apps.example.com
	  Git remote: ssh://52b22a9f3a0fb277cf0001bd@jenkins-ose.apps.example.com/~/git/jenkins.git/
	  Cloned to:  /Users/gshipley/code/oso/jenkins

	Run 'rhc show-app jenkins' for more details about your app.

Make a note of the username and password that were created for you by OpenShift Enterprise.

##**Adding Jenkins support to your application**

Now that we have a Jenkins server setup and running, we can add support to our *todo* application which will allow all future builds to compile on the Jenkins server.  To embed the Jenkins support cartridge in your application, use the following command:

	$ rhc cartridge-add jenkins-client -a todo

The output should be the following:

	Using jenkins-client-1 (Jenkins Client) for 'jenkins-client'
	Adding jenkins-client-1 to application 'todo' ... done

	jenkins-client-1 (Jenkins Client)
	---------------------------------
	  Gears:   Located with jbosseap-6, postgresql-8.4
	  Job URL: https://jenkins-ose.apps.example.com/job/todo-build/

	Associated with job 'todo-build' in Jenkins server.

Verify that the Jenkins client was added to your application by running the following command:

	$ rhc app show todo
	

You should see the following information indicating that Jenkins has been enabled for the *todo* application.

	todo @ http://todo-ose.apps.example.com/ (uuid: 52b228013a0fb277cf000197)
	-------------------------------------------------------------------------
	  Domain:     ose
	  Created:    3:56 PM
	  Gears:      1 (defaults to small)
	  Git URL:    ssh://52b228013a0fb277cf000197@todo-ose.apps.example.com/~/git/todo.git/
	  SSH:        52b228013a0fb277cf000197@todo-ose.apps.example.com
	  Deployment: auto (on git push)

	  jbosseap-6 (JBoss Enterprise Application Platform 6.1.0)
	  --------------------------------------------------------
	    Gears: Located with postgresql-8.4, jenkins-client-1

	  postgresql-8.4 (PostgreSQL 8.4)
	  -------------------------------
	    Gears:          Located with jbosseap-6, jenkins-client-1
	    Connection URL: postgresql://$OPENSHIFT_POSTGRESQL_DB_HOST:$OPENSHIFT_POSTGRESQL_DB_PORT
	    Database Name:  todo
	    Password:       5uyxIvYNd5s6
	    Username:       admindrgdkpd

	  jenkins-client-1 (Jenkins Client)
	  ---------------------------------
	    Gears:   Located with jbosseap-6, postgresql-8.4
	    Job URL: https://jenkins-ose.apps.example.com/job/todo-build/

##**Configuring Jenkins**

Open up a web browser and point to the following URL:

	https://jenkins-ose.apps.example.com/job/todo-build/
	
Authenticate to the Jenkins environment by providing the username and password that were displayed after adding the Jenkins application.

![](http://training.runcloudrun.com/images/jenkins.png)

Once you are authenticated to the Jenkins dashboard, click on the configure link:

![](http://training.runcloudrun.com/images/jenkins2.png)

A few interesting configuration items exist that may come in handy in the future:

**Builder Configuration**: The first interesting configuration is concerned with the builder. The configuration below states that Jenkins should create a builder with a small size gear using the JBoss EAP cartridge and that the Jenkins master will wait for 5 minutes for the slave to come online.

![](http://training.runcloudrun.com/images/jenkins3.png)

**Git Configuration**: The next configuration item of interest is the git SCM URL.  It specifies the URL of the Git repository to use, the branch to use, etc. This section is important if you want to use Jenkins to build a project which exists outside of OpenShift Enterprise.  This would be useful for developers who have an internal repo for their source code that they would prefer to build from.

**Build Configuration**: The last configuration item which is interesting is under the *build section*. Here you can specify a shell script for building the project. For our current builder it does the following:

* Specify if the project should be built using Java 6 or Java 7
* Specify XMX memory configuration for maven and build the maven project. The memory it configures is 396M.
* Deploying the application which includes stopping the application, pushing the content back from Jenkins to the application gear(s), and finally deploying the artifacts.

The source code for the default build script is as follows:

	source /usr/libexec/openshift/cartridges/abstract/info/lib/jenkins_util
	
	jenkins_rsync 4d1b096e414243e9833dad55d774de73@todo-ose.example.com:~/.m2/ ~/.m2/
	
	# Build setup and run user pre_build and build
	. ci_build.sh
	
	if [ -e ${OPENSHIFT_REPO_DIR}.openshift/markers/java7 ];
	then
	  export JAVA_HOME=/etc/alternatives/java_sdk_1.7.0
	else
	    export JAVA_HOME=/etc/alternatives/java_sdk_1.6.0
	fi
	
	export MAVEN_OPTS="$OPENSHIFT_MAVEN_XMX"
	mvn --global-settings $OPENSHIFT_MAVEN_MIRROR --version
	mvn --global-settings $OPENSHIFT_MAVEN_MIRROR clean package -Popenshift -DskipTests
	
	# Deploy new build
	
	# Stop app
	jenkins_stop_app 4d1b096e414243e9833dad55d774de73@todo-ose.example.com
	
	# Push content back to application
	jenkins_sync_jboss 4d1b096e414243e9833dad55d774de73@todo-ose.example.com
	
	# Configure / start app
	$GIT_SSH 4d1b096e414243e9833dad55d774de73@todo-ose.example.com deploy.sh
	
	jenkins_start_app 4d1b096e414243e9833dad55d774de73@todo-ose.example.com
	
	$GIT_SSH 4d1b096e414243e9833dad55d774de73@todo-ose.example.com post_deploy.sh
	      
**Deploying code to Jenkins**

Now that you have the Jenkins client embedded into your *todo* application gear, any future *git push* commands will send the code to the Jenkins server for building.  To test this out, edit the *src/main/webapp/todo.xhtml* source file and change the title of the page.  If you do not have this file, just create a new file instead.  Look for the following code block:

	<h2>Todo List Creation</h2>
	
Change the above code to the following:

	<h2>Todo List Creation using Jenkins</h2>
	
Commit and push your change:

	$ git commit -am "changed h2"
	$ git push
	
After you push your changes to the Jenkins server, you should see the following output:

	Counting objects: 5, done.
	Delta compression using up to 8 threads.
	Compressing objects: 100% (3/3), done.
	Writing objects: 100% (3/3), 282 bytes, done.
	Total 3 (delta 2), reused 0 (delta 0)
	remote: restart_on_add=false
	remote: Executing Jenkins build.
	remote: 
	remote: You can track your build at https://jenkins-ose.apps.example.com/job/todo-build
	remote: 
	remote: Waiting for build to schedule....Done
	remote: Waiting for job to complete.....................................................................Done
	remote: SUCCESS
	remote: New build has been deployed.
	To ssh://4d1b096e414243e9833dad55d774de73@todo-ose.apps.example.com/~/git/todo.git/
	   eb5f9dc..8cee826  master -> master

While the build is happening, open up a new terminal window and run the following command:

	$ rhc domain show
	
You will see a new gear that was created by the Jenkins application.  This new gear is a temporary gear that OpenShift Enterprise creates in order to build your application code.

	  todobldr @ http://todobldr-ose.apps.example.com/
	  ===========================================
	    Application Info
	    ================
	      UUID      = ffee273344bd404e99e59ba070512d0b
	      Git URL   =
	ssh://ffee273344bd404e99e59ba070512d0b@todobldr-ose.apps.example.com/~/git/todobldr.git/
	      SSH URL   = ssh://ffee273344bd404e99e59ba070512d0b@todobldr-ose.apps.example.com
	      Gear Size = small
	      Created   = 2:48 PM
	    Cartridges
	    ==========
	      jbosseap-6.0
	      
If the build fails, or if you just want to see the output of the Maven build process, you can log in to your Jenkins application, click on the build, and then click the link to view the console output.  Log in to your Jenkins application and view the contents of the last build.

![](http://training.runcloudrun.com/images/jenkins4.png)

##**Starting a new build**

One of the great things about integrating your application with the Jenkins CI environment is the ability to start a new build without having to modify and push your source code.  To initiate a new build, log in to the Jenkins dashboard and select the *todo* builder.  Point your browser to:

	https://jenkins-ose.apps.example.com/
	
Once you have been authenticated, click the *todo-build* link:

![](http://training.runcloudrun.com/images/jenkins5.png)

This will place you on the *todo* application builder dashboard.  Click the *Build Now* link on the left hand side of the screen to initiate a new build:

![](http://training.runcloudrun.com/images/jenkins6.png)

After you click the *Build Now* link, a new build will show up under the links on the left hand side of the screen.

![](http://training.runcloudrun.com/images/jenkins7.png)

For more information about the current build, you can click on the build to manage and view details, including the console output, for the build.


**Lab 19 Complete!**
<!--BREAK-->
