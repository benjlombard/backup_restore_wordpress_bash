#!/bin/bash
# simple script to restore wordpress website from one cloud (Mega.nz) : database + website folder
# (C) Lombard Benjamin <mlsuyt@protonmail.com>
# https://github.com/benjlombard/bash.git
#Update Date:2019:02:10



#usage function
usage()
{
  echo "Usage: $0 [-u USER] [-l LOGINMEGA] [-p PASSWORDMEGA] [-w WEBSERVER] [-d MAINDB] [-e USERDATABASE] [-z PASSWORDDATABASE] [-w SOURCEOPTION] [-y DESTOPTION] "
  exit 2
}


unset USER LOGIN_MEGA PASSWORD_MEGA WEBSERVER

WEBSERVER="nginx"
MAINDB="wordpress"
USERDATABASE="user_database"
PASSWORDDATABASE="password_database"
SOURCEOPTION="tekprog.fr"
DESTOPTION="10.123.234.121"


#A loop for parsing arguments with traditional getopts
while getopts 'u:l:p:w:d:e:z:w:y:?h' c
do
  case $c in
    u) USER=$OPTARG ;;
    l) LOGINMEGA=$OPTARG ;;
    p) PASSWORDMEGA=$OPTARG ;;
    w) WEBSERVER=$OPTARG ;;
    d) MAINDB=$OPTARG ;;
    e) USERDATABASE=$OPTARG ;;
    z) PASSWORDDATABASE=$OPTARG ;;
    w) SOURCEOPTION=$OPTARG ;;
    y) DESTOPTION=$OPTARG ;;
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
rm -rf backup_wordpress_*
#retrieve last backup from mega.nz cloud
bckFile=$(megals /Root/backup/wordpress -u $LOGINMEGA -p $PASSWORDMEGA | sort -k4 -rn | head -n1)
megaget ${bckFile} -u $LOGINMEGA -p $PASSWORDMEGA

#decypher the backup taken from mega.nz cloud
gpg --output /home/$USER/backup_wordpress_$(date +%F).tar.gz --decrypt /home/$USER/backup_wordpress_*.tar.gz.gpg 
rm -rf /home/$USER/backup_wordpress_*.tar.gz.gpg
mkdir backup
cd ./backup
tar -zxvf /home/$USER/backup_wordpress_*.tar.gz -C /home/$USER/backup
PASSWDDB="$(openssl rand -base64 12)"

#create database and create user and grant all privileges for this user to the created database which hosts wordpress
sudo mysql -uroot -e "DROP DATABASE ${MAINDB};"
sudo mysql -uroot -e "CREATE DATABASE ${MAINDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
sudo mysql -uroot ${MAINDB} < /home/${USER}/backup/backup_wordpress_*.sql
sudo mysql -uroot -e "CREATE USER $USERDATABASE@localhost IDENTIFIED BY '$PASSWORDDATABASE';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO $USERDATABASE'localhost' IDENTIFIED BY '$PASSWORDDATABASE';"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"

#update siteurl option and home option in table wp_options
sudo mysql -uroot -e "UPDATE ${MAINDB}.wp_options SET option_value = 'http://$DESTOPTION/html' WHERE option_name = 'home' OR option_name = 'siteurl'; UPDATE ${MAINDB}.wp_posts SET guid = REPLACE (guid, '$SOURCEOPTION/html', '$DESTOPTION/html'); UPDATE ${MAINDB}.wp_posts SET post_content = REPLACE (post_content, '$SOURCEOPTION/html', '$DESTOPTION/html'); UPDATE ${MAINDB}.wp_postmeta SET meta_value = REPLACE (meta_value, '$SOURCEOPTION/html','$DESTOPTION/html');"


#untar wordpress tar archive into /var/www/html
sudo cp -r /home/${USER}/backup/var/www/html/* /var/www/html/
if [ "$WEBSERVER" = "nginx" ]; then
  sudo chown -R www-data:www-data /var/www/html
else
  sudo chown -R apache:apache /var/www/html
fi

rm -rf /home/$USER/backup

#restart nginx.service & php7.0-fpm.service
sudo systemctl restart nginx.service
sudo systemctl restart php7.0-fpm.service



