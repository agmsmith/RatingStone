#!/bin/sh
# AGMS20190210 Dump the database to a file in SQL format, assumes password
# in ~/.pgpass (host:port:database:user:password, use * for host and port).
 
umask 027
pg_dump --verbose --clean --dbname=SomeDBName --user=SomeUser --no-password > /media/SomeFolderName/RatingStone.sql

rm -rv /var/www/SomeWWWName/storage/va/ri/variants/
rmdir /var/www/SomeWWWName/storage/va/ri
rmdir /var/www/SomeWWWName/storage/va
rsync --progress --verbose --itemize-changes --archive --delete-during --inplace --partial /var/www/SomeWWWName/storage /media/SomeFolderName/

echo "Backup of database and files has been completed."
