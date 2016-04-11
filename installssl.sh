#whmapi1 Let's Encrypt SSL script
#we need to URI encode the certificates because the cPanel API requires it. I used a one liner from here to do this:
#http://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
dom=$1
user=`/scripts/whoowns $dom`
crt=`cat /etc/letsencrypt/live/$dom/cert.pem | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g'`;
key=`cat /etc/letsencrypt/live/$dom/privkey.pem | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g'`;
ca=`cat /etc/letsencrypt/live/$dom/chain.pem | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g'`;
#If we're installing the hostname certificate we install it on the services - else install on the domain.
if [[ $dom == `hostname` ]]; then
  whmapi1 install_service_ssl_certificate service=exim crt=$crt cabundle=$ca key=$key
  whmapi1 install_service_ssl_certificate service=ftp crt=$crt cabundle=$ca key=$key
  whmapi1 install_service_ssl_certificate service=cpanel crt=$crt cabundle=$ca key=$key
  whmapi1 install_service_ssl_certificate service=dovecot crt=$crt cabundle=$ca key=$key
else
  ip=`cat /var/cpanel/users/$user | grep IP | cut -d"=" -f2`
  whmapi1 installssl domain=$dom crt=$crt key=$key cab=$ca ip=$ip
fi
