
-- Please Connect with Active directory password authentication and SQL AD Admin credentials
use ContosoClinicDB
Declare @domainName as varchar(50) = 'XXXX' -- Provide your domain name. This is the only change here

Declare @doctorUserName as varchar(100) = 'doctor_ChrisA@'+@domainName
exec ('CREATE USER [' + @doctorUserName+'] FROM EXTERNAL PROVIDER')
exec ('GRANT CONNECT TO [' + @doctorUserName+']' )
exec ('GRANT SELECT TO [' + @doctorUserName+']' )
exec ('GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO [' + @doctorUserName+']' )
exec ('GRANT VIEW ANY COLUMN Encryption KEY DEFINITION TO [' + @doctorUserName+']' )

GO

Declare @receptionistUserName as varchar(100) = 'receptionist_EdnaB@'+@domainName
exec ('CREATE USER [' + @receptionistUserName+'] FROM EXTERNAL PROVIDER')
exec ('GRANT CONNECT TO [' + @receptionistUserName+']' )
exec ('GRANT SELECT TO [' + @receptionistUserName+']' )
-- Receptionist would have privileges to update patient details
exec ('GRANT UPDATE TO [' + @receptionistUserName+']' )
exec ('GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO [' + @receptionistUserName+']' )
exec ('GRANT VIEW ANY COLUMN Encryption KEY DEFINITION TO [' + @receptionistUserName+']' )

EXECUTE AS USER = @receptionistUserName 
SELECT * FROM patients;
