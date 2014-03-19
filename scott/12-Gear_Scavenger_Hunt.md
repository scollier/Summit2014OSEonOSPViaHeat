#**Lab 12: Gear Scavenger Hunt**

##**Servers Used**

localhost

node

###**Steps**

Choose an app that you have created and find out what public IP address it is
using? (hint: use the <code>host</code> or <code>dig</code> command) 

Using the web console or CLI tools, find out the ssh login string for an
application. (hint: <code>rhc domain show</code>)

Now, <code>ssh</code> into the application.

What is your home directory? (hint: <code>pwd</code>)

Try to list all home directories. (hint: <code>ls</code>)

What private IP addresses is your app using? (hint: <code>env</code>)

How much memory is this app using? (hint: <code>oo-cgroup-read
memory.usage_in_bytes</code>)

Stop your app and check the memory usage (hint: <code>ctl_app
graceful-stop</code>)

Restart your app (hint: <code>ctl_app start</code>)

What is the total memory available for your app? (hint: <code>oo-cgroup-read
memory.limit_in_bytes</code>)


**Lab 12 Complete!**

<!--BREAK-->

