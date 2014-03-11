#**Lab 18:  Developing Java EE applications using JBoss EAP**

**Server used:**

* localhost

**Tools used:**

* rhc
* git
* curl

OpenShift Enterprise provides the JBoss EAP runtime to facilitate the development and deployment of Java EE 6 applications.

JBoss Enterprise Application Platform 6 (JBoss EAP 6) is a fully compliant Java EE 6 platform which includes a subscription model with long-term support, platform certification, service packs, and SLA(s).  In this lab we will build a simple todo application using Java EE 6 deployed on the JBoss EAP platform. The application will have a single entity called Todo and will persist todos to PostgreSQL using JPA. The application will also use EJB 3.1 Stateless session beans, Context and Dependency Injection (or CDI), and JAX RS for exposing RESTful web services.

##**Create a JBoss EAP application**

In order to create a JBoss EAP appication runtime, enter in the following command:

	$ rhc app create todo jbosseap
	
Just as we saw in previous labs, a template has been deployed for you at the following URL:

	http://todo-ose.apps.example.com

You should see the following output:

	Using jbosseap-6 (JBoss Enterprise Application Platform 6.1.0) for 'jbosseap'

	Application Options
	-------------------
	  Domain:     ose
	  Cartridges: jbosseap-6
	  Gear Size:  default
	  Scaling:    no

	Creating application 'todo' ... done


	Waiting for your DNS name to be available ... done

	Cloning into 'todo'...
	The authenticity of host 'todo-ose.apps.example.com (209.132.178.87)' can't be established.
	RSA key fingerprint is e8:e2:6b:9d:77:e2:ed:a2:94:54:17:72:af:71:28:04.
	Are you sure you want to continue connecting (yes/no)? yes
	Warning: Permanently added 'todo-ose.apps.example.com' (RSA) to the list of known hosts.
	Checking connectivity... done

	Your application 'todo' is now available.

	  URL:        http://todo-ose.apps.example.com/
	  SSH to:     52b220d23a0fb277cf0000e9@todo-ose.apps.example.com
	  Git remote: ssh://52b220d23a0fb277cf0000e9@todo-ose.apps.example.com/~/git/todo.git/
	  Cloned to:  /Users/gshipley/code/ose/scaledapp/myjavademo/src/test/todo

	Run 'rhc show-app todo' for more details about your app.
	
Verify that the application has been deployed and the template is displaying correctly in your web browser.

	http://todo-ose.apps.example.com

![](http://training.runcloudrun.com/ose2/eap1.png)

##**Additional marker files for JBoss EAP**

If you recall from a previous lab, we discussed the way that OpenShift Enterprise allows the developer to control and manage some of the runtime features using marker files.  For Java-based deployments, there are additional marker files that a developer needs to be aware of:

 * enable_jpda - Will enable the JPDA socket-based transport on the JVM running the JBoss EAP application server. This enables you to remotely debug code running inside of the JBoss application server.

   * skip\_maven_build - Maven build step will be skipped.
   * force\_clean_build - Will start the build process by removing all nonessential Maven dependencies.  Any current dependencies specified in your pom.xml file will then be re-downloaded.
   * hot_deploy - Will prevent a JBoss container restart during build/deployment.  Newly built archives will be re-deployed automatically by the JBoss HDScanner component.
   * java7 - Will run JBoss EAP with Java7 if present. If no marker is present then the baseline Java version will be used (currently Java6)

##**Deployment directory**

If you list the contents of the application repository that was cloned to your local machine, you will notice a deployments directory.  This directory is a location where a developer can place binary archive files, .ear files for example, for deployment.  If you want to deploy a .war file rather than pushing source code, copy the .war file to deployments directory, add the .war file to your git repository, commit the change, and then push the content to your OpenShift Enterprise server.

##**Maven**

OpenShift Enterprise uses the Maven build system for all Java projects.  Once you add new source code following the standard Maven directory structure, OpenShift Enterprise will recognize the existing *pom.xml* in your application's root directory in order to build the code remotely.  

The most important thing specified in the *pom.xml* file is a Maven profile named *openshift*. This is the profile which is invoked when you do deploy the code to OpenShift Enterprise.

##**Embed PostgreSQL cartridge**

The *todo* sample application that we are going to write as part of this lab will make use of the PostgreSQL 8.4 database.  Using the information that you have learned from previous labs, add the PostgreSQL 8.4 cartridge to the *todo* application.

##**Building the *todo* application**

At this point, we should have an application named *todo* created as well as having PostgreSQL embedded in the application to use as our datastore.  Now we can begin working on the application.

###**Creating Domain Model**

**Note:** The source code for this application is available on Github at the following URL:

	https://github.com/gshipley/todo-javaee6
	
If you want the easy way out, use the information you have learned from a previous lab to add the above repository as a remote repository and then pull in the source code while overwriting the existing template.  Then skip ahead to the section on deploying the application.

The first thing that we have to do is to create the domain model for the *todo application*. The application will have a single entity named *Todo* as shown below. The entity shown below is a simple JPA entity with JPA and bean validation annotations.  Create a source file named *Todo.java* in the *todo/src/main/java/com/todo/domain* directory with the following contents:

	package com.todo.domain;

	import java.util.Date;
	import java.util.List;
	
	import javax.persistence.CollectionTable;
	import javax.persistence.Column;
	import javax.persistence.ElementCollection;
	import javax.persistence.Entity;
	import javax.persistence.FetchType;
	import javax.persistence.GeneratedValue;
	import javax.persistence.GenerationType;
	import javax.persistence.Id;
	import javax.persistence.JoinColumn;
	import javax.validation.constraints.NotNull;
	import javax.validation.constraints.Size;
	
	@Entity
	public class Todo {
	
		@Id
		@GeneratedValue(strategy = GenerationType.AUTO)
		private Long id;
	
		@NotNull
		@Size(min = 10, max = 40)
		private String todo;
		
		@ElementCollection(fetch=FetchType.EAGER)
		@CollectionTable(name = "Tags", joinColumns = @JoinColumn(name = "todo_id"))
		@Column(name = "tag")
		@NotNull
		private List<String> tags;
	
		@NotNull
		private Date createdOn = new Date();
	
		public Todo(String todo) {
			this.todo = todo;
		}
	
		public Todo() {
		}
	
		public Long getId() {
			return id;
		}
	
		public void setId(Long id) {
			this.id = id;
		}
	
		public String getTodo() {
			return todo;
		}
	
		public void setTodo(String todo) {
			this.todo = todo;
		}
	
		public Date getCreatedOn() {
			return createdOn;
		}
	
		public void setCreatedOn(Date createdOn) {
			this.createdOn = createdOn;
		}
		
		
		public void setTags(List<String> tags) {
			this.tags = tags;
		}
		
		public List<String> getTags() {
			return tags;
		}
	
		@Override
		public String toString() {
			return "Todo [id=" + id + ", todo=" + todo + ", tags=" + tags
					+ ", createdOn=" + createdOn + "]";
		}
	
	}
	
###**Create the *persistence.xml* file**

The persistence.xml file is a standard configuration file in JPA that defines your data source.  It has to be included in the *META-INF* directory inside of the JAR file that contains the entity beans. The persistence.xml file must define a persistence-unit with a unique name. Create a *META-INF* directory under src/main/resources and then create the *persistence.xml* file with the contents below:

	<?xml version="1.0" encoding="UTF-8" ?>
	<persistence xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	        xsi:schemaLocation="http://java.sun.com/xml/ns/persistence http://java.sun.com/xml/ns/persistence/persistence_2_0.xsd"
	        version="2.0" xmlns="http://java.sun.com/xml/ns/persistence">
	
	        <persistence-unit name="todos" transaction-type="JTA">
	                <provider>org.hibernate.ejb.HibernatePersistence</provider>
	                <jta-data-source>java:jboss/datasources/PostgreSQLDS</jta-data-source>
	                <class>com.todo.domain.Todo</class>
	                <properties>
	                        <property name="hibernate.show_sql" value="true" />
	                        <property name="hibernate.hbm2ddl.auto" value="create" />
	                </properties>
	
	        </persistence-unit>
	</persistence>

The *jta-data-source* refers to JNDI name preconfigured by OpenShift Enterprise in the standalone.xml file located in the *.openshift/config* directory.

###**Create the TodoService EJB bean**

Next we will create a stateless EJB bean named *TodoService* in the *com.todo.service package*.  This bean will perform basic CRUD operations using *javax.persistence.EntityManager*.  Create a file named *TodoService* in the *src/main/java/com/todo/service* directory and add the following contents:

	package com.todo.service;
	
	import java.util.List;
	import javax.ejb.Stateless;
	import javax.persistence.EntityManager;
	import javax.persistence.PersistenceContext;
	import com.todo.domain.Todo;
	
	@Stateless
	public class TodoService {
	
	        @PersistenceContext
	        private EntityManager entityManager;
	
	
	        public Todo create(Todo todo) {
	                entityManager.persist(todo);
	                return todo;
	        }
	
	        public Todo find(Long id) {
	                Todo todo = entityManager.find(Todo.class, id);
	                List<String> tags = todo.getTags();
	                System.out.println("Tags : " + tags);
	                return todo;
	        }
	}
	
###**Enable CDI**

CDI, or Context and Dependency Injection, is a Java EE 6 specification which enables dependency injection in a Java EE 6 project. To enable CDI in the *todo* project, create a *beans.xml* file in *src/main/webapp/WEB-INF* directory with the following contents:

	<?xml version="1.0"?>
	<beans xmlns="http://java.sun.com/xml/ns/javaee"
	 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://jboss.org/schema/cdi/beans_1_0.xsd"/>

In order to use the *@Inject* annotation instead of the *@Ejb* annotation to inject an EJB, you will have to write a producer which will expose the *EntityManager*.  Create a source file in the *src/main/java/com/todo/utils* directory named *Resources* and add the following source code:

	package com.todo.utils;
	
	import javax.enterprise.inject.Produces;
	import javax.persistence.EntityManager;
	import javax.persistence.PersistenceContext;
	
	public class Resources {
	
	    @Produces
	    @PersistenceContext
	    private EntityManager em;
	
	}

###**Creating a RESTful web service**

Before exposing a RESTful web service for the *Todo* entity, we need to enable JAX-RS in our application. To enable JAX-RS, create a class which extends *javax.ws.rs.core.Application* and specify the application path using a *javax.ws.rs.ApplicationPath* annotation.  Create a source file named *JaxRsActivator* in the *src/main/java/com/todo/rest* directory and add the following source code:

	package com.todo.rest;
	
	import javax.ws.rs.ApplicationPath;
	import javax.ws.rs.core.Application;
	
	@ApplicationPath("/rest")
	public class JaxRsActivator extends Application {
	   /* class body intentionally left blank */
	}


Next we will create a *TodoRestService* class which will expose two methods that will create and read a *Todo* object. The service will consume and produce JSON.  Create a source file named *TodoRestService* in the *src/main/java/com/todo/rest* directory and add the following source code:

	package com.todo.rest;
	
	import javax.inject.Inject;
	import javax.ws.rs.Consumes;
	import javax.ws.rs.GET;
	import javax.ws.rs.POST;
	import javax.ws.rs.Path;
	import javax.ws.rs.PathParam;
	import javax.ws.rs.Produces;
	import javax.ws.rs.WebApplicationException;
	import javax.ws.rs.core.MediaType;
	import javax.ws.rs.core.Response;
	import javax.ws.rs.core.UriBuilder;
	import com.todo.domain.Todo;
	import com.todo.service.TodoService;
	
	@Path("/todos")
	public class TodoRestService {
	
		@Inject
		private TodoService todoService;
	
		@POST
		@Consumes("application/json")
		public Response create(Todo entity) {
			todoService.create(entity);
			return Response.created(
					UriBuilder.fromResource(TodoRestService.class)
							.path(String.valueOf(entity.getId())).build()).build();
		}
	
		@GET
		@Path("/{id:[0-9][0-9]*}")
		@Produces(MediaType.APPLICATION_JSON)
		public Todo lookupTodoById(@PathParam("id") long id) {
			Todo todo = todoService.find(id);
			if (todo == null) {
				throw new WebApplicationException(Response.Status.NOT_FOUND);
			}
			return todo;
		}
	}
	
##**Deploy the *todo* application to OpenShift Enterprise**

Now that we have our application created, we need to push our changes to the OpenShift Enterprise gear that we created earlier in this lab.  From the application root directory, issue the following commands:

	$ git add .
	$ git commit -am "Adding source code"
	$ git push
	
Once you execute the *git push* command, the application will begin building on the OpenShift Enterprise node host.  During this training class, the OpenStack virtual machines we have created are not production-grade environments.  Because of this, the build process will take some time to complete.  Sit back, be patient, and help your fellow classmates who may be having problems.

##**Testing the *todo* application**

In order to test out the RESTful web service that we created in this lab, we can add and retrieve todo items using the *curl* command line utility.  To add a new item, enter the following command:

	$ curl -k -i -X POST -H "Content-Type: application/json" -d '{"todo":"Sell a lot of OpenShift Enterprise","tags":["javascript","ui"]}' https://todo-ose.apps.example.com/rest/todos
	
To list all available todo items, run the following command:

	$ curl -k -i -H "Accept: application/json" https://todo-ose.apps.example.com/rest/todos/1
	
You should see the following output:

	HTTP/1.1 200 OK
	Date: Fri, 25 Jan 2013 04:05:51 GMT
	Server: Apache-Coyote/1.1
	Content-Type: application/json
	Connection: close
	Transfer-Encoding: chunked
	
	{"id":1,"todo":"Sell a lot of OpenShift Enterprise","tags":["javascript","ui"],"createdOn":1359086546955}
	
If you downloaded and deployed the source code from the Git repository, the project contains a JSF UI component which will allow you to test the application using your web browser.  Simply point your browser to

	http://todo-ose.apps.example.com
	
to verify that the application was deployed correctly.

![](http://training.runcloudrun.com/ose2/todoApp.png)


##**Extra Credit**

SSH into the application gear and verify the todo item was added to the PostgreSQL database.


**Lab 18 Complete!**
<!--BREAK-->
