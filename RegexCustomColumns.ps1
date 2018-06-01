Get-SqlAgentJobHistory -JobName ClearSingleUsePlans -ServerInstance PDCJDEENTD01 | 
#Where-Object { ($_.StepID -eq 1 -and $_.Message -match "no need to clear cache now") -or ($_.StepID -eq 1) } |
Where-Object { $_.StepID -eq 1 } |
Select-Object -Property RunDate, `
                        @{Name="MBsCached";Expression={ [regex]::Match($_.Message,'(?<=Only ).\d{1,5}\.\d{3}').Value }}, `
                        @{Name="StatusMsg";Expression={ if ([regex]::Match($_.Message,'no need to clear cache').Success -eq $true) {'Cache not cleared'} else {'Cache Cleared'}}} |

Sort-Object -Property RunDate |
Format-Table -AutoSize 
