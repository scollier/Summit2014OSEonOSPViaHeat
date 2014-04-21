#!/bin/sh -x
  
pdshopts="-f 80"
  
pdshcmd="pdsh -w ^lab-ips ${pdshopts} "
  
    #clean up /etc/rc.d/rc.local
    ${pdshcmd}  "sed -i -e '/ip/ d' /etc/rc.d/rc.local"
  
    #Create lab manual desktop shortcut
    ${pdshcmd}  "mkdir -p /home/user/Desktop"
    ${pdshcmd}  "mkdir -p /home/user/Pictures"
    ${pdshcmd}  "wget http://10.40.142.94/images/scollier.jpg -O /home/user/Pictures/scollier.jpg"
    ${pdshcmd}  "wget http://10.40.142.94/summit2014/scott/summit_labs.html -O /home/user/Desktop/summit_labs.html"
    ${pdshcmd}  "chown user:user /home/user/Pictures/scollier.jpg"
    ${pdshcmd}  "chown user:user /home/user/Desktop/summit_labs.html"
    ${pdshcmd}  "cat << EOF > /home/user/Desktop/LAB_MANUAL.Desktop
#!/usr/bin/env xdg-open
  
[Desktop Entry]
Version=1.0
Type=Link
Icon[en_US]=gnome-panel-launcher
Name[en_US]=LAB_MANUAL
URL=http://10.40.142.94/summit2014/scott/summit_labs.html
Name=LAB_MANUAL
Icon=/home/user/Pictures/scollier.jpg
EOF"
    ${pdshcmd}  "chown -Rv user.user /home/user/Desktop"
    ${pdshcmd}  "chmod -Rv 776 /home/user/Desktop"
  
    #delete lab1 user
    ${pdshcmd}  "userdel -r lab1"
  
    #change user 
    ${pdshcmd}  "usermod --comment 'Deploying OSE on RHEL OSP via Heat Templates' user"
  
     #change bridge script name
      ${pdshcmd}  "mv /usr/local/bin/convert-to-bridge /usr/local/bin/create-bridge-config"
      ${pdshcmd}  "sed -i -e 's/convert-to-bridge/create-bridge-config/' /etc/sudoers"
  
     #change /home/images/repos context
     ${pdshcmd}  "semanage fcontext -a -t httpd_sys_content_t \"/home/images/repos(/.*)?\""
     ${pdshcmd}  "restorecon -R /home/images"

     ${pdshcmd}  "echo Summit2014 | passwd root --stdin"

     ${pdshcmd} 'ip a show dev em1 | grep '\''inet '\'' | awk '\''{print $2}'\'' | awk -F/ '\''{print $1}'\'' | awk -F. '\''{system ("sed -i -e \"s/summitlab.03/station\""$4"\".partition03.summit2014/\" /etc/sysconfig/network" )}'\''' 
