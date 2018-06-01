Invoke-Command -ComputerName pdc-wb-app-d01 -ScriptBlock {
    $explorerprocesses = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='explorer.exe'" -ErrorAction SilentlyContinue)
    If ($explorerprocesses.Count -eq 0)
    {
        "No explorer process found / Nobody interactively logged on"
    }
    Else
    {
        ForEach ($i in $explorerprocesses)
        {
            $Username = $i.GetOwner().User
            $Domain = $i.GetOwner().Domain
            Write-Host "$Domain\$Username logged on since: $($i.ConvertToDateTime($i.CreationDate))"
        }
    }
}