#weekdays at 6am
Register-ScheduledJob -Name GetSystemEvents -ScriptBlock {
    Get-EventLog -LogName System -Newest 25 | 
    Export-Clixml D:\Test\sjtest.xml 
    } -Trigger (New-JobTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 6am) -ScheduledJobOption (New-ScheduledJobOption -WakeToRun -RunElevated)

#every 15 minutes indefinitely
Register-ScheduledJob -Name Jde_Dev_PerfmonData -ScriptBlock {
    &  D:\SqlSourceControl\Code\Powershell\Maintain_SQL_Server_Performance_Baseline_with_PowerShell\SQLPerfmon_JDE_Dev.ps1  
    } -Trigger (New-JobTrigger -Once -At "8/23/2017 1:00" -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)) -ScheduledJobOption (New-ScheduledJobOption -WakeToRun -RunElevated)
