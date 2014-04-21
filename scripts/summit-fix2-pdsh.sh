#!/bin/sh -x
  
pdshopts="-f 80"
  
pdshcmd="pdsh -w ^lab-ips ${pdshopts} "
  
    ${pdshcmd}  "rm -f /home/user/Desktop/summit_labs.html"
    ${pdshcmd}  "mkdir -p /home/user/Downloads"
    ${pdshcmd}  "wget http://10.40.142.94/summit2014/scott/summit_labs.html -O /home/user/Downloads/LAB_MANUAL.html"
    ${pdshcmd}  "rm -f /home/user/Desktop/LAB_MANUAL.Desktop"
    ${pdshcmd}  "cat << EOF > /home/user/Desktop/LAB_MANUAL.Desktop
#!/usr/bin/env xdg-open
  
[Desktop Entry]
Version=1.0
Type=Link
Icon[en_US]=gnome-panel-launcher
Name[en_US]=LAB_MANUAL
URL=file:///home/user/Downloads/LAB_MANUAL.html
Name=LAB_MANUAL
Icon=/home/user/Pictures/scollier.jpg
EOF"
    ${pdshcmd}  "chown user:user /home/user/Downloads/LAB_MANUAL.html"
    ${pdshcmd}  "chown user:user /home/user/Desktop/LAB_MANUAL.Desktop"


    ${pdshcmd}  "sed -i -e 's/^HWADDR=/#HWADDR/' /etc/sysconfig/network-scripts/ifcfg-em1"

    ${pdshcmd}  "semanage fcontext -a -t httpd_sys_content_t \"/home/images(/.*)?\""
    ${pdshcmd}  "restorecon -R /home/images"

