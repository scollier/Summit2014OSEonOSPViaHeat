#**Lab 20:  Using JBoss Tools**

**Server used:**

* localhost

**Tools used:**

* eclipse

JBoss Tools is an umbrella project for a set of Eclipse plugins that supports JBoss and related technologies; there is support for OpenShift, Hibernate, JBoss AS, Drools, jBPM, JSF, (X)HTML, Seam, Maven, JBoss ESB, JBoss Portal and more.

##**Download and install Eclipse - Kepler**

In this lab, we are going to use the latest version of JBoss Tools.  In order to make use of this version, we will need to use the Kepler version of the popular Eclipse IDE.  Head on over to the eclipse.org website and download the latest version of Eclipse for Java EE developers that is the correct distribution for your operating system.

	http://www.eclipse.org/downloads/

Once you have Eclipse installed, go to the JBoss Tools page located at

	http://www.jboss.org/tools
	
and follow the instructions to install JBoss Tools 4.1 (Kepler).  While you are welcome to install all of the JBoss Tools, we will only be using the JBoss OpenShift Tools for this lab.

##**Create an OpenShift Enterprise application**

Now that we have Eclipse Juno and JBoss Tools 4.0 installed, we can create an OpenShift Enterprise application without having the leave the comfort of our favorite IDE.  Click on the *OpenShift Application* link that is provided on the JBoss Central screen.  If you do not have this link, you can also select *file->new->other->OpenShift Application*.

![](http://training.runcloudrun.com/images/jbosstools1.png)

Once you click on the link to create a new OpenShift Enterprise application, you will be presented with a dialog to authenticate to OpenShift Enterprise.  Now is also a good time to validate the *Server* setting is correctly set to *broker.hosts.example.com*.  If your server does not reflect this, you have not configured your *express.conf* file correctly.  If you are unable to configure your *express.conf* file as specified in this lab, inform the instructor so that he/she may help you.

![](http://training.runcloudrun.com/images/jbosstools2.png)

After clicking *next*, the JBoss Tools plugin will authenticate you to the broker host and present another dialog box to you.  On this dialog box, you have the option of creating a new application, or to use an existing one.  Since we already have a JBoss EAP application deployed, let's select to *Use existing application* and click the *Browse* button.  After clicking the *Browse* button, a REST API call will be made to the broker host to retrieve the existing applications that you already have deployed.  

![](http://training.runcloudrun.com/images/jbosstools3.png)

Highlight the *todo* application and click on the *Details...* button.  This will display all of the necessary information about the application, including any cartridges that may be embedded.

![](http://training.runcloudrun.com/images/jbosstools4.png)

After clicking *Next* to use the existing *todo* application, Eclipse will ask you to create a new project or to use an existing one.  Let's create a new one and set the correct location where we want to store the project files.

![](http://training.runcloudrun.com/images/jbosstools5.png)

Once you click the *Finish* button, the existing application will be cloned to your local project.


##**Managing OpenShift Enterprise application with JBoss Tools**

JBoss Tools provide many features to allow a developer to manage their application from directly inside of the Eclipse IDE.  This includes features such as viewing log files, publishing the application, and port-forwarding.  Click on the servers tab at the bottom on the Eclipse IDE to see your OpenShift Enterprise server.

![](http://training.runcloudrun.com/images/jbosstools6.png)

###**Tailing log files**

After clicking on the *servers* tab, right click on your OpenShift Enterprise server and then select *OpenShift* and finally select *tail files*.

![](http://training.runcloudrun.com/images/jbosstools7.png)

You will now be able to view the log files in the console tab that has been opened for you inside of Eclipse.

###**Viewing environment variables**

After clicking on the *servers* tab, right click on your OpenShift Enterprise server and then select *OpenShift* and finally select *Environment Variables*.  Once you select this option, all of the system environment variables, including database connections, will be displayed in the console window of Eclipse.

###**Using port-forwarding**

After clicking on the *servers* tab, right click on your OpenShift Enterprise server and then select *OpenShift* and finally select *Port forwarding*.  This will open up a new dialog that displays which services and what IP address will be used for the forwarded services.

![](http://training.runcloudrun.com/images/jbosstools8.png)

For the next section of this lab, ensure that you click on *Start Forwarding* so that we will be able to connect to PostgreSQL from our local machine.

###**Adding PostgreSQL as an Eclipse data source**

Download the latest PostgreSQL driver from the following location:

	http://jdbc.postgresql.org/download.html
	
and save it to your local computer.  Once you have the file downloaded, click on the *Data Source Explorer* tab, right click on *Database Connection*, and select *New*.  This will open the following dialog where you will want to select PostgreSQL:

![](http://training.runcloudrun.com/images/db1.png)

Initially, the *Drivers* pull down box will be empty.  In order to add our PostgreSQL driver, click the plug sign next to the drop down, highlight *PostgreSQL JDBC Driver* and then click on *JAR List*.  Click on *Add JAR/Zip* and browse to the location of the JDBC4 driver that you downloaded.

Now that you have added the driver, the dialog box will display the available driver and allow you to specify your connection details.  Enter the following information:

* Database: todo
* URL: jdbc:postgresql://127.0.0.1:5432/todo
* User name: admin	
* Password: The password supplied by OpenShift.  If you forgot this, use the *Environment Variables* utility provided by JBoss Tools.

In order to verify that your port-forwarding and database connection are setup correctly, press the *test connection* button.  If your connection is failing, make sure that you have the correct authorization credentials and that port-fowarding is started via JBoss Tools.

Once you have correctly added the database connection, you should now see the remote database from the OpenShift Enterprise node host available for use in your Eclipse IDE.

![](http://training.runcloudrun.com/images/db2.png)

At this point, you should be able to use any of the database tools provided by Eclipse to communicate with and manage your OpenShift Enterprise PostgreSQL database.

##**Making a code change and deploying the application**

In the project view, expand the source files for the *src/main/webapp* directory and edit the *todo.xhtml* source file.  Change the following line

	<h2>Todo List Creation using Jenkins</h2>
	
to the include JBoss Tools

	<h2>Todo List Creation using Jenkins and JBoss Tools</h2>
	
Once you have made the source code change, save the contents of the file and then use the *Team* functionality by right-clicking on your project.  Commit and push the changes to your OpenShift Enterprise server.  This push will follow the same workflow used previously by initiating a build on your Jenkins server.

![](http://training.runcloudrun.com/images/tools1.png)

After you push your changes, open up your Jenkins dashboard and open the *Console Output* screen to see the build progress.  Once your build has completed, Eclipse will display a dialog box with a summary of the deployment:

![](http://training.runcloudrun.com/images/tools2.png)

Verify that your changes were deployed correctly by opening up a web browser and going to the following URL:

	http://todo-ose.example.com/	
	
![](http://training.runcloudrun.com/images/tools3.png)

**Lab 20 Complete!**
<!--BREAK-->
