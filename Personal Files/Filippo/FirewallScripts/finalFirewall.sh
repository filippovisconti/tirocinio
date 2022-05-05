#!/bin/bash

#---------- FLUSH FIREWALL ----------#
/root/firewallScripts/flush_firewall.sh

#---------- Enable routing ----------#
# echo 1 > /proc/sys/net/ipv4/ip_forward NOT NEEDED FOR NOW

Ibytewise=ens192
Iexternal=ens160

#---SETTING POLICIES---#
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#----------- SSH --------------------#
#The following rule verifies if that IP address has tried to connect three times or more within the last 90 seconds. If it hasn’t, then the packet is accepted (this rule would need a default policy of DROP on the input chain).

### OLD SSH PORT
iptables -A INPUT  -p tcp --dport 22 -i $Iexternal -m state --state NEW,ESTABLISHED -m recent ! --rcheck --seconds 300 --hitcount 3 --name ssh --rsource -j ACCEPT
iptables -A INPUT  -p tcp --dport 22 -i $Iexternal -s 93.41.112.9                   -j ACCEPT    
 NON VOLEVO ESSERE BUTTATO FUORI MENTRE FACEVO PROVE LOL
iptables -A OUTPUT -p tcp --sport 22 -o $Iexternal -m state --state ESTABLISHED      -j ACCEPT

iptables -A INPUT  -p tcp --dport 22 -i $Ibytewise -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -A OUTPUT -p tcp --dport 22 -o $Ibytewise -m state --state ESTABLISHED     -j ACCEPT 
### END



iptables -A INPUT  -p tcp --dport 65022 -i $Iexternal -m state --state NEW,ESTABLISHED -m recent ! --rcheck --seconds 300 --hitcount 3 --name ssh --rsource -j ACCEPT
iptables -A INPUT  -p tcp --dport 65022 -i $Iexternal -s 93.41.112.9                   -j ACCEPT    
# NON VOLEVO ESSERE BUTTATO FUORI MENTRE FACEVO PROVE LOL
iptables -A OUTPUT -p tcp --sport 65022 -o $Iexternal -m state --state ESTABLISHED      -j ACCEPT

iptables -A INPUT  -p tcp --dport 65022 -i $Ibytewise -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -A OUTPUT -p tcp --dport 65022 -o $Ibytewise -m state --state ESTABLISHED     -j ACCEPT 

#----------- FORWARD FILE -----------#

/root/firewallScripts/firewallForward.sh

#----------- I/0 FILE ---------------#

/root/firewallScripts/firewallIO.sh


service iptables save