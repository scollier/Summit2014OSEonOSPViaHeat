#**Lab 16: Scaling an application**


**Server used:**

* localhost
* node host

**Tools used:**

* rhc
* ssh
* git
* touch
* pwd

Application scaling enables your application to react to changes in HTTP traffic and automatically allocate the necessary resources to handle the current demand. The OpenShift Enterprise infrastructure monitors incoming web traffic and automatically adds additional gears to satisfy the demand your application is receiving.

##**How scaling works**

If you create a non-scaled application, the web cartridge occupies only a single gear and all traffic is sent to that gear. When you create a scaled application, it can consume multiple gears: one for the high-availability proxy (HAProxy) itself, and one or more for your actual application. If you add other cartridges like PostgreSQL or MySQL to your application, they are installed on their own dedicated gears.

The HAProxy cartridge sits between your application and the network and routes web traffic to your web cartridges. When traffic increases, HAProxy notifies the OpenShift Enterprise servers that it needs additional capacity. OpenShift checks that you have a free gear (out of your max number of gears) and then creates another copy of your web cartridge on that new gear. The code in the Git repository is copied to each new gear, but the data directory begins empty. When the new cartridge copy starts, it will invoke your build hooks and then HAProxy will begin routing web requests to it. If you push a code change to your web application, all of the running gears will get that update.

The algorithm for scaling up and scaling down is based on the number of concurrent requests to your application. OpenShift Enterprise allocates 10 connections per gear - if HAProxy sees that you're sustaining 90% of your peak capacity, it adds another gear. If your demand falls to 50% of your peak capacity for several minutes, HAProxy removes that gear. Simple!

Because each cartridge is "share-nothing", if you want to share data between web cartridges, you can use a database cartridge. Each of the gears created during scaling has access to the database and can read and write consistent data. As OpenShift Enterprise grows, we anticipate adding more capabilities like shared storage, scaled databases, and shared caching. 

The OpenShift Enterprise management console shows you how many gears are currently being consumed by your application. We have lots of great things coming for web application scaling, so stay tuned.

##**Create a scaled application**

In order to create a scaled application using the *rhc* command line tools, you need to specify the *-s* switch to the command.  Let's create a scaled PHP application with the following command:

	$ rhc app create scaledapp php-5.3 -s
	
After executing the above command, you should see output that specifies that scaling is enabled:

	Application Options
	-------------------
	  Domain:     ose
	  Cartridges: php-5.3
	  Gear Size:  default
	  Scaling:    yes

	Creating application 'scaledapp' ... done


	Waiting for your DNS name to be available ... done

	Cloning into 'scaledapp'...
	The authenticity of host 'scaledapp-ose.apps.example.com (209.132.178.87)' can't be established.
	RSA key fingerprint is e8:e2:6b:9d:77:e2:ed:a2:94:54:17:72:af:71:28:04.
	Are you sure you want to continue connecting (yes/no)? yes
	Warning: Permanently added 'scaledapp-ose.apps.example.com' (RSA) to the list of known hosts.
	Checking connectivity... done

	Your application 'scaledapp' is now available.

	  URL:        http://scaledapp-ose.apps.example.com/
	  SSH to:     52b209683a0fb2bc1d000030@scaledapp-ose.apps.example.com
	  Git remote: ssh://52b209683a0fb2bc1d000030@scaledapp-ose.apps.example.com/~/git/scaledapp.git/
	  Cloned to:  /Users/gshipley/code/ose/scaledapp

	Run 'rhc show-app scaledapp' for more details about your app.
	
Log in to the management console with your browser and click on the *scaledapp* application.  You will notice while looking at the gear details that it lists the number of gears that your application is currently using.

![](http://training.runcloudrun.com/ose2/scaledApp.png)

##**Setting the scaling strategy**

OpenShift Enterprise allows users the ability to set the minimum and maximum numbers of gears that an application can use to handle increased HTTP traffic.  This scaling strategy is exposed via the management console.  While on the application details screen, click the *Scales 1 - 25* link to change the default scaling rules.

![](http://training.runcloudrun.com/ose2/scaledApp2.png)

Change this setting to scale to 5 nodes and click the save button.  Verify that the change is reflected in the management console by clicking on your application under the *Applications* tab.

![](http://training.runcloudrun.com/ose2/scaledApp3.png)

##**Manual scaling**

There are often times when a developer will want to disable automatic scaling in order to manually control when a new gear is added to an application.  Some examples of when manual scaling may be preferred over automatic scaling could include the following:

* If you are anticipating a certain load on your application and wish to scale it accordingly. 
* You have a fixed set of resources for your application. 

OpenShift Enterprise supports this workflow by allowing users to manually add and remove gears for an application.  The instructions below describe how to disable the automatic scaling feature. It is assumed you have already created your scaled application as detailed in this lab and are at the root level directory for the application.

From your locally cloned Git repository, create a *disable autoscaling* marker, as shown in the example below:
	
	$ touch .openshift/markers/disable_auto_scaling
	$ git add .
	$ git commit -am “remove automatic scaling”
	$ git push
	
To add a new gear to your application, SSH to your application gear with the following command, replacing the contents with the correct information for your application.  Alternatively, you can use the *rhc app ssh* command.

	$ ssh [AppUUID]@[AppName]-[DomainName].example.com

Once you have have been authenticated to your application gear, you can add a new gear with the following command:

	 $ add-gear -a [AppName] -u [AppUUID] -n [DomainName]
	 
In this lab, the application name is *scaledapp*, the application UUID is the username that you used to SSH to the node host, and the domain name is *ose*.  Given that information, your command should looking similar to the following:

	[scaledapp-ose.example.com ~]\> add-gear -a scaledapp -u 1a6d471841d84e8aaf25222c4cdac278 -n ose
	
Verify that your new gear was added to the application by running the *rhc app show* command or by looking at the application details on the management console:

	$ rhc app show scaledapp
	
After executing this command, you should see the application is now using two gears.

	scaledapp @ http://scaledapp-ose.apps.example.com/ (uuid: 52b209683a0fb2bc1d000030)
	-----------------------------------------------------------------------------------
	  Domain:     ose
	  Created:    1:45 PM
	  Gears:      2 (defaults to small)
	  Git URL:    ssh://52b209683a0fb2bc1d000030@scaledapp-ose.apps.example.com/~/git/scaledapp.git/
	  SSH:        52b209683a0fb2bc1d000030@scaledapp-ose.apps.example.com
	  Deployment: auto (on git push)

	  php-5.3 (PHP 5.3)
	  -----------------
	    Scaling: x2 (minimum: 1, maximum: 5) on small gears

	  haproxy-1.4 (Web Load Balancer)
	  -------------------------------
	    Gears: Located with php-5.3
	  
![](http://training.runcloudrun.com/ose2/scaledApp4.png)

Just as we scaled up with the *add-gear* command, we can manually scale down with the *remove-gear* command.  Remove the second gear from your application with the following command, making sure to substitute the correct application UUID:

	[scaledapp-ose.example.com ~]\> remove-gear -a scaledapp -u 1a6d471841d84e8aaf25222c4cdac278 -n ose
	
After removing the gear with the *remove-gear* command, verify that the application only contains one gear, HAProxy and a single runtime gear:

	$  rhc app show scaledapp
	
	scaledapp @ http://scaledapp-ose.apps.example.com/ (uuid: 52b209683a0fb2bc1d000030)
	-----------------------------------------------------------------------------------
	  Domain:     ose
	  Created:    1:45 PM
	  Gears:      1 (defaults to small)
	  Git URL:    ssh://52b209683a0fb2bc1d000030@scaledapp-ose.apps.example.com/~/git/scaledapp.git/
	  SSH:        52b209683a0fb2bc1d000030@scaledapp-ose.apps.example.com
	  Deployment: auto (on git push)

	  php-5.3 (PHP 5.3)
	  -----------------
	    Scaling: x1 (minimum: 1, maximum: 5) on small gears

	  haproxy-1.4 (Web Load Balancer)
	  -------------------------------
	    Gears: Located with php-5.3

##**Viewing HAProxy information**

OpenShift Enterprise provides a dashboard that will give users relevant information about the status of the HAProxy gear that is balancing and managing load between the application gears.  This dashboard provides visibility into metrics such as process id, uptime, system limits, current connections, and running tasks.  To view the HAProxy dashboard, open your web browser and enter the following URL:

	http://scaledapp-ose.apps.example.com/haproxy-status/
	
![](http://training.runcloudrun.com/ose2/scaledApp5.png)


**Lab 16 Complete!**
<!--BREAK-->
