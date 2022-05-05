#!/bin/bash

# Empty all rules
iptables -F
iptables -F -t nat
iptables -X

# change default policy to accept
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT