
$files = Get-ChildItem D:\fDrive\SSIS\Edens_Avant\EA_ETL -Recurse -Include *.dtsx

Select-String -Path $files -Pattern "name=`"FastLoadMaxInsertCommitSize`">0</property>"

foreach ($file in $files)
    {
        (Get-Content $file.PSPath) | 
        ForEach-Object { $_ -replace "name=`"FastLoadMaxInsertCommitSize`">2147483647</property>", "name=`"FastLoadMaxInsertCommitSize`">0</property>" } |
        Set-Content $file.PSPath
    }

Select-String -Path $files -Pattern "name=`"FastLoadMaxInsertCommitSize`">0</property>"