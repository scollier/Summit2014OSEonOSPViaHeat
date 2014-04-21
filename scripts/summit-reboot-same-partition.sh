#!/bin/sh -x
  
pdshopts="-f 80"
  
pdshcmd="pdsh -w ^lab-ips ${pdshopts} "
  
${pdshcmd}  "reboot"

