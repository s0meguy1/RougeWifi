#!/bin/bash
#variable 1 = wifi device
#variable 2 = internet device
[ $# -eq 0 ] && { echo "usage: wifi.sh [wireless-device] [internet-device] [AP network name]"; exit 1; }
wifi="$1"
eth="$2"
cat <<EOF
__________                            __      __.__  _____.__ 
\______   \ ____   ____  __ __   ____/  \    /  \__|/ ____\__|
 |       _//  _ \ / ___\|  |  \_/ __ \   \/\/   /  \   __\|  |
 |    |   (  <_> ) /_/  >  |  /\  ___/\        /|  ||  |  |  |
 |____|_  /\____/\___  /|____/  \___  >\__/\  / |__||__|  |__|
        \/      /_____/             \/      \/                
EOF
control_c()
{
  echo -e "\e[91mCTRL C Detected!\n"
  cleanup $wifi $eth
  echo -e "\e[91mExiting!"
  exit $?
}
function cleanup() {
	echo -en "\n###Caught SIGINT; Cleaning up and exiting\n"
	local x="$1" #x = wlan0
	local z="$2" #z = eth0
	echo -e "\e[32m###Restoring hostapd.conf"
	if [ -f /etc/hostapd/hostapd.BAK ]; then mv /etc/hostapd/hostapd.BAK /etc/hostapd/hostapd.conf; fi
	sleep 1
	echo -e "\e[32m###Restoring dnsmasq.conf"
	if [ -f /etc/dnsmasq.BAK ]; then mv /etc/dnsmasq.BAK /etc/dnsmasq.conf; fi
	sleep 1
	echo -e "\e[32m###Restoring iptables"
	iptables -t mangle -D PREROUTING -i $x -p udp --dport 53 -j RETURN
	iptables -t mangle -D PREROUTING -i $x -j captiveportal
	iptables -t mangle -D captiveportal -j MARK --set-mark 1
	iptables -t nat -D PREROUTING -i $x  -p tcp -m mark --mark 1 -j DNAT --to-destination 10.0.0.1
	iptables -D FORWARD -i $x -j ACCEPT
	iptables -t nat -D POSTROUTING -o $z -j MASQUERADE
	iptables -t nat -F
	iptables -t nat -X
	iptables -t mangle -F
	iptables -t mangle -X
	sleep 1
	echo -e "\e[32m###Killing dnsmasq"
	pkill dnsmasq
	sleep 1
	echo -e "\e[32m###Killing hostapd"
	pkill hostapd
    exit $?
}
trap control_c SIGINT
echo -e "\e[32m###Backing up/Creating hostapd.conf"
if [ -f /etc/hostapd/hostapd.conf ]; then mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.BAK; fi
echo -e "interface=$1\ndriver=nl80211\nssid=$3\nhw_mode=g\nchannel=6\nignore_broadcast_ssid=0" > /etc/hostapd/hostapd.conf
sleep 1
echo -e "\e[32m###Backing up/Creating dnsmasq.conf"
if [ -f /etc/dnsmasq.conf ]; then mv /etc/dnsmasq.conf /etc/dnsmasq.BAK; fi
echo -e "no-resolv\ninterface=$1\ndhcp-range=10.0.0.2,10.0.0.101,12h\nserver=8.8.8.8\nserver=8.8.4.4" > /etc/dnsmasq.conf
sleep 1
echo -e "\e[32m###Adding routes to iptables"
iptables -t mangle -N captiveportal
iptables -t mangle -A PREROUTING -i $1 -p udp --dport 53 -j RETURN
iptables -t mangle -A PREROUTING -i $1 -j captiveportal
iptables -t mangle -A captiveportal -j MARK --set-mark 1
iptables -t nat -A PREROUTING -i $1  -p tcp -m mark --mark 1 -j DNAT --to-destination 10.0.0.1
sysctl -w net.ipv4.ip_forward=1
iptables -A FORWARD -i $1 -j ACCEPT
iptables -t nat -A POSTROUTING -o $2 -j MASQUERADE
echo -e "\e[32m###Starting apache"
service apache2 start
echo -e "\e[32m###Configuring $1 "
ifconfig $1 up 10.0.0.1 netmask 255.255.255.0
echo -e "\e[32m###Turning on dnsmasq"
if [ -z "$(ps -e | grep dnsmasq)" ]
  then 
    dnsmasq &
  fi
sleep 1
echo -e "\e[32m###Starting hostapd"
hostapd -B /etc/hostapd/hostapd.conf 1> /dev/null
while true; do read x; done

