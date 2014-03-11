#**Lab 8: Managing districts**

**Server used:**

* node host
* broker host

**Tools used:**

* text editor
* oo-admin-ctl-district

Districts define a set of node hosts within which gears can be easily moved to load-balance the resource usage of those nodes. While not required for a basic OpenShift Enterprise installation, districts provide several administrative benefits and their use is recommended.

Districts allow a gear to maintain the same UUID (and related IP addresses, MCS levels, and ports) across any node within the district, so that applications continue to function normally when moved between nodes in the same district. All nodes within a district have the same profile, meaning that all the gears on those nodes are the same size (for example, small or medium). There is a hard limit of 6000 gears per district.

This means, for example, that developers who hard-code environment settings into their applications instead of using environment variables will not experience problems due to gear migrations between nodes. The application continues to function normally because exactly the same environment is reserved for the gear on every node in the district. This saves developers and administrators time and effort. 

##**Enabling districts**

To use districts, the broker's MCollective plugin must be configured to enable districts.  Edit the */etc/openshift/plugins.d/openshift-origin-msg-broker-mcollective.conf* configuration file and confirm the following parameters are set:

**Note: Confirm the following on the broker host.**

	DISTRICTS_ENABLED=true
	NODE_PROFILE_ENABLED=true
	
While you are viewing this file, you may notice the *DISTRICTS_REQUIRE_FOR_APP_CREATE=false* setting.  Enabling this option prevents users from creating a new application if there are no districts defined or if all districts are at max capacity.  

##**Creating and populating districts**

To create a district that will support a gear type of small, we will use the *oo-admin-ctl-district* command.  After defining the district, we can add our node host (node.hosts.example.com) as the only node in that district.  Execute the following commands to create a district named small_district which can only hold *small* gear types:

**Note: Execute the following on the broker host.**

	# oo-admin-ctl-district -c create -n small_district -p small
	
If the command was successful, you should see output similar to the following:

	Successfully created district: 513b50508f9f44aeb90090f19d2fd940
	
	{"name"=>"small_district",
	 "externally_reserved_uids_size"=>0,
	 "active_server_identities_size"=>0,
	 "node_profile"=>"small",
	 "max_uid"=>6999,
	 "creation_time"=>"2013-01-15T17:18:28-05:00",
	 "max_capacity"=>6000,
	 "server_identities"=>{},
	 "uuid"=>"513b50508f9f44aeb90090f19d2fd940",
	 "available_uids"=>"<6000 uids hidden>",
	 "available_capacity"=>6000}

If you are familiar with JSON, you will understand the format of this output.  What actually happened is a new document was created in the MongoDB database that we installed using the *openshift.sh* installation script.  To view this document inside of the database, execute the following command on the broker host:

	# mongo localhost/openshift_broker -u openshift -p mongopass
	
**Note:** The default mongodb username and password can be found in the */etc/openshift/broker.conf* file.

This will drop you into the mongo shell where you can perform commands against the database.  The first thing we need to do is list all of the available collections in the *openshift_broker* database.  To do so, you can issue the following command:
 
	> db.getCollectionNames()
	
You should see the following collections returned:

	[
		"applications",
		"authorizations",
		"cloud_users",
		"districts",
		"domains",
		"locks",
		"system.indexes",
		"system.users",
		"usage",
		"usage_records"
	]	
	
We can now query the *district* collection to verify the creation of our small district:

	> db.districts.find()
	
The output should be:

	{ "_id" : "513b50508f9f44aeb90090f19d2fd940", "name" : "small_district", "externally_reserved_uids_size" : 0, 
	"active_server_identities_size" : 0, "node_profile" : "small", "max_uid" : 6999, "creation_time" : 
	"2013-01-15T17:18:28-05:00", "max_capacity" : 6000, "server_identities" : [ ], "uuid" : 
	"513b50508f9f44aeb90090f19d2fd940", "available_uids" : [ 	1000, .........], , "available_capacity" : 6000 }

**Note:** The *server_identities* array does not contain any data yet.
**Note:** The above output is an abbreviated version.  You will see more information returned from the command.  The order is not set as this is a JSON document.

Exit the mongo shell by using the exit command:

	> exit

Now we can add our node host, node.hosts.example.com, to the *small_district* that we created above:

	# oo-admin-ctl-district -c add-node -n small_district -i node.hosts.example.com
	
You should see the following output:

	Success!
	
	{"available_capacity"=>6000,
	 "creation_time"=>"2013-01-15T17:18:28-05:00",
	 "available_uids"=>"<6000 uids hidden>",
	 "node_profile"=>"small",
	 "uuid"=>"513b50508f9f44aeb90090f19d2fd940",
	 "externally_reserved_uids_size"=>0,
	 "server_identities"=>{"node.hosts.example.com"=>{"active"=>true}},
	 "name"=>"small_district",
	 "max_capacity"=>6000,
	 "max_uid"=>6999,
	 "active_server_identities_size"=>1}
	 
**Note:** If you see an error message indicating that you can't add this node to the district because the node already has applications on it, congratulations -- you worked ahead and have already created an application. To clean this up, you will need to delete both your application and domain that you created.  If you don't know how to do this, ask the instructor.

In order to verify that the information was added to the MongoDB document, enter in the following commands:

	# mongo localhost/openshift_broker -u openshift -p mongopass
	> db.districts.find()

You should see the following information in the *server_identities* array.

	"server_identities" : [ { "name" : "node.hosts.example.com", "active" : true } ]
	
If you continued to add additional nodes to this district, the *server_identities* array would show all the node hosts assigned to the district.

OpenShift Enterprise also provides a command-line tool to display information about a district.  Simply enter the following command to view the JSON information that is stored in the MongoDB database:

	# oo-admin-ctl-district
	
Once you enter the above command, you should a more human readable version of the document:

	{"_id"=>"52afc6ed3a0fb2e386000001",
	 "active_server_identities_size"=>1,
	 "available_capacity"=>6000,
	 "available_uids"=>"<6000 uids hidden>",
	 "created_at"=>2013-12-17 03:37:17 UTC,
	 "gear_size"=>"small",
	 "max_capacity"=>6000,
	 "max_uid"=>6999,
	 "name"=>"small_district",
	 "server_identities"=>[{"name"=>"broker.hosts.example.com", "active"=>true}],
	 "updated_at"=>2013-12-17 03:45:35 UTC,
	 "uuid"=>"52afc6ed3a0fb2e386000001"}

##**Managing district capacity**

Districts and node hosts have a configured capacity for the number of gears allowed. For a node host, the default value configured in */etc/openshift/resource_limits.conf* is: 

* Maximum number of active gears per node : 100	

Use the max_active_gears parameter in the */etc/openshift/resource_limits.conf* file to specify the maximum number of active gears allowed per node. By default, this value is set to 100, but most administrators will need to modify this value over time. Stopped or idled gears do not count toward this limit; a node can have any number of inactive gears, constrained only by storage. However, starting inactive gears after the max_active_gears limit has been reached may exceed the limit, which cannot be prevented or corrected. Reaching the limit exempts the node from future gear placement by the broker.

##**Viewing district capacity statistics**

In order view usage information for your installation, you run use the *oo-stats* command.  Let's view the current state of our district by entering in the following command:

	# oo-stats
	
You should see information similar to the following:

	------------------------
	Profile 'small' summary:
	------------------------
	            District count : 1
	         District capacity : 6,000
	       Dist avail capacity : 6,000
	           Dist avail uids : 6,000
	     Lowest dist usage pct : 0.0
	    Highest dist usage pct : 0.0
	        Avg dist usage pct : 0.0
	               Nodes count : 1
	              Nodes active : 1
	         Gears total count : 0
	        Gears active count : 0
	    Available active gears : 100
	 Effective available gears : 100
	
	Districts:
	          Name Nodes DistAvailCap GearsActv EffAvailGears LoActvUsgPct AvgActvUsgPct
	-------------- ----- ------------ --------- ------------- ------------ -------------
	small_district     1        6,000         0           100          0.0           0.0
	
	
	------------------------
	Summary for all systems:
	------------------------
	 Districts : 1
	     Nodes : 1
	  Profiles : 1

	 
**Lab 8 Complete!**

<!--BREAK-->
