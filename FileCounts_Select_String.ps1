cd "C:\Temp\2018-Feb-15-0843AM"
$files = dir -Filter *.rdl -Recurse  

Select-String -Path $files -SimpleMatch "2005" |
        Select-Object -Property Filename, Line |
        Sort-Object -Property filename |
        Measure-Object |
        %{$_.count}


Select-String -Path $files -SimpleMatch "2005" |
    Select-Object -Property Filename, Line |
    Sort-Object -Property filename | out-file results.txt