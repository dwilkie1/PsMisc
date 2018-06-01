$SqlInstance = 'PDC-SQL-P01\Applications'
$Password = ''

$sqlclrEnable = @"
sp_configure @configname=clr_enabled, @configvalue=1
GO
RECONFIGURE
GO
"@

$sqlBackupMasterKey = @"
USE SSISDB 
GO
OPEN MASTER KEY DECRYPTION BY PASSWORD = `'$Password`'; 
BACKUP MASTER KEY TO FILE = `'c:\temp\exportedmasterkey`'   
    ENCRYPTION BY PASSWORD = `'$Password`';  
"@

#Enable clr, a prerequisite for the SSIS catalog
Invoke-Sqlcmd -Query $sqlclrEnable -ServerInstance $SqlInstance -Database 'Master'

# Load the IntegrationServices Assembly
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices")

# Store the IntegrationServices Assembly namespace to avoid typing it every time
$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"

Write-Host "Connecting to server ..."

# Create a connection to the server
$sqlConnectionString = "Data Source=$SqlInstance;Initial Catalog=master;Integrated Security=SSPI;"
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

# Create the Integration Services object
$integrationServices = New-Object $ISNamespace".IntegrationServices" $sqlConnection

# Provision a new SSIS Catalog
$catalog = New-Object $ISNamespace".Catalog" ($integrationServices, "SSISDB", $Password)
$catalog.Create()

#BackupMasterKey
if ((Test-Path 'C:\temp') -eq $true)
  {
      Write-Host "Backing up key"
      Invoke-Sqlcmd -Query $sqlBackupMasterKey -ServerInstance $SqlInstance -Database 'SSISDB'
  }
  else
  {
      Write-Host "creating temp folder"
      New-Item 'C:\temp' -ItemType Directory
      Write-Host "Backing up key"
      Invoke-Sqlcmd -Query $sqlBackupMasterKey -ServerInstance $SqlInstance -Database 'SSISDB'

  }
