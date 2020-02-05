#!/bin/sh
# AGMS20191209 Restore the database from a .sql text file.  Credentials
# in ~/.pgpass (host:port:database:user:password, use * for host and port
# and database too since we do things while our main database doesn't exist).
 
umask 027

# Make a totally empty database, else restore won't work well.
dropdb --echo --username=SomeUser --no-password SomeDBName
createdb --echo --username=SomeUser --no-password --template=template0 SomeDBName
psql --dbname=SomeDBName --username=SomeUser --no-password --command="COMMENT ON DATABASE \"SomeDBName\" IS 'The SomeDBName reputation system database.  Used for running the SomeWWWName web site.';"

# Restore the database from the saved SQL statements file.
psql --dbname=SomeDBName --username=SomeUser --no-password --file /media/SomeFolderName/RatingStone.sql

# Restore the ActiveStorage monitored files used for pictures and other media.
rsync --progress --verbose --itemize-changes --archive --delete-during --inplace --partial /media/SomeFolderName/storage /var/www/SomeWWWName/

echo "Restore of database and files has been completed."
