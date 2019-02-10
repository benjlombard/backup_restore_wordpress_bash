#!/bin/bash
# simple script to backup wordpress website into one cloud (Mega.nz) : database + website folder
# (C) Lombard Benjamin <mlsuyt@protonmail.com>
# https://github.com/benjlombard/bash.git
#Update Date:2019:02:10


#usage function
usage()
{
  echo "Usage: $0 [-u USER] [-l LOGINMEGA] [-p PASSWORDMEGA] [-d DATABASE]"
  exit 2
}

unset USER LOGIN_MEGA PASSWORD_MEGA DATABASE

DATABASE="wordpress"

#A loop for parsing arguments with traditional getopts
while getopts 'u:l:p:d:?h' c
do
  case $c in
    u) USER=$OPTARG ;;
    l) LOGINMEGA=$OPTARG ;;
    p) PASSWORDMEGA=$OPTARG ;;
    d) DATABASE=$OPTARG ;;
    h|?) usage ;; 
  esac
done

#check if variables are unset and if the case call usage function
[ -z "$USER" ] && [ -z "$LOGINMEGA" ] && [ -z "$PASSWORDMEGA" ] && usage
[ -z "$USER" ] && usage
[ -z "$LOGINMEGA" ] && usage
[ -z "$PASSWORDMEGA" ] && usage
[ -z "$USER" ] && [ -z "$PASSWORDMEGA" ] && usage
[ -z "$USER" ] && [ -z "$LOGINMEGA" ] && usage
[ -z "$PASSWORDMEGA" ] && [ -z "$LOGINMEGA" ] && usage

cd /home/$USER

#backup database given in argument
sudo mysqldump --add-drop-table -u root -p ${DATABASE} > ./backup_wordpress_$(date +%F).sql
sudo tar -vczf ./backup_wordpress_$(date +%F).tar.gz /var/www/html/. ./backup_wordpress_$(date +%F).sql
rm ./backup_wordpress_$(date +%F).sql

#cypher tar archive with TWOFISH alogrithm (symmetric algorithm)
gpg --symmetric --cipher-algo TWOFISH -o ./backup_wordpress_$(date +%F).tar.gz.gpg ./backup_wordpress_$(date +%F).tar.gz

rm -rf ./backup_wordpress_$(date +%F).tar.gz

megaput -u $LOGINMEGA -p $PASSWORDMEGA --path /Root/backup/wordpress ./backup_wordpress_$(date +%F).tar.gz.gpg 
 
