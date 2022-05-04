#!/bin/bash

# Flush all rules
/root/scripts/firewall/firewallFlushScript.sh
echo "Flushed rules... Done."

# Enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Variable declaration
II=enp0s8
IE=enp0s9
ID=enp0s10
EXT=0/0
NETLAN=10.10.10.0/24
DMZLAN=20.20.20.0/24

FWEXTIP=10.11.13.118
FWDMZIP=20.20.20.1
FWLANIP=10.10.10.2

DMZCLIENT=20.20.20.20

# Chain creation
iptables -N ie # -- EXT -> LAN 
iptables -N ei

iptables -N de # -- EXT -> DMZ
iptables -N ed

iptables -N id # -- LAN -> DMZ
iptables -N di

# -- EXT -> LAN 
echo "EXT -> LAN... Done."
iptables -A FORWARD -i $IE -o $II -s $EXT -d $NETLAN -j ei
# -- LAN -> EXT
iptables -A FORWARD -i $II -o $IE -s $NETLAN -d $EXT -j ie

# -- EXT -> DMZ
echo "EXT -> DMZ... Done."
iptables -A FORWARD -i $IE -o $ID -s $EXT -d $DMZLAN -j ed
# -- DMZ -> EXT
iptables -A FORWARD -i $ID -o $IE -s $DMZLAN -d $EXT -j de

# -- LAN -> DMZ
echo "LAN -> DMZ... Done."
iptables -A FORWARD -i $II -o $ID -s $NETLAN -d $DMZLAN -j id
# -- DMZ -> LAN
iptables -A FORWARD -i $ID -o $II -s $DMZLAN -d $NETLAN -j di

# Enabling destination network address translation to expose webserver on port 80
iptables -t nat -A PREROUTING -i $IE -s $EXT -d $FWEXTIP -p tcp --dport 80  -j DNAT --to $DMZCLIENT:80

# Enabling destination network address translation to expose webserver on port 443
iptables -t nat -A PREROUTING -i $IE -s $EXT -d $FWEXTIP -p tcp --dport 443 -j DNAT --to $DMZCLIENT:443

# ---------------------------------------- #

# Define rules for forwarding

# ----------- Internet and DMZ ----------- #
echo "Internet and DMZ... Done."
# Forward HTTPS Server to Internet from LAN
iptables -A ed -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

# Forward HTTP Server to Internet from LAN
iptables -A ed -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
# ----------- ---------------- ----------- #

# ----------- LAN and DMZ ----------- #
echo "LAN and DMZ... Done."
# Forward SSH
iptables -A id -p tcp --dport 22 -s 10.10.10.50 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A di -p tcp --sport 22 -d 10.10.10.50 -m state --state ESTABLISHED -j ACCEPT

# HTTP client
iptables -A id -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A di -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# HTTPS client
iptables -A id -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A di -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
# ----------- ----------- ----------- #


# ----------- Internet and LAN ----------- #
echo "Internet and DMZ... Done."
# Forward SMTP to Internet from LAN
iptables -A ie -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ei -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT

# Forward POP3 to Internet from LAN
iptables -A ie -p tcp --dport 110 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ei -p tcp --sport 110 -m state --state ESTABLISHED -j ACCEPT

# Forward IMAP to Internet from LAN
iptables -A ie -p tcp --dport 143 -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A ei -p tcp --sport 143 -m state --state ESTABLISHED -j ACCEPT

# Forward HTTP to Internet from LAN
iptables -A ie -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ei -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# Forward HTTPS to Internet from LAN
iptables -A ie -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ei -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
# ----------- ---------------- ----------- #


# ----------- Direct communication with FW ----------- #
# aggiungere le interfacce 
echo "Direct communication with FW... Done."
# SSH
iptables -A INPUT  -p tcp --dport 22 -i $II -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -o $II -m state --state ESTABLISHED -j ACCEPT

# DNS client and server to LAN and DMZ
iptables -A OUTPUT -p udp --dport 53 -o $IE -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p udp --sport 53 -i $IE -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A INPUT  -p udp --dport 53 -i $II -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A OUTPUT -p udp --sport 53 -o $II -m state --state NEW,ESTABLISHED -j ACCEPT

iptables -A INPUT  -p udp --dport 53 -i $ID -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A OUTPUT -p udp --sport 53 -o $ID -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTP client
iptables -A OUTPUT -p tcp --dport 80 -o $IE -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p tcp --sport 80 -i $IE -m state --state ESTABLISHED -j ACCEPT

# HTTPS client
iptables -A OUTPUT -p tcp --dport 443 -o $IE -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p tcp --sport 443 -i $IE -m state --state ESTABLISHED -j ACCEPT

# SQUID to DMZLAN only
iptables -A INPUT  -p tcp --dport 3128 -i $ID -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A OUTPUT -p tcp --sport 3128 -o $ID -m state --state ESTABLISHED -j ACCEPT

# ICMP on every interface
iptables -A INPUT  -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

# DHCP to NETLAN only
iptables -A INPUT  -p udp --dport 67 -i $II -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A OUTPUT -p udp --dport 68 -o $II -m state --state NEW,ESTABLISHED -j ACCEPT
# ----------- ---------------------------- ----------- #

# Enabling source network address translation to access internet without proxy
iptables -t nat -A POSTROUTING -o $IE -s $NETLAN -j SNAT --to-source $FWEXTIP

# Block everything else
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

service iptables save