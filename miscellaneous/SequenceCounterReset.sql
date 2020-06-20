-- From https://wiki.postgresql.org/wiki/Fixing_Sequences
-- Resets the sequence counters to the highest ID value from each table, useful after importing some data manually.
-- Note that squences need to be owned by table, see that wiki for how to fix that.
-- Run it with these three command lines:
--   psql --dbname=SomeDBName --username=SomeUser --no-password --file SequenceCounterReset.sql > temp.sql
--   psql --dbname=SomeDBName --username=SomeUser --no-password --file temp.sql
--   rm -v temp.sql

SELECT 'SELECT SETVAL(' ||
       quote_literal(quote_ident(PGT.schemaname) || '.' || quote_ident(S.relname)) ||
       ', COALESCE(MAX(' ||quote_ident(C.attname)|| '), 1) ) FROM ' ||
       quote_ident(PGT.schemaname)|| '.'||quote_ident(T.relname)|| ';'
FROM pg_class AS S,
     pg_depend AS D,
     pg_class AS T,
     pg_attribute AS C,
     pg_tables AS PGT
WHERE S.relkind = 'S'
    AND S.oid = D.objid
    AND D.refobjid = T.oid
    AND D.refobjid = C.attrelid
    AND D.refobjsubid = C.attnum
    AND T.relname = PGT.tablename
ORDER BY S.relname;
