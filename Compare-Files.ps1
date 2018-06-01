function CompareFiles {
    param(
    [string]$Filepath1,
    [string]$Filepath2
    )
    if ((Get-FileHash $Filepath1).Hash -eq (Get-FileHash $Filepath2).Hash) {
        Write-Host 'Files Match' -ForegroundColor Green
    } else {
        Write-Host 'Files do not match' -ForegroundColor Red
    }
}

CompareFiles -Filepath1 F:\Angus\AngusDev\Angus\web.config -FilePath2 F:\Angus\AngusProd\Angus\web.config