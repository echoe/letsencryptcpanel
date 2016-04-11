#Let's Install Let's Encrypt
#version=0.1
#Check to see if Let's Encrypt is already installed. If not, install it.
if [[ ! -a /root/letsencrypt/ ]]; then
#Install the Cert Generator
centos=`cat /etc/centos-release | cut -d. -f1 | cut -d" " -f4`
if [[ $centos=="6" ]]; then
	rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
	rpm -ivh https://rhel6.iuscommunity.org/ius-release.rpm
	yum -y install python27 python27-devel python27-pip python27-setuptools python27-virtualenv --enablerepo=ius
	cd /root
	git clone https://github.com/letsencrypt/letsencrypt
	cd /root/letsencrypt
	sed -i "s|--python python2|--python python2.7|" letsencrypt-auto
	./letsencrypt-auto --verbose
elif [[ $centos=="7" ]]; then
	cd /root
	git clone https://github.com/letsencrypt/letsencrypt
	cd /root/letsencrypt
	./letsencrypt-auto --verbose
else echo "Your CentOS version is not supported, exiting";
	exit 1
fi
fi

if [[ ! -a /root/installssl.sh ]]; then
#Download and install the cPanel installer
	wget files.wiredtree.com/misc/installssl.sh -O /root/installssl.sh
fi
#Ask what you're installing this on
echo -e "Please type an h for hostname, or a d for domain."; read why
if [[ $why == h ]]; then
	echo -e "If the hostname isn't `hostname`, please type it now."; read HOSTNAME
	if [[ $HOSTNAME == "" ]]; then HOSTNAME=`hostname`; fi
	echo -e "Please let us know what email address you want the information for. If you don't specify one it will go to an obviously fake email."; read email
	if [[ $EMAIL == "" ]]; then EMAIL="notarealemailaddress@notanemail.com"; fi
	if [[ -a /root/letsencryptscript.sh ]]; then
		cat > /root/letsencryptscript.sh <<EOF
		/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $HOSTNAME
		/bin/sh /root/installssl.sh $HOSTNAME
		service cpanel restart
EOF
	else
		grep -v "$HOSTNAME" /root/letsencryptscript.sh > /root/letsencryptscript.sh;
		grep -v "service cpanel restart" /root/letsencryptscript.sh > /root/letsencryptscript.sh;
		echo "/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $HOSTNAME" >> /root/letsencryptscript.sh;
		echo "/bin/sh /root/installssl.sh $HOSTNAME" >> /root/letsencryptscript.sh;
		echo "service cpanel restart" >> /root/letsencryptscript.sh;
	fi
	/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $HOSTNAME
	/bin/sh /root/installssl.sh $HOSTNAME
	service cpanel restart
	echo "Please test this now, the changes should have been made to the letsencryptscript :D"
		
elif [[ $why == d ]]; then
	echo -e "Domain?"; read DOMAIN; CPUSER=`/scripts/whoowns $DOMAIN`;
	echo -e "Please let us know what email address you want the information for. If you don't specify one it will go to an obviously fake email."; read EMAIL
        if [[ $EMAIL == "" ]]; then EMAIL="notarealemailaddress@notanemail.com"; fi
	echo -e "EMAIL=$EMAIL DOMAIN=$DOMAIN CPUSER=$CPUSER Does this look good? Type y for yes"; read good;
	if [[ $good=y ]]; then
		DOCROOT=`grep "documentroot:" /var/cpanel/userdata/$CPUSER/$DOMAIN | cut -d" " -f2`;
		grep -v "d $DOMAIN" /root/letsencryptscript.sh > /root/letsencryptscript.sh;
		grep -v "/bin/sh /root/installssl.sh $DOMAIN" /root/letsencryptscript.sh > /root/letsencryptscript.sh;
		echo "/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path $DOCROOT --renew-by-default -d $DOMAIN www.$DOMAIN" >> /root/letsencryptscript.sh;
		echo "/bin/sh /root/installssl.sh $DOMAIN" >> /root/letsencryptscript.sh;
		/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path $DOCROOT --renew-by-default -d $DOMAIN www.$DOMAIN
		/bin/sh /root/installssl.sh $DOMAIN
		echo "This cert should now be installed!";
fi;
fi;
#Add the crontab
echo "Adding the crontab."
if [[ -z `grep "0 0 */60 * * /bin/sh /root/letsencryptscript.sh" /var/spool/cron/root` ]]; then crontab -l | { cat; echo "0 0 */60 * * /bin/sh /root/letsencryptscript.sh"; } | crontab - ; fi
#Done!
echo "You're finished! Here's the contents of the letsencrypt script right now just in case. If you see any problems, you'll need to edit them manually."
cat /root/letsencryptscript.sh
