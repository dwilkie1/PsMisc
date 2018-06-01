<#
.SYNOPSIS
    Get-DiskInventory retrieves logical disk information from one or more computers using WMI Win32LogicalDisk.
.PARAMETER computername
    The computer(s) name(s) to query. Default: LocalHost.
.PARAMETER drivetype
    The type of drive to query. Default: 3. See Win32_LogicalDisk documentation. 
.EXAMPLE
    Get-Diskinventory -computername SERVER01 -drivetype 3
#>
Param (
    $computerName = 'localhost',
    $driveType = 3
)
Get-WmiObject -Class Win32_LogicalDisk `
-ComputerName $computerName `
-Filter "driveType=$driveType" |
Sort-Object -Property DeviceID | 
Format-Table -Property DeviceID, 
@{label = 'FreeSpace (MB)'; expression={$_.FreeSpace / 1MB -as [int]}},
@{label = 'Size (GB)'; expression={$_.Size / 1GB -as [int]}},
@{label = 'Free (%)'; expression={$_.FreeSpace / $_.Size * 100 -as [int]}}
