#!/bin/bash
#Let's Install Let's Encrypt
#version=0.4

#Check to see if Let's Encrypt is already installed. If not, install certbot :D.
if [[ -a /root/letsencrypt/ ]]; then
  echo "Letsencrypt is installed already! Do you want us to convert you to the new certbot? y for yes."; read convert;
  if [[ $convert=="y" ]]; then
    sed -i 's~/root/.local/share/letsencrypt/bin/python2.7 /root/.local/share/letsencrypt/bin/letsencrypt~/bin/sh /root/certbot/certbot-auto~g' letsencryptscript.sh;
    rm -rf /root/letsencrypt/
  else;
    echo "Okay, exiting. Please clean this up on your end, then rerun the script."
    exit 1
  fi
else
  cd /root/;
  git clone https://github.com/certbot/certbot;
  cd certbot;
fi

#Check for and install the cPanel SSL install script.
if [[ ! -a /root/installssl.sh ]]; then
        wget https://raw.githubusercontent.com/echoe/letsencryptcpanel/master/installssl.sh --no-check-certificate -O /root/installssl.sh
        else echo "We already have the installssl script."
fi

#Set the domain and email.
DOMAIN=$1;
EMAIL=$2;
if [[ $DOMAIN == "" ]]; then
  echo "It looks like you aren't auto-installing ( ./installle.sh domain email ).";
  echo "Please specify the domain you would like to have an SSL installed on."; read DOMAIN;
  echo "Please specify the email you want this domain to be installed under."; read EMAIL;
fi
if [[ $EMAIL == "" ]]; then EMAIL="notarealemailaddress@notanemail.com"; fi
echo "We are installing an SSL on $DOMAIN with the email $EMAIL ."

#Install the SSL.
if [[ $DOMAIN == `hostname` ]]; then
  echo "We have a hostname.";
  if [[ -a /root/letsencryptscript.sh ]]; then
    sed -i "/$DOMAIN/d" /root/letsencryptscript.sh;
    sed -i "/service cpanel restart/d" /root/letsencryptscript.sh;
  fi
  echo "/bin/sh /root/certbot/certbot-auto --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $DOMAIN" >> /root/letsencryptscript.sh;
  echo "/bin/sh /root/installssl.sh $DOMAIN" >> /root/letsencryptscript.sh;
  echo "service cpanel restart" >> /root/letsencryptscript.sh;
  echo "Processing ..."
  /bin/sh /root/certbot/certbot-auto --text --agree-tos --email $EMAIL certonly --webroot --webroot-path /usr/local/apache/htdocs --renew-by-default -d $DOMAIN
  /bin/sh /root/installssl.sh $DOMAIN
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
  echo "/bin/sh /root/certbot/certbot-auto --text --agree-tos --email $EMAIL certonly --webroot --webroot-path $DOCROOT --renew-by-default -d $DOMAIN -d www.$DOMAIN" >> /root/letsencryptscript.sh;
  echo "/bin/sh /root/installssl.sh $DOMAIN" >> /root/letsencryptscript.sh;
  echo "Processing ..."
  /bin/sh /root/certbot/certbot-auto --text --agree-tos --email $EMAIL certonly --webroot --webroot-path $DOCROOT --renew-by-default -d $DOMAIN -d www.$DOMAIN
  /bin/sh /root/installssl.sh $DOMAIN
  echo "This cert should now be installed!";
fi;

#Add the crontab if necessary, and then let us see the letsencryptscript and finish.
echo "Adding the crontab."
if [[ -z `grep "0 0 01 */2 * /bin/sh /root/letsencryptscript.sh" /var/spool/cron/root` ]]; then crontab -l | { cat; echo "0 0 */60 * * /bin/sh /root/letsencryptscript.sh"; } | crontab - ; fi
echo -e "\n You're finished! Here's the contents of the letsencrypt script right now just in case. If you see any problems, you'll need to edit them manually. \n ----- \n"
cat /root/letsencryptscript.sh
