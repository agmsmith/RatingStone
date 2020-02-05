#!/bin/sh
# AGMS20191209 Restore the database from a .sql text file.  Credentials
# in ~/.pgpass (host:port:database:user:password, use * for host and port).
 
umask 027

dropdb --echo --user=SomeUser --no-password SomeDBName
createdb --echo --user=SomeUser --no-password --template=template0 --owner=SomeUser SomeDBName
psql --dbname=SomeDBName --user=SomeUser --no-password --file /media/SomeFolderName/RatingStone.sql

rsync --progress --verbose --itemize-changes --archive --delete-during --inplace --partial /media/SomeFolderName/storage /var/www/SomeWWWName/

echo "Restore of database and files has been completed."
