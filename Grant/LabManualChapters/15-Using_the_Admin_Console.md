#**Lab 15: Using the admin console**


**Server used:**

* localhost

**Tools used:**

* OpenShift Enterprise Admin Console

OpenShift Enterprise 2.0 includes the first version of an Admin Console that will allow an Admistrator to gain valuable insights into the usage of the platform.  Having this visibility will allow the adminstrator to perform capacity planning as well as view metrics of the platform as a whole.  

**Note:** The current iteration of the Admin Console is set to read-only.

##**Enable external access to the admin console**

The default location for the admin console is at the following URL:

    http://brokers.hosts.example.com/admin-console

However, by default the admin console is restricted so that it will not allow external traffic.  In order to enable access to the admin console, you will need to create an SSH tunnel to the broker host.

##**System Overview**

Open your favorite web browser and go to the following URL:

    http://broker.hosts.example.com/admin-console
    
Once you enter the above URL, you will the admin console *System Overview* dashboard.

![](http://training.runcloudrun.com/ose2/adminconsole1.png)

On this page you can see the information for the number of disticts and nodes that you have deployed in your environment for each available gear type.  In our lab, you will only see a single district with small gears.  However, in a production deployment of OpenShift Enterprise 2.0, the administrator will be able to view information for all available gear types.

For reference, a production environment may look look like the following image:

![](http://training.runcloudrun.com/ose2/adminconsole2.png)

##**Viewing Gear Profiles**

Click on a gear profile's *Details* link from the System Overview page to view more information about it. Each gear profile page provides the same summary for the respective gear profile as seen on the System Overview page and allows you to toggle between viewing the relevant districts or nodes. The DISTRICTS view shows all of the districts in that gear profile, and by default sorts by the fewest total gears remaining, or the most full districts. Each district displays a progress bar of the total gears and a link to view the nodes for that district.

The DISTRICTS view also displays a threshold indicator. The threshold is a configurable value for the target number of active gears available on a node. Each node for the district appears as either over (displayed in red) or under (displayed in green) the threshold. Each bar is slightly opaque to allow for multiple bars of the same type to show through. Therefore, if there is an intense red or green color, then several nodes are either over or under the threshold.

At any point in time you can refresh the statistics collected by clicking the refresh button in the upper right hand corner of the detail page.

##**Viewing Suggestions**

The admin console also provides a suggestion system that will make reccomendations on the current deployment.  In order to view any suggestions click on the *Suggestions* tab at the top of the screen.  During this training lab, our install if a fairly basic deployment with a minimal number of applications created and deployed on the platform.  Because of this, you may not see any suggestions offered from the console.

Any suggestions will also be displayed on the *System Overview* page on the right hand side of the screen.

##**Searching for Application Entities**

The upper right section of every page of the Administration Console contains a search box, providing a quick way to find OpenShift Enterprise entities. Additionally, the dedicated Search page provides more information on the expected search queries for the different entities, such as Applications, Users, Gears, and Nodes.

The search does not intend to provide a list of possible matches; it is a quick access method that attempts to directly match the search query. Applications, User, Gear, and Node pages link to each other where possible. For example, a User page links to all of the user's applications, and vice versa.

Let's use the search feature to find the *firstphp* application that we created in a previous lab.  In the upper right hand corner of the admin console, select application from the dropbox box and then enter in *firstphp* in the search field.

![](http://training.runcloudrun.com/ose2/adminconsole3.png)

After clicking the search button, you will the details for the application displayed in the main browser window as shown below:

![](http://training.runcloudrun.com/ose2/adminconsole4.png)

On this application detail page, you can view all of the information about the application including the URL, any aliases assigned to the application, the Linux user id that was created for the gear, the domain, which node the gear resides on, and any cartridges that application is using.  You can drill down even further by clicking on any of the link presented on the application detail page.

##**Searching for User Entities**

In the previous section, we searched for our application that we created as part of this training class.  We can also use the search funtionality to view detailed information for a user of the platform.  Using the skills you learned in the previous section, search for the *demo* user.

You should see a detail screen listing the applications the user has deployed.

![](http://training.runcloudrun.com/ose2/adminconsole5.png)

##**Using Data with External Tools**

The Administration Console exposes OpenShift Enterprise 2.0 system data for use by external tools. In the current iteration of the Administration Console, you can retrieve the raw data from some of the application controllers in JSON format. This is not a long-term API however, and is likely to change in future releases. You can access the following URLs by appending them to the appropriate host name:

**Exposed Data Points***

* /admin-console/capacity/profiles.json returns all profile summaries from the Admin Stats library (the same library used by the oo-stats command). Add the ?reload=1 parameter to ensure the data is current rather than cached.

* /admin-console/stats/gears_per_user.json returns frequency data for gears owned by a user.
* /admin-console/stats/apps_per_domain.json returns frequency data for applications belonging to a domain.

* /admin-console/stats/domains_per_user.json returns frequency data for domains owned by a user.

To verify this, you can enter in the following URL in your web browser:

    http://broker.hosts.example.com/admin-console/capacity/profiles.json

You should see output similar to the following:

![](http://training.runcloudrun.com/ose2/adminconsole6.png)

Having these data points avaiable in a consumable JSON fashion will allow administrators to use external tools to monitor the OpenShift Enterprise 2.0 environment.

**Lab 15 Complete!**
<!--BREAK-->
