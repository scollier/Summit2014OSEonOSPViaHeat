#**Lab 14: Using the management console to create applications**


**Server used:**

* localhost

**Tools used:**

* OpenShift Enterprise Management Console
* git

OpenShift Enterprise provides users with multiple ways to create and manage applications.  The platform provides command line tools, IDE integration, REST APIs, and a web-based management console.  During this lab, we will explore the creation and management of application using the management console.

Having DNS resolution setup on your local machine, as discussed in a previous lab, is crucial in order to complete this lab.

##**Authenticate to the management console**

Open your favorite web browser and go to the following URL:

    http://broker.hosts.example.com
    
Once you enter the above URL, you will be asked to authenticate using basic auth.  For this training class, you can use the demo account that has been provided for you.  

![](http://training.runcloudrun.com/images/consoleAuth.png)

After entering in valid credentials, you will see the OpenShift Enterprise management console dashboard:

![](http://training.runcloudrun.com/ose2/webconsole.png)

##**Creating a new application**

In order to create a new application using the management console, click on the *ADD APPLICATION* button.  You will then be presented with a list of available runtimes that you can choose from.  To follow along with our PHP examples above, let's create a new PHP application and name it *phptwo*.

![](http://training.runcloudrun.com/ose2/php2.png)

After selecting to create a new PHP application, specify the name of your application:


![](http://training.runcloudrun.com/ose2/php2.1.png)

Once you have created the application, you will see a confirmation screen with some important information:

* Git repository URL
* Instructions for making code changes

![](http://training.runcloudrun.com/ose2/php2.2.png)


##**Clone your application repository**

Open up a command prompt and clone your application repository with the instructions provided on the management console.  When executing the *git clone* command, a new directory will be created in your current working directory.  Once you have a local copy of your application, make a small code change to the *index.php* and push your changes to your OpenShift Enterprise gear.

Once you have made a code change, view your application in a web browser to ensure that the code was deployed correctly to your server.

##**Adding a cartridge with the management console**

Click on the *My Applications* tab at the top of the screen and then select the *Phptwo* application by clicking on it.

![](http://training.runcloudrun.com/ose2/php2.3.png)

After clicking on the *Phptwo* application link, you will be presented with the management dashboard for that application.  On this page, you can view the Git repository URL, add a cartridge, or delete the application.  We want to add the MySQL database to our application.  To do this, click on the *Add MySQL 5.1* link.

![](http://training.runcloudrun.com/ose2/php2.4.png)

Once the MySQL database cartridge has been added to your application, the management console will display a confirmation screen which contains the connection information for your database.

![](http://training.runcloudrun.com/ose2/php2.6.png)

If you recall from a previous lab, the connection information is always available via environment variables on your OpenShift Enterprise gear.

##**Verify database connection**

Using information you learned in a previous lab, add a PHP file that tests the connection to the database.  You will need to modify the previously used PHP code block to only display whether the connection was successful as we have not created a schema for this new database instance.

Once you have completed this lab and your application, *phptwo*, is connected to the database, raise your hand to show your instructor.


**Lab 14 Complete!**
<!--BREAK-->
