#**Lab 22: Creating a quick start**


**Server used:**

* localhost
* node host

**Tools used:**

* rhc
* git
* Github

A common task that you will be asked to do is make a software developers development environment easily deployable on OpenShift Enterprise.  Development teams desire a quick and repeatable way to spin up an environment with their application code already deployed and integrated with various data stores.  In the previous lab, we saw how easy it was to install applications via our quick start process.  During this lab, we will focus on the ability for you to create your own quick starts using the popular open source project Piwik as an example.

##**Download the Piwik source code**

At the time of this writing, you can obtain the code directly from the Piwik website at: http://piwik.org/latest.zip.  Once downloaded, save the file to *~/code/piwikstage*.

After you have downloaded the source code, extract the contents of the zip archive with the following commands:

	$ cd ~
	$ mkdir code
	$ cd code
	$ mkdir piwikstage
	$ cd piwikstage
	$ unzip latest.zip
    
This will create a piwik directory under the ~/code/piwikstage directory.  

##**Create an OpenShift Enterprise application**

We need to create an OpenShift Enterprise application to hold the source code as well as embed the MySQL database:
   
	$ cd ~/code
	$ rhc app create piwik php-5.3
	$ rhc cartridge add -a piwik -c mysql-5.1
    
OpenShift Enterprise, as you know, creates a default *index* file for your application.  Because we are going to be using the source code from our Piwik applicaiton, we need to remove the existing template.

	$ rm -rf ~/code/piwik/php/*
	
At this point, we need to copy over the source code that we extracted from the zip archive to our *piwik* OpenShift Enterprise application:

	$ cp –av ~/code/piwikstage/piwik/* ~/code/piwik/php
	
Now we need to add and commit our changes to our *piwik* application:

 	$ cd ~/code/piwik/php
 	$ git add .
 	$ git commit –am “Initial commit for Piwik”
 	$ git push
    
Assuming everything went as expected, you should be able to verify Piwik is running by opening up your web browser and pointing to the following URL:

	http://piwik-ose.apps.example.com
	
![](http://training.runcloudrun.com/images/piwik.png)	    

##**Creating a Github repository**

**Note**: This step assumes that you already have a Github account.  If you don't, head on over to www.github.com and sign up (it's free).
   
Log in to the Github website and create a new repository for our quick start.  The direct link, after you are logged in, to create a new repository is:
	
	https://github.com/repositories/new
		
Enter a project name and a description for your quick start.  I suggest a name that identifies the project as a OpenShift Enterprise quick start.  For example, a good name would be *Piwik-openshift-quickstart*.

![](http://training.runcloudrun.com/images/piwik2.png)

On your newly created project space, grab the HTTP Git URL and add the Github repository as a remote to your existing *piwik* OpenShift Enterprise application.	    	

![](http://training.runcloudrun.com/images/piwik3.png)

	$ cd ~/code/piwik
	$ git remote add github ${github http URL from github}
	
##**Create deployment instructions**

In order for developers to be able to use the quick start that you have created, you need to provide instructions on how to install the application.  These instructions need to be in the *README* and *README.md* files.  By default, Github will display the contents of this file, using the markdown version if it exits, on the repository page.  For example, a proper README file would contain the following contents:

	Piwik on OpenShift
	=========================
	Piwik is a downloadable, open source (GPL licensed) real time web analytics software program. It provides you with detailed reports on your website visitors: the search engines and keywords they used, the language they speak, your popular pages, and so much more.
	
	Piwik aims to be an open source alternative to Google Analytics, and is already used on more than 150,000 websites. 
	
	More information can be found on the official Piwik website at http://piwik.org
	
		Running on OpenShift
		--------------------
		
		Create an account at http://openshift.redhat.com/
		
		Create a PHP application
		
			rhc app create -a piwik -t php-5.3 -l $USERNAME
		
		Add mysql support to your application
		    
			rhc cartridge add -a piwik -c mysql -l $USERNAME
		Make a note of the username, password, and host name as you will need to use these to complete the Piwik installation on OpenShift
		
		Add this upstream Piwik quickstart repo
		
			cd piwik/php
			rm -rf *
			git remote add upstream -m master git://github.com/gshipley/piwik-openshift-quickstart.git
			git pull -s recursive -X theirs upstream master
		
		Then push the repo upstream to OpenShift
		
			git push
		
		That's it, you can now checkout your application at:
		
			http://piwik-$yourlogin.rhcloud.com

Create the *README* and *README.md* in the *~/code/piwik* directory and add the contents provided above.  Once you have created these files, add and commit them to your repository:

	$ cd ~/code/piwik
	$ git add .
	$ git commit -am “Add installation instructions”
	
Now we need to push these changes to the Github repository we created:

	$ git push -u github master
	
##**Verify your quick start works**

Delete the *piwik* OpenShift Enterprise application and follow the instructions you created for your Piwik quick start to verify that everything works as expected.  

**Note:**  If your application requires an existing populated database, the way to accomplish this is by using the .openshift/action_hooks/build script located in your application directory.  Once you have your database created locally, do a *mysqldump* on the table and store the .sql file in the action_hooks directory.  You can then modify an existing build file to import the schema on application deployment.  For an example, take a look at the action_hooks directory of the Wordpress quick start.

**Lab 22 Complete!**
<!--BREAK-->
