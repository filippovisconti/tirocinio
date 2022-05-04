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
IV=tun+             #VPN Interface
EXT=0/0
NETLAN=10.10.10.0/24
DMZLAN=20.20.20.0/24
VPNLAN=10.8.0.0/24

#FWEXTIP=192.168.1.194
FWEXTIP=10.11.13.115
FWDMZIP=20.20.20.1
FWLANIP=10.10.10.2
VPNSERVERIP=10.8.0.1

DMZCLIENT=20.20.20.20

# Chain creation
iptables -N ie # -- EXT -> LAN 
iptables -N ei

iptables -N de # -- EXT -> DMZ
iptables -N ed

iptables -N id # -- LAN -> DMZ
iptables -N di



#Allow TUN interface connections to be forwarded through other interfaces
iptables -A FORWARD -i $IV -j ACCEPT
iptables -A FORWARD -i $IV -o enp0s+ -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s+ -o $IV -m state --state RELATED,ESTABLISHED -j ACCEPT

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

# Enabling destination network address translation to expose webserver
#iptables -t nat -A PREROUTING -i $IE -s $EXT -d $FWEXTIP -j DNAT --to $DMZCLIENT
# far passare solo 80 e 443
# ---------------------------------------- #

# Define rules for forwarding

# ----------- Internet and DMZ ----------- #
echo "Internet and DMZ empty."
# ----------- ---------------- ----------- #

# ----------- LAN and DMZ ----------- #
echo "LAN and DMZ... Done."
# Forward SSH
iptables -A id -p tcp --dport 22 -s 10.10.10.50 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A di -p tcp --sport 22 -d 10.10.10.50 -m state --state ESTABLISHED     -j ACCEPT

# HTTP client
iptables -A id -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A di -p tcp --sport 80 -m state --state ESTABLISHED     -j ACCEPT

# HTTPS client
iptables -A id -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A di -p tcp --sport 443 -m state --state ESTABLISHED     -j ACCEPT
# ----------- ----------- ----------- #


# ----------- Internet and LAN ----------- #
echo "Internet and DMZ... Done."
# Forward SMTP to Internet from LAN
iptables -A ie -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ei -p tcp --sport 25 -m state --state ESTABLISHED     -j ACCEPT

# Forward POP3 to Internet from LAN
iptables -A ie -p tcp --dport 110 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ei -p tcp --sport 110 -m state --state ESTABLISHED     -j ACCEPT

# Forward IMAP to Internet from LAN
iptables -A ie -p tcp --dport 143 -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A ei -p tcp --sport 143 -m state --state ESTABLISHED      -j ACCEPT

# Forward HTTP to Internet from LAN
iptables -A ie -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ei -p tcp --sport 80 -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTPS to Internet from LAN
iptables -A ie -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ei -p tcp --sport 443 -m state --state ESTABLISHED     -j ACCEPT
# ----------- ---------------- ----------- #


# ----------- Direct communication with FW ----------- #
echo "Direct communication with FW... Done."
# SSH
iptables -A INPUT  -p tcp --dport 22 -i $II -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -o $II -m state --state ESTABLISHED     -j ACCEPT

iptables -A INPUT  -p tcp --dport 22 -i enp0s3 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -o enp0s3 -m state --state ESTABLISHED     -j ACCEPT

# DNS client and server to LAN and DMZ
## DNS client - firewall to ext
iptables -A OUTPUT -p udp --dport 53  -o $IE -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p udp --sport 53  -i $IE -m state --state NEW,ESTABLISHED -j ACCEPT

## DNS server - lan to FW
iptables -A INPUT  -p udp --dport 53  -i $II -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp --sport 53  -o $II -m state --state NEW,ESTABLISHED -j ACCEPT

## DNS server - DMZ to FW
iptables -A INPUT  -p udp --dport 53  -i $ID -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp --sport 53  -o $ID -m state --state NEW,ESTABLISHED -j ACCEPT

## DNS server - VPN to FW
iptables -A INPUT  -p udp --dport 53  -i $IV -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp --sport 53  -o $IV -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTP client
iptables -A INPUT  -p tcp --sport 80  -i $IE -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80  -o $IE -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTPS client
iptables -A INPUT  -p tcp --sport 443 -i $IE -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -o $IE -m state --state NEW,ESTABLISHED -j ACCEPT

# SQUID to DMZLAN only
iptables -A INPUT  -p tcp --dport 3128 -i $ID -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A OUTPUT -p tcp --sport 3128 -o $ID -m state --state ESTABLISHED      -j ACCEPT

# ICMP on every interface
iptables -A INPUT  -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

# DHCP to NETLAN only
iptables -A INPUT  -p udp --dport 67 -i $II -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A OUTPUT -p udp --dport 68 -o $II -m state --state NEW,ESTABLISHED  -j ACCEPT

## VPN server - Internet to FW
iptables -A INPUT  -p udp --dport 1194  -i $IE -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp --sport 1194  -o $IE -m state --state RELATED,ESTABLISHED     -j ACCEPT

#Allow TUN interface connections to OpenVPN server
iptables -A INPUT  -i $IV -j ACCEPT
iptables -A OUTPUT -o $IV -j ACCEPT

# ----------- ---------------------------- ----------- #

# nginx HTTP server from internet
iptables -A INPUT  -p tcp --dport 80  -i $IE -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 80  -o $IE -m state --state ESTABLISHED     -j ACCEPT

# nginx HTTPS server from internet
iptables -A INPUT  -p tcp --dport 443 -i $IE -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 443 -o $IE -m state --state ESTABLISHED     -j ACCEPT

# HTTP client
iptables -A INPUT  -p tcp --sport 80  -i $ID -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80  -o $ID -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTPS client
iptables -A INPUT  -p tcp --sport 443 -i $ID -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -o $ID -m state --state NEW,ESTABLISHED -j ACCEPT


# Enabling source network address translation to access internet without proxy
iptables -t nat -A POSTROUTING -o $IE -s $NETLAN -j SNAT --to-source $FWEXTIP

# NATting VPN Clients
iptables -t nat -A POSTROUTING -s $VPNLAN -o $II -j MASQUERADE


# Block everything else
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

service iptables save
