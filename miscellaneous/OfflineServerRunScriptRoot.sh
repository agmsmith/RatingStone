#!/bin/sh
# AGMS20191214 Run a scripting command with the web site and database in standby
# mode (no database accesses, please wait web page). $1 is the name of a script
# file to run, from the application's miscellaneous directory.  Also rewrites
# the standby index.html file to show the start time and script name.
 
cd /etc/httpd/conf/
rm -v ratingstone.conf
ln -s -v ratingstone_off.conf ratingstone.conf
cd
systemctl restart httpd
sed "--expression=s/MYDATE/`date`/" "--expression=s/MYSCRIPT/$1/" < "/var/www/WWWName/public/offline/index.template.html" > "/var/www/WWWName/public/offline/index.html"

runuser -u SomeUser "/usr/bin/sh /var/www/WWWName/miscellaneous/$1"

cd /etc/httpd/conf/
rm -v ratingstone.conf
ln -s -v ratingstone_on.conf ratingstone.conf
cd
systemctl restart httpd

