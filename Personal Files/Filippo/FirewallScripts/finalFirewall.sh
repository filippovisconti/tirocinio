#!/bin/bash

#---------- FLUSH FIREWALL ----------#
/root/firewallScripts/flush_firewall.sh

#---------- Enable routing ----------#
echo 1 > /proc/sys/net/ipv4/ip_forward NOT NEEDED FOR NOW

Ibytewise=ens192
Iinternal=ens224
Iexternal=ens160
EXT=0/0
BYTEWISELAN=10.11.12.0/23
DMZLAN=50.50.50.0/24

FWbytewiseIP=10.11.13.121
FWexternalIP=10.222.111.2
FWDMZIP=50.50.50.1
DMZCLIENT=50.50.50.3

# Chain creation
iptables -N bd # -- BYTEWISE -> DMZ 
iptables -N db

iptables -N de # -- DMZ -> EXT
iptables -N ed


#---SETTING POLICIES---#
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Enabling destination network address translation to expose webserver
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 80 -j DNAT --to $DMZCLIENT:80
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 443 -j DNAT --to $DMZCLIENT:443
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 8080 -j DNAT --to $DMZCLIENT:8080
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 8443 -j DNAT --to $DMZCLIENT:8443

iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 139 -j DNAT --to $DMZCLIENT:139
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 445 -j DNAT --to $DMZCLIENT:445

iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 64022 -j DNAT --to $DMZCLIENT:22

iptables -t nat -A PREROUTING -i $Ibytewise -s $EXT -d $FWbytewiseIP -p tcp --dport 64022 -j DNAT --to $DMZCLIENT:22

echo "EXT -> DMZ... Done."
iptables -A FORWARD -i $Iexternal -o $Iinternal -s $EXT -d $DMZLAN -j ed
# -- DMZ -> EXT
iptables -A FORWARD -i $Iinternal -o $Iexternal -s $DMZLAN -d $EXT -j de

echo "BYTEWISE -> DMZ... Done."
iptables -A FORWARD -i $Ibytewise -o $Iinternal -s $BYTEWISELAN -d $DMZLAN -j bd
# -- DMZ -> EXT
iptables -A FORWARD -i $Iinternal -o $Ibytewise -s $DMZLAN -d $BYTEWISELAN -j db

#----------- SSH --------------------#
iptables -A INPUT  -p tcp --dport 65022 -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 65022 -o $Iexternal -m state --state ESTABLISHED     -j ACCEPT

iptables -A INPUT  -p tcp --dport 65022 -i $Ibytewise -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -A OUTPUT -p tcp --sport 65022 -o $Ibytewise -m state --state ESTABLISHED     -j ACCEPT 

#----------- FORWARD FILE -----------#
/root/firewallScripts/firewallForward.sh

#----------- I/0 FILE ---------------#
/root/firewallScripts/firewallIO.sh

iptables -t nat -A POSTROUTING -o $Iexternal  -s $DMZLAN      -j MASQUERADE
iptables -t nat -A POSTROUTING -o $Ibytewise  -s $BYTEWISELAN -j MASQUERADE

service iptables save