#!/bin/bash
# Interactive PoPToP install script for an OpenVZ VPS
# Tested on Debian 5, 6, and Ubuntu 11.04
# July 18, 2014 v1.11
# Cara Mudah Install PPTP by evil bastard

echo "######################################################"
echo "Interactive PoPToP Install Script for an OpenVZ VPS"
echo
echo "Make sure to contact your provider and have them enable"
echo "IPtables and ppp modules prior to setting up PoPToP."
echo "PPP can also be enabled from SolusVM."
echo
echo "You need to set up the server before creating more users."
echo "A separate user is required per connection or machine."
echo "######################################################"
echo
echo
echo "============================================"
echo "SSH Super Gila, PPTP Script Installer stolen from evil bastard"
echo "Pilh Salah Satu:"
echo "1) Install PoPToP server dan buat satu user"
echo "2) Membuat User"
echo "============================================"
read x
if test $x -eq 1; then
	echo "Masukkan Username yang akan dibuat (eg. client1 or evilbastard):"
	read u
	echo "Buat Password untuk $u:"
	read p
	echo "Masukkan Public DNS 1 dari http://public-dns.tk/ :"
	read dns1
	echo "Masukkan Public DNS 2 dari http://public-dns.tk/ :"
	read dns2
	
# get the VPS IP
ip=`ifconfig venet0:0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://`

echo
echo "===================================="
echo "Lagi download sama install PoPToP"
echo "===================================="
apt-get update
apt-get -y install pptpd

echo
echo "===================================="
echo "Membuat Konfigurasi Server"
echo "===================================="
cat > /etc/ppp/pptpd-options <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
proxyarp
nodefaultroute
lock
nobsdcomp
END

# setting up pptpd.conf
echo "option /etc/ppp/pptpd-options" > /etc/pptpd.conf
echo "logwtmp" >> /etc/pptpd.conf
echo "localip $ip" >> /etc/pptpd.conf
echo "remoteip 10.1.0.1-100" >> /etc/pptpd.conf

# adding new user
echo "$u	*	$p	*" >> /etc/ppp/chap-secrets
echo "ms-dns $dns1" >> /etc/ppp/pptpd-options
echo "ms-dns $dns2" >> /etc/ppp/pptpd-options

echo
echo echo "===================================="
echo "Mengalihkan IPv4 dan menerapkan saat boot"
echo echo "===================================="
cat >> /etc/sysctl.conf <<END
net.ipv4.ip_forward=1
END
sysctl -p

echo
echo "===================================="
echo "Update iptables routing dan menerapkan saat boot"
echo "===================================="
iptables -t nat -A POSTROUTING -j SNAT --to $ip
# saves iptables routing rules and enables them on-boot
iptables-save > /etc/iptables.conf

cat > /etc/network/if-pre-up.d/iptables <<END
#!/bin/sh
iptables-restore < /etc/iptables.conf
END

chmod +x /etc/network/if-pre-up.d/iptables
cat >> /etc/ppp/ip-up <<END
ifconfig ppp0 mtu 1400
END

echo
echo "===================================="
echo "Restart PoPToP"
echo "===================================="
sleep 5
/etc/init.d/pptpd restart

echo
echo "===================================="
echo "Sudah Selesai"
echo "Silahkan konek VPN PPTP $ip dengan user & pass berikut:"
echo "Username:$u ##### Password: $p"
echo "===================================="

echo "Script stolen from evil bastard"

# runs this if option 2 is selected
elif test $x -eq 2; then
	echo "Masukan username yang akan di buat (Contoh : Evil, Bastard):"
	read u
	echo "Buat Password untuk $u:"
	read p

# get the VPS IP
ip=`ifconfig venet0:0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://`

# adding new user
echo "$u	*	$p	*" >> /etc/ppp/chap-secrets

echo
echo "===================================="
echo "User PPTP Sukses dibuat!"
echo "Silahkan konek VPN PPTP $ip dengan user & pass berikut:"
echo "Username:$u ##### Password: $p"
echo "===================================="

echo "Script stolen from evil bastard"

else
echo "Invalid selection, quitting."
exit
fi
