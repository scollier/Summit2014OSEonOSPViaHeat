#!/bin/sh -x
  
pdshopts="-f 80"
  
pdshcmd="pdsh -w ^lab-ips ${pdshopts} "
  
pushd /var/www/html/summit2014/
git pull
popd
${pdshcmd}  "rm -f /home/user/Downloads/LAB_MANUAL.html"
${pdshcmd}  "wget http://10.40.142.94/summit2014/scott/summit_labs.html -O /home/user/Downloads/LAB_MANUAL.html"
${pdshcmd}  "chown user:user /home/user/Downloads/LAB_MANUAL.html"
