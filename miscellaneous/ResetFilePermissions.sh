#!/bin/sh
# AGMS20191216 Change the server file permissions for all files with
# confidential information to make them more private.  The trouble is that git
# only saves the executable bit of the file permissions.
 
cd /var/www/SomeWWWName/
pwd
chmod -R -v og-rwx config | grep -i changed
chmod -R -v og-rwx miscellaneous | grep -i changed

for filename in ./log/*.log
do
  echo "Resetting log file $filename."
  date > "$filename"
done

