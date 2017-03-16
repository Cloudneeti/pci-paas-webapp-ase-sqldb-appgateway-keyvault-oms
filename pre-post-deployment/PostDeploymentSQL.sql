use ContosoClinicDB
Declare @username as varchar(100) = 'ChrisA@avyanconsulting.com'
exec ('CREATE USER [' + @username+'] FROM EXTERNAL PROVIDER')
exec ('GRANT CONNECT TO [' + @username+']' )
exec ('GRANT SELECT TO [' + @username+']' )
exec ('GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO [' + @username+']' )
exec ('GRANT VIEW ANY COLUMN Encryption KEY DEFINITION TO [' + @username+']' )
EXECUTE AS USER = @username 
SELECT * FROM patients;
