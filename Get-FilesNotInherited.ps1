Get-childitem D:\SqlSourceControl -recurse |
Get-Acl | % {
    $path = $_.Path
    $_.Access | % {
        New-Object PSObject -Property @{
            Folder = $path.Replace("Microsoft.PowerShell.Core\FileSystem::","")
            Access = $_.FileSystemRights
            Control = $_.AccessControlType
            User = $_.IdentityReference
            Inheritance = $_.IsInherited
            }
    }
} | ? {-not $_.Inheritance} | export-csv D:\test\test_dump.csv -force