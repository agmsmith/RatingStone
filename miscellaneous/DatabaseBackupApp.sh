#!/bin/sh
# AGMS20190210 Dump the database to a file in SQL format, assumes password
# in ~/.pgpass (host:port:database:user:password, use * for host and port
# and database).  Presumes that the database will be empty before restoration.
 
umask 027

# Save the database as SQL statements.  Not using --clean due to some
# foreign key constraints that cause trouble later during restoration.
# Instead the restore script will delete everything first.
pg_dump --verbose --dbname=SomeDBName --username=SomeUser --no-password > /media/SomeFolderName/SomeDBName.sql

# Save the ActiveStorage files uploaded by the users, except variants (which
# get recreated whenever somebody accesses one).
rm -rv /var/www/SomeWWWName/storage/va/ri/variants/
rmdir /var/www/SomeWWWName/storage/va/ri
rmdir /var/www/SomeWWWName/storage/va
rsync --progress --verbose --itemize-changes --archive --delete-during --inplace --partial /var/www/SomeWWWName/storage /media/SomeFolderName/

echo "Backup of database and files has been completed."
