function Get-TrueRandomNumber {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [ValidateSet('uint8','uint16','hex16')]
        [string]$DataType = 'uint8',

        [Parameter(Mandatory=$false)]
        [ValidateRange(1,1024)]
        [int]$ArrayLength = 1,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1,1024)]
        [int]$BlockSize = 1
    )

    $uriBase = "https://qrng.anu.edu.au/API/jsonI.php?"

    If ( ($DataType -eq 'uint8') -or ($DataType -eq 'uint16') ) {
        $uriInt = "$($uriBase)length=$ArrayLength&type=$DataType"
        $objTrn = Invoke-RestMethod -Method Get -Uri $uriInt
    }

    If ( ($DataType -eq 'hex16') ) {
        $uriHex = "$($uriBase)length=$ArrayLength&type=$DataType&size=$BlockSize"
        $objTrn = Invoke-RestMethod -Method Get -Uri $uriHex
    }

    return $objTrn
}

Get-TrueRandomNumber -DataType uint16