#!/bin/bash
echo "Firewall IO rules..."

Ibytewise=ens192
Iexternal=ens160

# DNS client and server to LAN and DMZ
## DNS client - firewall to ext
iptables -A OUTPUT -p udp --dport 53  -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p udp --sport 53  -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTP client
iptables -A INPUT  -p tcp --sport 80  -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80  -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTPS client
iptables -A INPUT  -p tcp --sport 443 -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# NTP client
iptables -A INPUT  -p udp --sport 123 -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p udp --dport 123 -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT


# ICMP on every interface
iptables -A INPUT  -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

echo "Done."