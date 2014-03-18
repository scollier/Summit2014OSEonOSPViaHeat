#**Lab 11: Using cartridges**

**Server used:**

* localhost
* node host

**Tools used:**

* rhc
* mysql
* tail
* git
* PHP

Cartridges provide the actual functionality necessary to run applications. There are several cartridges available to support different programming languages, databases, monitoring, and management. Cartridges are designed to be extensible so the community can add support for any programming language, database, or any management tool not officially supported by OpenShift Enterprise. Please refer to the official OpenShift Enterprise documentation for how you can [write your own cartridge](https://openshift.redhat.com/community/wiki/introduction-to-cartridge-building).

	https://www.openshift.com/wiki/introduction-to-cartridge-building

##**Viewing available cartridges**

To view all of the available commands for working with cartridges on OpenShift Enterprise, enter the following command:

	$ rhc cartridge -h
	
##**List available cartridges**

To see a list of all available cartridges to users of this OpenShift Enterprise deployment, issue the following command:

	$ rhc cartridge list
	
You should see the following output depending on which cartridges you have installed:

  jbosseap-6       JBoss Enterprise Application Platform 6.1.0 web
  jenkins-1        Jenkins Server                              web
  nodejs-0.10      Node.js 0.10                                web
  perl-5.10        Perl 5.10                                   web
  php-5.3          PHP 5.3                                     web
  python-2.6       Python 2.6                                  web
  python-2.7       Python 2.7                                  web
  ruby-1.8         Ruby 1.8                                    web
  ruby-1.9         Ruby 1.9                                    web
  jbossews-1.0     Tomcat 6 (JBoss EWS 1.0)                    web
  jbossews-2.0     Tomcat 7 (JBoss EWS 2.0)                    web
  diy-0.1          Do-It-Yourself 0.1                          web
  cron-1.4         Cron 1.4                                    addon
  jenkins-client-1 Jenkins Client                              addon
  mysql-5.1        MySQL 5.1                                   addon
  postgresql-8.4   PostgreSQL 8.4                              addon
  postgresql-9.2   PostgreSQL 9.2                              addon
  haproxy-1.4      Web Load Balancer                           addon

  Note: Web cartridges can only be added to new applications.
	

##**Add the MySQL cartridge**

In order to use a cartridge, we need to embed it into our existing application.  OpenShift Enterprise provides support for version 5.1 of this popular open source database.  To enable MySQL support for the *firstphp* application, issue the following command:

	$ rhc cartridge-add mysql-5.1 -a firstphp
	
	You should see the following output:

	Adding mysql-5.1 to application 'firstphp' ... done

	mysql-5.1 (MySQL 5.1)
	---------------------
	  Gears:          Located with php-5.3
	  Connection URL: mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
	  Database Name:  firstphp
	  Password:       9svQXLVtv89Y
	  Username:       adminxzGaLVm

	MySQL 5.1 database added.  Please make note of these credentials:

	       Root User: adminxzGaLVm
	   Root Password: 9svQXLVtv89Y
	   Database Name: firstphp

	Connection URL: mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
	
##**Using MySQL**

Developers will typically interact with MySQL by using the mysql shell command
on OpenShift Enterprise.  In order to use the mysql shell, you will need to use
ssh to login to your application gear.  

$ rhc ssh firstphp

	[firstphp-ose.example.com ~]\> mysql
	
You will notice that you did not have to authenticate to the MySQL database.  This is because OpenShift Enterprise sets environment variables that contains the connection information for the database. 

When embedding the MySQL database, OpenShift Enterprise creates a default database based upon the application name.  That being said, the user has full permissions to create new databases inside of MySQL.  Let's use the default database that was created for us and create a *users* table:

	mysql> use firstphp;
	Database changed
	
	mysql> create table users (user_id int not null auto_increment, username varchar(200), PRIMARY KEY(user_id));
	Query OK, 0 rows affected (0.01 sec)

	mysql> insert into users values (null, 'gshipley@redhat.com');
	Query OK, 1 row affected (0.00 sec)
	
Verify that the user record has been added by selecting all rows from the *users* table:

	mysql> select * from users;
	+---------+---------------------+
	| user_id | username            |
	+---------+---------------------+
	|       1 | gshipley@redhat.com |
	+---------+---------------------+
	1 row in set (0.00 sec)
	
To exit out of the MySQL session, simply enter the *exit* command:

	mysql> exit
	
##**MySQL environment variables**

As mentioned earlier in this lab, OpenShift Enterprise creates environment variables that contain the connection information for your MySQL database.  If a user forgets their connection information, they can always retrieve the authentication information by viewing these environment variables:

**Note:  Execute the following on the application gear**

	[firstphp-ose.example.com ~]\> env |grep MYSQL
	
You should see the following information return from the command:

	OPENSHIFT_MYSQL_DIR=/var/lib/openshift/52afd7bc3a0fb277cf000070/mysql/
	OPENSHIFT_MYSQL_DB_PORT=3306
	OPENSHIFT_MYSQL_DB_HOST=127.10.134.130
	OPENSHIFT_MYSQL_DB_PASSWORD=9svQXLVtv89Y
	OPENSHIFT_MYSQL_IDENT=redhat:mysql:5.1:0.2.6
	OPENSHIFT_MYSQL_DB_USERNAME=adminxzGaLVm
	OPENSHIFT_MYSQL_DB_SOCKET=/var/lib/openshift/52afd7bc3a0fb277cf000070/mysql//socket/mysql.sock
	OPENSHIFT_MYSQL_DB_URL=mysql://adminxzGaLVm:9svQXLVtv89Y@127.10.134.130:3306/
	OPENSHIFT_MYSQL_DB_LOG_DIR=/var/lib/openshift/52afd7bc3a0fb277cf000070/mysql//log/
	
To view a list of all *OPENSHIFT* environment variables, you can use the following command:

	[firstphp-ose.example.com ~]\> env | grep OPENSHIFT

##**Viewing MySQL logs**

Given the above information, you can see that the log file directory for MySQL is specified with the *OPENSHIFT_MYSQL_DB_LOG_DIR* environment variable.  To view these log files, simply use the tail command:

	[firstphp-ose.example.com ~]\> tail -f $OPENSHIFT_MYSQL_DB_LOG_DIR/*
	
##**Connecting to the MySQL cartridge from PHP**

Now that we have verified that our MySQL database has been created correctly, and have created a database table with some user information, let's connect to the database from PHP in order to verify that our application code can communicate to the newly embedded MySQL cartridge.  Create a new file in the *php* directory of your *firstphp* application named *dbtest.php*.  Add the following source code to the *dbtest.php* file:


	<?php
	$dbhost = getenv("OPENSHIFT_MYSQL_DB_HOST");
	$dbport = getenv("OPENSHIFT_MYSQL_DB_PORT");
	$dbuser = getenv("OPENSHIFT_MYSQL_DB_USERNAME");
	$dbpwd = getenv("OPENSHIFT_MYSQL_DB_PASSWORD");
	$dbname = getenv("OPENSHIFT_APP_NAME");
	
	$connection = mysql_connect($dbhost, $dbuser, $dbpwd);
	
	if (!$connection) {
	        echo "Could not connect to database";
	} else {
	        echo "Connected to database.<br>";
	}
	
	$dbconnection = mysql_select_db($dbname);
	
	$query = "SELECT * from users";
	
	$rs = mysql_query($query);
	while ($row = mysql_fetch_assoc($rs)) {
	    echo $row['user_id'] . " " . $row['username'] . "\n";
	}
	
	mysql_close();
	
	?>

Once you have created the source file, add the file to your git repository, commit the change, and push the change to your OpenShift Enterprise gear.

	$ git add .
	$ git commit -am “Adding dbtest.php”
	$ git push
	
After the code has been deployed to your application gear, open up a web browser and enter the following URL:

	http://firstphp-ose.apps.example.com/dbtest.php
	
You should see a screen with the following information:

	Connected to database.
	1 gshipley@redhat.com 
	
	
##**Managing cartridges**

OpenShift Enterprise provides the ability to embed multiple cartridges in an application.  For instance, even though we are using MySQL for our *firstphp* application, we could also embed the cron cartridge as well.  It may be useful to stop, restart, or even check the status of a cartridge.  To check the status of our MySQL database, use the following command:

	$ rhc cartridge-status mysql -a firstphp
	
To stop the cartridge, enter the following command:

	$ rhc cartridge-stop mysql -a firstphp
	
Verify that the MySQL database has been stopped by either checking the status again or viewing the following URL in your browser:

	http://firstphp-ose.example.com/dbtest.php
	
You should see the following message returned to your browser:

	Could not connect to database
	
Start the database back up using the *cartridge-start* command.
	
	$ rhc cartridge-start mysql -a firstphp
	

Verify that the database has been restarted by opening up a web browser and entering in the following URL:

	http://firstphp-ose.apps.example.com/dbtest.php
	
You should see a screen with the following information:

	Connected to database.
	1 gshipley@redhat.com 
	
OpenShift Enterprise also provides the ability to list important information about a cartridge by using the *cartridge-show* command.  For example, if a user has forgotten their MySQL connection information, they can display this information with the following command:

	$ rhc cartridge-show mysql -a firstphp
	
The user will then be presented with the following output:

	Password: ****

	mysql-5.1 (MySQL 5.1)
	---------------------
	  Gears:          Located with php-5.3
	  Connection URL: mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
	  Database Name:  firstphp
	  Password:       9svQXLVtv89Y
	  Username:       adminxzGaLVm
	    
##**Using port forwarding**

At this point, you may have noticed that the database cartridge is only accessible via a 127.x.x.x private address.  This ensures that only the application gear can communicate with the database.

With OpenShift Enterprise port-forwarding, developers can connect to remote services with local client tools.  This allows the developer to focus on code without having to worry about the details of configuring complicated firewall rules or SSH tunnels. To connect to the MySQL database running on our OpenShift Enterprise gear, you have to first forward all the ports to your local machine. This can be done using the *rhc port-forward* command.  This command is a wrapper that configures SSH port forwarding. Once the command is executed, you should see a list of services that are being forwarded and the associated IP address and port to use for connections as shown below:

	$ rhc port-forward firstphp
 
	To connect to a service running on OpenShift, use the Local address

	Service Local               OpenShift
	------- -------------- ---- -------------------
	httpd   127.0.0.1:8080  =>  127.10.134.129:8080
	mysql   127.0.0.1:3307  =>  127.10.134.130:3306

	Press CTRL-C to terminate port forwarding

In the above snippet, you can see that mysql database, which we added to the *firstphp* gear, is forwarded to our local machine. If you open http://127.0.0.1:8080 in your browser, you will see the application.

**Note:** At the time of this writing, there is an extra step to enable port forwarding on Mac OS X based systems.  You will need to create an alias on your loopback device for the IP address listed in output shown above.  

	sudo ifconfig lo0 alias 127.0.0.1

Now that you have your services forward, you can connect to them using local client tools. To connect to the MySQL database running on the OpenShift Enterprise gear, run the *mysql* command as shown below:

	$ mysql -uadmin -p -h 127.0.0.1
	
**Note:** The above command assumes that you have the MySQL client installed locally.

##**Enable *hot_deploy***

If you are familiar with PHP, you will probably be wondering why we stop and start Apache on each code deployment.  Fortunately, we provide a way for developers to signal to OpenShift Enterprise that they do not want to restart the application runtime for each deployment.  This is accomplished by creating a hot_deploy marker in the correct directory.  Change to your application root directory, for example ~/code/ose/firstphp, and issue the following commands:

	$ touch .openshift/markers/hot_deploy
	$ git add .
	$ git commit -am “Adding hot_deploy marker”
	$ git push
	
Pay attention to the output:

	Counting objects: 7, done.
	Delta compression using up to 8 threads.
	Compressing objects: 100% (4/4), done.
	Writing objects: 100% (4/4), 403 bytes, done.
	Total 4 (delta 2), reused 0 (delta 0)
	remote: restart_on_add=false
	remote: Will add new hot deploy marker
	remote: App will not be stopped due to presence of hot_deploy marker
	remote: restart_on_add=false
	remote: ~/git/firstphp.git ~/git/firstphp.git
	remote: ~/git/firstphp.git
	remote: Running .openshift/action_hooks/pre_build
	remote: Running .openshift/action_hooks/build
	remote: Running .openshift/action_hooks/deploy
	remote: hot_deploy_added=false
	remote: App will not be started due to presence of hot_deploy marker
	remote: Running .openshift/action_hooks/post_deploy
	To ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.apps.example.com/~/git/firstphp.git/
	   4fbda99..fdbd056  master -> master


The two lines of importance are:

	remote: Will add new hot deploy marker
	remote: App will not be stopped due to presence of hot_deploy marker

Adding a hot_deploy marker will significantly increase the speed of application deployments while developing an application.



**Lab 11 Complete!**
<!--BREAK-->

