#Let's Install Let's Encrypt superauto version! Pipe me a domain!
#version=0.01
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
else echo "We already have Let's Encrypt installed :)"
fi

if [[ ! -a /root/installssl.sh ]]; then
#Download and install the cPanel installer
        wget files.wiredtree.com/misc/installssl.sh -O /root/installssl.sh
        else echo "We already have the installssl script :)"
fi

#Get the domain and email from this thing.
DOMAIN=$1
EMAIL=$2
if [[ $EMAIL == "" ]]; then EMAIL="notarealemailaddress@notanemail.com"; fi
#Tell us what we're doing.
echo "This is the domain we're doing: $DOMAIN and email: $EMAIL"

if [[ $DOMAIN == `hostname` ]]; then
        echo "We have a hostname"
        HOSTNAME=$DOMAIN;
        if [[ -a /root/letsencryptscript.sh ]]; then
            sed --in-place "/$HOSTNAME/d" /root/letsencryptscript.sh;
            sed --in-place "/service cpanel restart/d" /root/letsencryptscript.sh;
        fi
        echo "/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $HOSTNAME" >> /root/letsencryptscript.sh;
        echo "/bin/sh /root/installssl.sh $HOSTNAME" >> /root/letsencryptscript.sh;
        echo "service cpanel restart" >> /root/letsencryptscript.sh;
        echo "Processing ..."
        /root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $HOSTNAME
        /bin/sh /root/installssl.sh $HOSTNAME
        service cpanel restart
        echo "Please test this now, the changes should have been made to the letsencryptscript :D"
fi
if [[ $DOMAIN != `hostname` ]]; then
        echo "we have a domain";
        CPUSER=`/scripts/whoowns $DOMAIN`;
        DOCROOT=`grep "documentroot:" /var/cpanel/userdata/$CPUSER/$DOMAIN | cut -d" " -f2`;
        if [[ -a /root/letsencryptscript.sh ]]; then
            sed --in-place "/d $DOMAIN/d" /root/letsencryptscript.sh;
            sed --in-place "/installssl.sh $DOMAIN/d" /root/letsencryptscript.sh;
        fi
        echo "/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path $DOCROOT --renew-by-default -d $DOMAIN -d www.$DOMAIN" >> /root/letsencryptscript.sh;
        echo "/bin/sh /root/installssl.sh $DOMAIN" >> /root/letsencryptscript.sh;
        echo "Processing ..."
        /root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path $DOCROOT --renew-by-default -d $DOMAIN -d www.$DOMAIN
        /bin/sh /root/installssl.sh $DOMAIN
        echo "This cert should now be installed!";
fi;
#Add the crontab if necessary.
echo "Adding the crontab."
if [[ -z `grep "0 0 01 */2 * /bin/sh /root/letsencryptscript.sh" /var/spool/cron/root` ]]; then crontab -l | { cat; echo "0 0 */60 * * /bin/sh /root/letsencryptscript.sh"; } | crontab - ; fi
#Done!
echo -e "\n You're finished! Here's the contents of the letsencrypt script right now just in case. If you see any problems, you'll need to edit them manually. \n ----- \n"
cat /root/letsencryptscript.sh