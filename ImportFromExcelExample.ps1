Install-Module ImportExcel

Import-Module ImportExcel

$datatable = Import-Excel -Path "C:\DonDocuments\JDE\NAICS clean up.xlsx" -WorkSheetname "NAICS clean up" | Out-DbaDataTable 

Write-DbaDataTable -SqlServer PDCJDEENTD01 -InputObject $datatable -Table DWTestDB.dbo.JdeNaicsCleanUp -AutoCreateTable -Truncate -Verbose