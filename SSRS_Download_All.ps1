#------------------------------------------------------
#Prerequisites
#Install-Module -Name ReportingServicesTools
#------------------------------------------------------

#Lets get security on all folders in a single instance
#------------------------------------------------------
#Declare SSRS URI
#$sourceRsUri = 'http://ReportServerURL/ReportServer/ReportService2010.asmx?wsdl'
$sourceRsUri = 'http://pdc-sql-d01/ReportServer/ReportService2010.asmx?wsdl'

#Declare Proxy so we dont need to connect with every command
$proxy = New-RsWebServiceProxy -ReportServerUri $sourceRsUri

#Output ALL Catalog items to file system
Out-RsFolderContent -Proxy $proxy -RsFolder / -Destination 'D:\Temp\SSRS_Out\' -Recurse