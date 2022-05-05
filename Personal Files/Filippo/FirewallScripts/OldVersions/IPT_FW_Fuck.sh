#!/bin/bash

echo "Flushing..."
# Flush all rules
/root/scripts/firewall/firewallFlushScript.sh
echo "Flushed rules."

# Enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Variable declaration
II=enp0s8
IE=enp0s9

EXT=0/0
NETLAN=10.10.10.0/24

#FWEXTIP1=10.11.13.101
FWEXTIP1=192.168.1.194

IPCLIENT1=10.10.10.134


# Chain creation
iptables -N ie
iptables -N ei

# -- EXT -> LAN
iptables -A FORWARD -i $IE -o $II -s $EXT -d $NETLAN -j ei
# -- LAN -> EXT
iptables -A FORWARD -i $II -o $IE -s $NETLAN -d $EXT -j ie

#iptables -t nat -A PREROUTING -i $IE -d $FWEXTIP1 -j DNAT --to-destination $IPCLIENT1
#iptables -t nat -A PREROUTING -i $IE -s $EXT -d $FWEXTIP1 -j DNAT --to $IPCLIENT1
iptables -A PREROUTING -t nat -i $IE -s $EXT -d $FWEXTIP1 -j DNAT --to $IPCLIENT1

# Define rules for chains

# Forward SSH from outside
iptables -A ei -p tcp --dport 22 -j ACCEPT
iptables -A ie -p tcp --sport 22 -j ACCEPT

# Comunicazione diretta con FW
# SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

# DNS
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A INPUT -p udp --sport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp --sport 53 -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTP client
#iptables -A INPUT -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# HTTPS client
#iptables -A INPUT -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

# SQUID
iptables -A INPUT -p tcp --dport 3128 -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A OUTPUT -p tcp --sport 3128 -m state --state ESTABLISHED -j ACCEPT

# ICMP
iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

# DHCP
iptables -A INPUT -p udp --dport 67 -m state --state NEW,ESTABLISHED  -j ACCEPT
iptables -A OUTPUT -p udp --dport 68 -m state --state NEW,ESTABLISHED -j ACCEPT

# Block everything by default
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

service iptables save