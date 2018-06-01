#Ends any current transcripts and starts the Auto-DB-Restore script silencing any errors
#$ErrorActionPreference="SilentlyContinue"
#Stop-Transcript | out-null
#$ErrorActionPreference = "Continue"


#Edit restore details below: (names should be in " ")
$sourceDB = "(database name)"
$sourceVM = "(VM name you are restoring database from)"
$backupJob = "(name of backup job in Veeam)"
$targetVM = "(VM name you wish to restore database to)"
$targetInstance = "(instance of SQL to restore to - if default, leave a space between the quotes -like this " ")"

#Target DB name (in order to keep the same name of original database)
$targetDB = "$sourceDB"

#For testing - Target DB name used when adding a date to the end of target DB name (this is currently not in use - removed the # symbol and then place a # symbol in the Target DB name option above)
#$targetDB = "{0}-{1}" -f $sourceDB, (Get-Date -Format yyyMMdd)


#*****CREATES LOG FILE WITH CURRENT DATE*****
$logName = "log-{0}-{1}.txt" -f $sourceDB,(Get-Date -Format yyyMMdd)
Start-Transcript -path C:\DBRestoreScript\Logs\$logName -append


#THIS IS WHERE THE SCRIPT ACTUALLY STARTS WORKING


#Adds VeeamPSSnapIn
Add-PSSnapin VeeamPSSnapIn -ErrorAction SilentlyContinue

#*****TARGET CREDENTIALS - LEAVE INTACT*****
$targetCreds = Get-VBRCredentials -Name "(LEAVE THE QUOTES AND PUT YOUR DOMAIN\USERNAME HERE)"


#*****CHECK $RESTOREPOINT BEFORE RUNNING CODE BELOW THIS POINT FOR THE FIRST TIME TO MAKE SURE EVERYTHING IS CORRECT TO THIS POINT*****
$restorePoint = Get-VBRRestorePoint -Backup $backupJob -Name "$sourceVM" | Sort-Object creationtime -Descending | Select-Object -First 1


#Checks the availability of restoring the DB
try {
    $database = Get-VBRSQLDatabase -ApplicationRestorePoint $restorePoint -Name $sourceDB #NOT SURE WHY I GET THE CREATION TIME OF 9/18/2016
} catch {
    "Couldnt find database" 
    break
}

#Performs restore to another server/instance of SQL
$restoreSession = Start-VBRSQLDatabaseRestore -force -Database $database -ServerName $targetVM -InstanceName $targetInstance -DatabaseName $targetDB -GuestCredentials $targetCreds -SqlCredentials $targetCreds

#End logs
Stop-Transcript

#Remove logs older than 7 days
$limit = (Get-Date).AddDays(-7)
$path = "C:\DBRestoreScript\Logs"
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force

#Create 'Readme for logs folder
New-Item C:\DBRestoreScript\Logs\`ReadMe.txt -Force -Value "If the logs are "blank" or don't show any errors before transcript ends - job completed without error."

#Ends script
Exit