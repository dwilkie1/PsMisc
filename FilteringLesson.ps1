# get-process | Where-Object { $_.Name -notlike "*powershell*" } |
# Sort-Object VM -Descending |
# Select-Object -last 10 -Property VM |
# Measure-Object -Property VM -Sum

#Get-netadapter -Physical | Select-Object -Property name,Virtual
# Get-ChildItem C:\Windows\System32 -Filter *.exe | Where-Object { $_.Length -gt (5MB) } |
# Select-Object -Property Name, @{Name="Length(MB)";Expression={$_.Length / 1MB}},Attributes | Format-Table -AutoSize

#Get-HotFix -description 'Update' | Where-Object {$_.InstalledBy -like "*adgetmin*" }
Get-Process -Name conhost,svchost | get-object -Property Name,status
#| Where-Object {$_.status -eq "Stopped"}