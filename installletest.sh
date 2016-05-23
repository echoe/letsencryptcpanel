#Let's Install Let's Encrypt
#version=0.31

#Flags.
if [[ $* == *--help* ]]; then
  echo "OPTIONS:"
  echo "[domain] [email] --auto: Automatically installs an SSL without prompts for a specific domain."
  echo "For example: sh /root/installle.sh domain.com me@domain.com --auto will install an SSL for domain.com with the specified email address."
fi
if [[ $* == *--auto* ]]; then
  DOMAIN=$1;
  EMAIL=$2;
  if [[ $EMAIL == "" ]]; then EMAIL="notarealemailaddress@notanemail.com"; fi
  echo "This is the domain we're installing an SSL on: $DOMAIN using this email: $EMAIL"
fi

#Check to see if Let's Encrypt is already installed. If not, install it.
if [[ ! -a /root/letsencrypt/ ]]; then
  centos=`cat /etc/centos-release | cut -d. -f1 | cut -d" " -f4`;
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
  else echo "Your CentOS version is not supported, exiting"; exit 1
  fi
  else echo "We already have Let's Encrypt installed."
fi

#Check for and install the cPanel SSL install script.
if [[ ! -a /root/installssl.sh ]]; then
        wget files.wiredtree.com/misc/installssl.sh -O /root/installssl.sh
        else echo "We already have the installssl script."
fi

#Set the domain and email.
if [[ -z $DOMAIN ]];
  echo "Please specify the domain you would like to have an SSL installed on."; read DOMAIN;
  echo "Please specify the email you want this domain to be installed under."; read EMAIL;
  if [[ $EMAIL == "" ]]; then EMAIL="notarealemailaddress@notanemail.com"; fi
fi

#Install the SSL.
if [[ $DOMAIN == `hostname` ]]; then
  echo "We have a hostname.";
  if [[ -a /root/letsencryptscript.sh ]]; then
    sed -i "/$HOSTNAME/d" /root/letsencryptscript.sh;
    sed -i "/service cpanel restart/d" /root/letsencryptscript.sh;
  fi
  echo "/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $HOSTNAME" >> /root/letsencryptscript.sh;
  echo "/bin/sh /root/installssl.sh $HOSTNAME" >> /root/letsencryptscript.sh;
  echo "service cpanel restart" >> /root/letsencryptscript.sh;
  echo "Processing ..."
  /root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $HOSTNAME
  /bin/sh /root/installssl.sh $HOSTNAME
  service cpanel restart
  echo "Please test this now, the changes should have been made to the letsencryptscript."
elif [[ $DOMAIN != `hostname` ]]; then
  echo "We have a non-hostname domain.";
  CPUSER=`/scripts/whoowns $DOMAIN`;
  DOCROOT=`grep "documentroot:" /var/cpanel/userdata/$CPUSER/$DOMAIN | cut -d" " -f2`;
  if [[ -a /root/letsencryptscript.sh ]]; then
    sed -i "/d $DOMAIN/d" /root/letsencryptscript.sh;
    sed -i "/installssl.sh $DOMAIN/d" /root/letsencryptscript.sh;
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