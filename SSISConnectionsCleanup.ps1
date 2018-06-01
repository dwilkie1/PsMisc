$FolderLocation = 'D:\SqlSourceControl\Development\Las2.0\SSIS\LAS2Dev Upload'
$ToBeReplacedString = '\[PRODDTA\]'
$ReplacementString = '[CRPDTA]'

$files = Get-ChildItem -Path $FolderLocation -Filter '*.dtsx' -File

ForEach ($file in $files)
    {(Get-Content $file.FullName) `
        | ForEach-Object {$_ -replace ($ToBeReplacedString), ($ReplacementString)} `
        | Set-Content $file.FullName
    }