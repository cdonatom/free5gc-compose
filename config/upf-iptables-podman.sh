#!/bin/bash
#
# Configure iptables in UPF
#
iptables -t nat -A POSTROUTING -o tap0  -j MASQUERADE
iptables -I FORWARD 1 -j ACCEPT

