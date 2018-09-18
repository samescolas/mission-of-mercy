DO
$
BEGIN
   IF NOT EXISTS (
      SELECT                       -- SELECT list can stay empty for this
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'my_user') THEN

      CREATE ROLE my_user LOGIN PASSWORD 'my_password';
   END IF;
END
$;
