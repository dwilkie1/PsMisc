$Computers = (Get-Content -Path "$psscriptroot\SQLSERVERs.txt")
$Computers

$sessions = New-PSSession -ComputerName $Computers

$Data = Invoke-Command -Command {
    Get-EventLog System -After (get-date).AddDays(-90) | Where-Object {$_.EventID -eq "6005"} 
} -Session $sessions

$Data | Select-Object -Property PScomputername, TimeGenerated, @{Name="DayofWeek";Expression={($_."TimeGenerated").DayofWeek}}, Message | 
    Sort-Object -Descending PScomputername, TimeGenerated | Export-Csv -Path D:\Temp\output.csv 

Get-PSSession | Remove-PSSession
