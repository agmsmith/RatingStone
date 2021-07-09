#!/bin/sh
# AGMS20191214 Run a scripting command with the web site and database in standby
# mode (no database accesses, please wait web page). $1 is the name of a script
# file to run, from the application's miscellaneous directory.  Also rewrites
# the standby index.html file to show the start time and script name.

if [ -z "$1" ]
then
  echo "Usage: $0 Command"
  echo "Put the web server offline and run one of these commands:"
  ls "/var/www/SomeWWWName/miscellaneous/"
  exit 1
fi

cd /etc/httpd/conf/
rm -v ratingstone.conf
ln -s -v ratingstone_off.conf ratingstone.conf
cd
sed "--expression=s/MYDATE/`date`/" "--expression=s/MYSCRIPT/$1/" < "/var/www/SomeWWWName/public/offline/index.template.html" > "/var/www/SomeWWWName/public/offline/index.html"
systemctl restart httpd
sleep 2s

echo
echo
echo
echo "Now executing: $1"
runuser --login SomeUser "/var/www/SomeWWWName/miscellaneous/$1"
echo "Finished executing $1, return code $?."
echo
echo
echo

cd /etc/httpd/conf/
rm -v ratingstone.conf
ln -s -v ratingstone_on.conf ratingstone.conf
cd
systemctl restart httpd
