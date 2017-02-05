#RougeWifi
This is my first contribution as I finally decided to start sharing my scripts. I am not a programmer and as you can see, not an advanced script writer, but
I put this out here to expand and improve this into something that I could never have done by myself!
 
I got tired of simple Wifi AP's that don’t act as one you'd find in a public free wifi. This AP grants the user access after they have authenticated using 
one of the 4 social media options. The first time they authenticate, I added a message saying "Authentication failed. incorrect username/password" as I noticed some 
people would enter gibberish. The failed first auth increases likelihood that they will enter the correct credentials. 

Once authenticated, both passwords ([first-attempt] and [second-attempt]) are dumped into "passwords.txt" along with the email/username and type of 
authentication (Google, Facebook, Twitter and Linkedin) and the user is granted access to the internet. 

You need to add the line:
**www-data ALL=(ALL:ALL) NOPASSWD: /sbin/iptables, /usr/sbin/arp**
to /etc/sudoers. NOTE: /sbin/ and /usr/sbin/ may not be the locations of arp/iptables for you, so do a "whereis arp && whereis iptables" to find the correct path.

This was built on Kali Linux on a VM, so most of the dependencies to run this "out of box" are already installed, except hostapd. On other versions of linux you 
may need to install php5, dnsmasq and some other php dependencies, along with apache2. Also the below assumes you have your internet connection through eth0. If you
are using two wifi cards, just switch out eth0 (in my below example) for {internet interface}. The internet facing interface can be wired or wireless, but obviously
the AP interface needs to be a wireless interface.

To run:
Just place all files in /var/www/html/, run the command chown `www-data:www-data ./*` (may want to limit it to the html, js and images if running on a large
network) and run:
`wifi.sh wlan0 eth0 {network name}` without brackets and enjoy!

One final note -
If the script runs but you dont see the network, you may have some driver issues with hostapd and alpha - just make sure you have the correct driver set running
and it should work. You can troubleshoot by running: `hostapd -dd /etc/hostapd/hostapd.conf` and looking at the error messages

Special thanks to jeretc for his HTML templates! https://github.com/jeretc/cfp
